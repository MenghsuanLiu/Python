# %%
import random
import requests as req
import json
import sqlalchemy
import pymysql
import pandas as pd
import os
import time
import shioaji as sj
from bs4 import BeautifulSoup as bs
from datetime import datetime, date, timedelta


class cfg:
    def __init__(self, cfg = None)->None:
        self.cfg_file = "./config/config.json"
        if cfg:
            self.cfg_file = cfg

    def getValueByConfigFile(self, key = None):        
        if not key:
            return print("請指定取得Config的Key值")
        
        try:
            with open(self.cfg_file, encoding="UTF-8") as f:
                jfile = json.load(f)
            val = jfile[key]
        except:
            val = None
        return val



    def getConfigValue(cfgfile, key):
        try:
            with open(cfgfile, encoding="UTF-8") as f:
                jfile = json.load(f)
            val = jfile[key]    
            # val =  ({True: "", False: jfile[datatype]}[jfile[datatype] == "" | jfile[datatype] == "None"])
        except:
            val = ""
        return val

class con: 
    def __init__(self, insrt_api = None) -> None:
        self.acct_mapping = "./config/account.json"
        self.loginfile = cfg().getValueByConfigFile(key = "login")
        self.api = None
        if insrt_api:
            self.api = insrt_api

        self.simulation = True  # 是否為測試環境
        self.id = "PAPIUSER0" + str(random.randint(1,8))
        self.pwd = "2222"
        self.ca_active = False
        self.ca_acct = "chris"
        self.ca_userid = None
        self.start_time = "09:00:00"
        self.end_time = "13:30:00"
        self.markets = ["TSE", "OTC"]
        self.mkt_mapping = {"TSE": "上市", "OTC": "上櫃", "OES": "興櫃"}
        self.ex_cate = ["00", "", "17"] # 排除類別00:權證, 17:金融
        self.ex_price = 20 # 排除股價
        self.tb_basic = "basicdata"
        self.tb_dohlc = "dailyholc"
        self.tb_minohlc = "dailyminsholc"
        
        
    def LoginToServerForStock(self, simulate:bool = True, id = None, pwd = None, ca_acct = None):
        # 模擬!=True self.simulation就要置換,同時ca_acct有值表示要做憑證的active
        # **如果是模擬=>ca_acct不管是否有值都不會active憑證
        if not simulate:
            self.simulation = simulate
            # 當use_acct != None時就取代self.ca_acct
            if ca_acct:            
               self.ca_active = True
               self.ca_acct = ca_acct
        else:
            if ca_acct:
                print("模擬環境不需要啟用憑證!!")
        # 如果id及pwd有給,就用給的取代預設
        if id and pwd:
            self.id = id
            self.pwd = pwd           

        try:
            # 登入 shioaji
            self.api = sj.Shioaji(simulation = self.simulation)
            # 實體機: 讀file登入
            if self.simulation == False:
                with open(self.loginfile, "r") as f:
                    login_cfg = json.loads(f.read())
                self.api.login(**login_cfg, contracts_timeout = 0)
                print("Login Actural Environment Success!!")
            # 測試機: 直接給帳密    
            else:
                self.api.login(person_id = self.id, passwd = self.pwd)
                print(f"Login Simulation Environment({self.id}) Success")
            
        except Exception as exc:
            return print(f"id = {self.id}, pwd = {self.pwd}...{exc}") 

        # 若是前面判斷要active ca就要做這段
        if self.ca_active == True:
            self.SetTreadAccount()            
            
        return self.api

    # tread_type (S:股票 F:期貨)
    def SetTreadAccount(self, tread_type = "S"):
        acctid = cfg(self.acct_mapping).getValueByConfigFile(key = self.ca_acct.lower())        
        # 取出這個帳號裡面有多少帳戶可以做交易,生一個DataFrame
        acct = []
        i = 0        
        while True:    
            try:
                acct.append([self.api.list_accounts()[i].account_type.value, self.api.list_accounts()[i].person_id, self.api.list_accounts()[i].account_id, self.api.list_accounts()[i].username])
                i += 1
            except:
                break
        acctDF = pd.DataFrame(acct, columns = ["Type", "ID", "AccountID", "Name"])     
        # 取得帳戶的Index,後面可以設交易帳戶
        acct_idx = acctDF.index[(acctDF.Type == tread_type) & (acctDF.AccountID == acctid)].values[0]
        # 設定預設交易帳戶
        self.api.set_default_account(self.api.list_accounts()[int(acct_idx)])
        # 取得身份證字號,然後把憑證餵進去
        self.ca_userid = acctDF.ID[(acctDF.Type == tread_type) & (acctDF.AccountID == acctid)].values[0]
        uname = acctDF.Name[(acctDF.Type == tread_type) & (acctDF.AccountID == acctid)].values[0].strip()

        i_ca = self.InsertCAFile()

        if i_ca:
            return print(f"啟用及匯入憑證成功![目前使用 {uname}({self.ca_userid})憑證]")
        else:
            return print(f"匯入憑證失敗,請檢查File Status!")
    
    def InsertCAFile(self):
        remsg = self.api.activate_ca(
                                    ca_path = fr"C:\ekey\551\{self.ca_userid}\S\Sinopac.pfx",
                                    ca_passwd = self.ca_userid,
                                    person_id = self.ca_userid
                                )
        return remsg

    def ChangeTreadAccount(self, ca_acct = None):
        if self.api == None:
            return print("請指定API")
        
        if ca_acct:
            self.ca_acct = ca_acct
        else:
            return print("請指定要更換的使用者")
        
        print("更換交易帳號中...請稍等.....")
        self.SetTreadAccount()

    def getContractForAPI(self, focus_DF):
        if self.api == None:
            return print("請指定API")

        try:
            Lst = tool.DFcolumnToList(focus_DF, "StockID")
            ct_lst = []
            for stkid in Lst:
                ct_lst.append(self.api.Contracts.Stocks[stkid])
            return ct_lst
        except Exception as exc:
            return print(exc)

    def getAfterOpenTimesSnapshotData(self, contract, nmin_run:int = 0):
        self.start_time = (datetime.strptime(self.start_time, "%H:%M:%S") + timedelta(minutes = nmin_run)).strftime("%H:%M:%S")

        # 這段是防止開盤後run時跑去等開盤時間
        if datetime.now().strftime("%H:%M:%S") > self.start_time:
            outDF = self.getMinSnapshotData(contract)
            return outDF

        while True:    
            if datetime.now().strftime("%H:%M:%S") == self.start_time:
                outDF = self.getMinSnapshotData(contract)
                break
        return outDF 

    def getMinsSnapshotData(self, contract = None, start: int = 10):
        self.start_time = (datetime.strptime(self.start_time, "%H:%M:%S") + timedelta(minutes = start)).strftime("%H:%M:%S")
        outDF = pd.DataFrame()
        # 收盤後只要取一次就好
        if datetime.now().time() > datetime.strptime(self.end_time, "%H:%M:%S").time() or datetime.today().weekday() in (5, 6):
            outDF = self.getMinSnapshotData(contract)
            return outDF
        
        while True:
            outDF = outDF.append(self.getMinSnapshotData(contract))            
            if datetime.now().strftime("%H:%M:%S") == self.start_time:
                break
            tool.WaitingTimeDecide(60)

    def getMinSnapshotData(self, ctract:list):
        minDF = pd.DataFrame(self.api.snapshots(ctract)).filter(items = ["code", "ts", "open", "high", "low", "close", "volume" ]).rename(columns = {"code": "StockID", "ts": "DateTime", "open": "Open", "high": "High", "low": "Low", "close": "Close", "volume": "Volume"})
        minDF.DateTime = pd.to_datetime(minDF.DateTime)
        minDF["TradeDate"] = pd.to_datetime(minDF.DateTime).dt.strftime("%Y%m%d")
        minDF["TradeTime"] = pd.to_datetime(minDF.DateTime).dt.time
        minDF["SnapShotTime"] = datetime.now().strftime("%H:%M:%S")
        minDF.StockID = minDF.StockID.astype(str)
        return minDF

    def getKarData(self, stkid:str = None, sdate:str = None, edate:str = None):
        try:
            outDF = pd.DataFrame({**self.api.kbars(self.api.Contracts.Stocks[stkid], start = sdate, end = edate)})
            outDF["TradeDate"] = pd.to_datetime(outDF.ts).dt.strftime("%Y%m%d")
            outDF["TradeTime"] = pd.to_datetime(outDF.ts).dt.time
            outDF["DateTime"] = pd.to_datetime(outDF.ts)
            outDF.insert(0, "StockID", str(stkid))
            outDF = outDF.sort_values(by = "ts")
        except Exception as exc:
            return print(exc)
        return outDF

    def StockNormalBuy(self, stkid, buyprice = "now", buyqty:int = 1):
        # Order參數說明  action{Buy, Sell}, price_type{LMT(限價), MKT(市價), MKP(範圍市價)} p.s MKT/MKP只能搭IOC, price = 0
        #               order_type{ROD, IOC, FOK}, order_cond{Cash(現股), MarginTrading(融資), ShortSelling(融券)}
        #               order_lot{Common(整股), Fixing(定盤), Odd(盤後零股), IntradayOdd(盤中零股)}
        Ctract = self.api.Contracts.Stocks[stkid]
        # 漲停
        myotype = "ROD"
        myptype = "LMT"
        myprice = buyprice
        if buyprice == "up":
            myprice = Ctract.limit_up
        # 跌停
        if buyprice == "down":
            myprice = Ctract.limit_down    
        # 現價
        if buyprice == "now":
            myprice = 0
            myotype = "IOC"
            myptype = "MKT"   
        # 下單    
        order = self.api.Order(
                                price = myprice, 
                                quantity = buyqty, 
                                action = "Buy", 
                                price_type = myptype, 
                                order_type = myotype,
                                order_cond = "Cash",
                                order_lot = "Common",                     
                                account = self.api.stock_account
                             )
        self.api.place_order(Ctract, order)
        return

    def SubscribeTick(self, contract):
        self.api.quote.subscribe(contract, quote_type = sj.constant.QuoteType.Tick)

    def UnsubscribeTick(self, contract):
        self.api.quote.unsubscribe(contract, quote_type=sj.constant.QuoteType.Tick)

    def getStockDataByCondition(self, udb:bool = True, market = None):
        if market:
            self.markets = market
        
        stkDF = pd.DataFrame()
        for mkt in self.markets:
            # 上市(筆數太多要等一下)
            if mkt == "TSE":
                collect = self.api.Contracts.Stocks.TSE
                time.sleep(10)
            # 上櫃    
            if mkt == "OTC":
                collect = self.api.Contracts.Stocks.OTC
            # 興櫃
            if mkt == "OES":  
                collect = self.api.Contracts.Stocks.OES

            tmpDF = []
            for each in collect:
                tmpDF.append({**each})
            stkDF = stkDF.append(pd.DataFrame(tmpDF))
        
        stkDF = stkDF[~stkDF.category.isin(self.ex_cate) & ~stkDF.name.str.contains(pat = "KY") & ~stkDF.name.str.contains(pat = "特")]
        stkDF = stkDF[stkDF.update_date == stkDF.update_date.max()]
        stkDF = stkDF[stkDF.reference >= self.ex_price]

        stkDF = stkDF.filter(items = ["code", "name", "exchange", "category", "update_date"]).rename(columns = {"code": "StockID", "name": "StockName", "exchange": "上市/上櫃"}).replace(self.mkt_mapping)

        if udb == True:
            DFtoDB = stkDF.filter(items = ["StockID", "StockName", "上市/上櫃", "category"]).rename(columns = {"StockName": "Name", "上市/上櫃": "Exchange", "category": "categoryID"})
            exist_lst = tool.DFcolumnToList(db().selectDatatoDF(tb_name = self.tb_basic), "StockID")
            DFtoDB = DFtoDB[~DFtoDB.StockID.isin(exist_lst)]
            DFtoDB = DFtoDB.drop_duplicates(subset = ["StockID"], keep = "first")
            if not DFtoDB.empty:
                db().updateDFtoDB(DFtoDB, self.tb_basic)

        return stkDF.reset_index(drop = True)
    # & stkDF.update_date == stkDF.update_date.max()

    # def connectToServer(loginfile):
    #     # 登入帳號
    #     api = sj.Shioaji(backend = "http", simulation = False) 
    #     with open(loginfile, "r") as f:
    #         login_cfg = json.loads(f.read())
    #     api.login(**login_cfg, contracts_timeout = 0)
    #     return api
    
    # def connectToSimServer():
    #     # 登入帳號
    #     api = sj.Shioaji(simulation = True) 
    #     api.login(
    #         # PAPIUSER01~PAPIUSER08
    #         person_id = "PAPIUSER06", 
    #         passwd = "2222", 
    #         contracts_cb = lambda security_type: print(f"{repr(security_type)} fetch done.")
    #     )
    #     return api

    # def InsertCAbyConfig(api, cafile):
    #     with open(cafile, "r") as f:
    #         ca_cfg = json.loads(f.read())
    #     remsg = api.activate_ca(**ca_cfg)
    #     return print(remsg)

    # def InsertCAbyID(api, id):
    #     remsg = api.activate_ca(
    #                         ca_path = fr"C:\ekey\551\{id}\S\Sinopac.pfx",
    #                         ca_passwd = id,
    #                         person_id = id,
    #                     )
    #     return remsg

    # def SetDefaultAccount(api, acctype, name):
    #     account_cfg = "./config/account.json"
    #     # acctype => S:股票 F:期貨 H:
    #     acctid = cfg.getConfigValue(account_cfg, name.lower())
    #     acct = []
    #     i = 0
    #     # 取出這個帳號裡面有多少帳戶可以做交易
    #     while True:    
    #         try:
    #             acct.append([api.list_accounts()[i].account_type.value, api.list_accounts()[i].person_id, api.list_accounts()[i].account_id, api.list_accounts()[i].username])
    #             i += 1
    #         except:
    #             break
    #     acctDF = pd.DataFrame(acct, columns = ["Type", "ID", "AccountID", "Name"])
    #     # 取得帳戶的Index,後面可以設交易帳戶
    #     idx = acctDF.index[(acctDF.Type == acctype) & (acctDF.AccountID == acctid)].values[0]
    #     # 設定預設交易帳戶
    #     api.set_default_account(api.list_accounts()[int(idx)])
    #     # 取得身份證字號,然後把慼證餵進去
    #     PID = acctDF.ID[(acctDF.Type == acctype) & (acctDF.AccountID == acctid)].values[0]
    #     msg = con.InsertCAbyID(api, PID)
    #     # 憑證若失敗會跳error message
    #     if msg == True:
    #         return print(f"目前使用憑證:{PID}!!")
    #     else:
    #         return

class db:
    def __init__(self):
        self.tb_name = None
        self.dbusr = "root"
        self.dbpwd = "670325"
        self.dbname = "stock"
        self.dbmode = None
        self.statment = None

    def getStockBasicData(self):
        basicDF = self.selectDatatoDF(cfg().getValueByConfigFile(key = "tb_basic")).filter(items = ["StockID", "categoryID"]).rename(columns = {"categoryID": "cateID"})
        cateDF = self.selectDatatoDF(cfg().getValueByConfigFile(key = "tb_ind")).filter(items = ["cateID", "cateDesc"])
        return basicDF.merge(cateDF, on = "cateID", how = "left")


    def connLoclmySQL(self, db_name = None, con_mode = None):
        # 有指定db就用指定的,其他用預設
        if db_name:
            self.dbname = db_name

        # mode中有給值就是要做update
        if con_mode:
            self.dbmode = con_mode
            return sqlalchemy.create_engine(f"mysql+pymysql://{self.dbusr}:{self.dbpwd}@localhost/{self.dbname}?charset=utf8")
        
        return pymysql.connect(host = "localhost", user = self.dbusr, passwd = self.dbpwd, database = self.dbname)

    def selectDatatoDF(self, tb_name = None, sql_statment:str = None):
        if tb_name:
            self.tb_name = tb_name  
            self.statment = f"SELECT * FROM {self.tb_name}"

        if sql_statment:
            self.statment = sql_statment

        try:
            dbcon = self.connLoclmySQL()
            return pd.read_sql(self.statment, con = dbcon)
        except Exception as exc:
            return print(exc) 
       

    def updateDFtoDB(self, insertDF, tb_name = None):
        if not tb_name:
            return print("請輸入需要upDate的Table Name")
        else:
            self.tb_name = tb_name

        dbcon = self.connLoclmySQL(con_mode = "update")
        try:
            insertDF.to_sql(con = dbcon, name = self.tb_name, if_exists = "append", index = False)
            return print(f"Update Table {self.tb_name} Success!")
        except:
            return print(f"Fail to Update Table {self.tb_name}, Check It Please!!!!!")
        


    def mySQLconn(dbname, fn):
        db_usr = "root"
        db_pwd = "670325"
        if fn == "pd_update":
            return sqlalchemy.create_engine(f"mysql+pymysql://{db_usr}:{db_pwd}@localhost/{dbname}?charset=utf8")
        else:
            return pymysql.connect(host = "localhost", user = db_usr, passwd = db_pwd, database = dbname)


    def delDataFromDB(tbfullname, cond_dict):
        cols, vals = list(cond_dict.items())[0]
        
        db_con = db.mySQLconn(tbfullname.split(".")[0], "delete")
        cur = db_con.cursor()
        if isinstance(vals, str):
            cur.execute(f"DELETE FROM {tbfullname} WHERE {cols} = {vals}")
        else:
            cur.execute(f"DELETE FROM {tbfullname} WHERE {cols} IN {vals}")
        db_con.commit()
        return print(f"Delete Table {tbfullname} Value Success!")        

    def updateDataToDB(tbfullname, updf):
        updb_con = db.mySQLconn(tbfullname.split(".")[0], "pd_update")
        new_df = updf
        # 不同Table處理方式不太一樣,就只要一直加(不需刪舊的)        
        if tbfullname.split(".")[1] == "basicdata":
            df_org = db.readDataFromDBtoDF(tbfullname, "")         
            if not df_org.empty:
                new_df = new_df.append(df_org)
                # 差集(這次DF沒有, DB有要再處理)
                new_df = new_df.drop_duplicates(subset = ["StockID"], keep = False)
                # 留下DB有但這次沒有
                new_df = pd.merge(new_df, updf.filter(items = ["StockID"]), on = ["StockID"]).dropna(axis = "columns")
        # else:
            # # 取得要做Delete的ColumnName
            # colname = ""
            # if tbfullname.split(".")[1] in ["dailyvolume", "dailyminsholc"]:
            #     colname = "TradeDate"
            # if tbfullname.split(".")[1] in ["dailyholc", "testable"]:
            #     colname = ("StockID", "TradeDate")
            #     del_df = updf.filter(items = ["StockID", "TradeDate"])
            #     del_df["TradeDate"] = del_df["TradeDate"].apply(lambda x: x.strftime("%Y%m%d"))
            #     subsetlst = tuple(zip(del_df.StockID, del_df.TradeDate))
            # new_df = updf
        if not new_df.empty:
            try:
                new_df.to_sql(con = updb_con, name = tbfullname.split(".")[1], if_exists = "append", index = False)
                return print(f"Update Table {tbfullname} Success!")
            except:
                return print(f"Fail to Update Table {tbfullname} !!!!!")
        else:
            return print(f"No New Data need to Update ({tbfullname})!")

    def readDataFromDBtoDF(tbfullname, dict_filter):
        db_con = db.mySQLconn(tbfullname.split(".")[0], "read")
        if dict_filter == "":
            return pd.read_sql(f"SELECT * FROM {tbfullname}", con = db_con)
        else:
            col, value = list(dict_filter.items())[0]
            if isinstance(value, str):
                return pd.read_sql(f"SELECT * FROM {tbfullname} WHERE {col} = {value}", con = db_con)
            else:
                return pd.read_sql(f"SELECT * FROM {tbfullname} WHERE {col} IN {value}", con = db_con)

class file:
    def __init__(self) -> None:
        self.api = None

    def getLastFocusStockDF(self):
        filelst = os.listdir(cfg().getValueByConfigFile(key = "dailypath"))
        matching = []
        i = 0
        while True:
            # 算出最近有資料的那一天
            yyyymmdd = (date.today() - timedelta(days = i)).strftime("%Y%m%d")
            fname = cfg().getValueByConfigFile(key = "resultname") + f"_{yyyymmdd}.xlsx"
            matching = [s for s in filelst if fname in s]
            i += 1
            if matching !=[]:
                ffpath = cfg().getValueByConfigFile(key = "dailypath") + "/" + cfg().getValueByConfigFile(key = "resultname") + f"_{yyyymmdd}.xlsx"
                break
    
        stkDF = pd.read_excel(ffpath)
        stkDF.StockID = stkDF.StockID.astype(str)
        return stkDF

    def GeneratorFromDF(genDF, fname, ftype:str = "xlsx"):
        if ftype.lower() == "csv":
            genDF.to_csv(fname, index = False, encoding = "utf_8_sig")
        if ftype.lower() == "xlsx":
            genDF.to_excel(fname, index = False)

    def genFiles(cfgname, df, filename, ftype):
        gen = cfg.getConfigValue(cfgname, "genData")
        if gen.lower() == "x":
            if ftype.lower() == "csv":
                df.to_csv(filename, index = False, encoding = "utf_8_sig")
            if ftype.lower() == "xlsx":
                df.to_excel(filename, index = False)
        return

class stg:
    def __init__(self, DF):
        self.basicDF = db().getStockBasicData()
        self.in_DF = DF

    def SMA_Volume(self):
        out_DF =  self.in_DF.loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.Volume >= 5000)]
        return out_DF.merge(self.basicDF, on = ["StockID"], how = "left").drop(columns = ["cateID"])

    # 邏輯: 前一交易日成交價 > 60MA & 10MA,且成交量 >= 5000張 
    def SMA_SAR002_Volume(self):
        out_DF = pd.DataFrame()
        try:
            out_DF =  self.in_DF.loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.Volume >= 5000) & (self.in_DF.sgl_SAR_002 > 0)]
            out_DF = out_DF.merge(self.basicDF, on = ["StockID"], how = "left").drop(columns = ["cateID"])
        except:
            pass
        return out_DF

    def SMA_SAR002_Volume_MAXMIN120(self):
        out_DF = pd.DataFrame()
        try:
            out_DF =  self.in_DF.loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.Volume >= 5000) & (self.in_DF.sgl_SAR_002 > 0) & (self.in_DF.sgl_maxmin_120 > 0)]
            out_DF = out_DF.merge(self.basicDF, on = ["StockID"], how = "left").drop(columns = ["cateID"])
        except:
            pass    
        return out_DF
        
    # 買進策略:5min的Close < 前一天的Close * 1.05
    def BuyStrategyFromOpenSnapDF_01(self, snap_DF):
        MergeDF = self.in_DF.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).merge(snap_DF.filter(items = ["StockID", "Open", "High", "Close"]).rename(columns = {"Close": "snapClose"}), on = ["StockID"], how = "left")
        MergeDF["BuyFlag"] = ""
        
        MergeDF.loc[(MergeDF["snapClose"] < MergeDF["Close"] * 1.05), "BuyFlag"] = "X"
        BuyDF = MergeDF.loc[MergeDF.BuyFlag == "X"]
        return BuyDF.drop(columns = ["BuyFlag", "High", "snapClose", "Close"])
    # 買進策略:a.5min價 < 前一交易收盤價+5% b.5min價 >= 開盤價(紅K) c.5min價>= 最高價*(1 - 0.01)
    def BuyStrategyFromOpenSnapDF_02(self, snap_DF):
        MergeDF = self.in_DF.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).merge(snap_DF.filter(items = ["StockID", "Open", "High", "Close"]).rename(columns = {"Close": "snapClose"}), on = ["StockID"], how = "left")
        MergeDF["BuyFlag"] = ""

        MergeDF.loc[(MergeDF["snapClose"] < MergeDF["Close"] * 1.05) & (MergeDF["snapClose"] >= MergeDF["Open"]) & (MergeDF["snapClose"] >= MergeDF["High"] * (1 - 0.01)), "BuyFlag"] = "X"
        BuyDF = MergeDF.loc[MergeDF.BuyFlag == "X"]        
        return BuyDF.drop(columns = ["BuyFlag", "High", "snapClose", "Close"])

    def BuyStrategyFromOpenSnapDF_03(self, snap_DF):
        snap_DF = snap_DF.set_index("DateTime").groupby("StockID").resample("5T", label = "right", closed = "right").agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
        ymd = datetime.now().strftime("%Y%m%d")
        if snap_DF != []:
            file.GeneratorFromDF(snap_DF, f"./data/ActuralTrade/snap_{ymd}.xlsx")



class tool:

    def DFcolumnToList(inDF, colname:str):
        col_list = []
        col_list = inDF[colname].astype(str).tolist()
        return col_list
    
    def WaitingTimeDecide(secs:int = 30):
        closetime = "14:00:00"
        # 這段是防止開盤後run時跑去等開盤時間
        if datetime.now().time() > datetime.strptime(closetime, "%H:%M:%S").time() or datetime.today().weekday() in (5, 6):
            wait = 0.1
        else:
            wait = secs - (int(datetime.now().strftime("%S")) % secs)
        time.sleep(wait)
    
    def calcuateTimesBetweenTwoTime(stime:str = "09:00:00", etime:str = "13:30:00", feq:int = 30):
        step = 0
        if stime > etime:
            step = 10
        else:
            step = int((datetime.strptime(etime, "%H:%M:%S") - datetime.strptime(stime, "%H:%M:%S")).seconds / feq )        
        return step

class craw:
    def __init__(self):
        self.markets = ["TSE", "OTC"]
        self.m = None
        self.head_info = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
        self.head_str = "table > thead > tr:nth-child(2) > td"
        self.item_str = "table > tbody > tr"
        self.obj = None
        self.tableID = 0
    
    def getMarketList(self):
        return self.markets

    def getBSobject(self, YMD:str, market:str = None):
        if market:
            self.m = market
        # 抓config檔決定是否要產生File
        genfile = cfg().getConfigValue(key = "genhtml")
        # 取得網址-上市
        if self.m == "TSE":
            # 網頁取得自 https://www.twse.com.tw/zh/page/trading/fund/T86.html (列印 / HTML)
            # url = f"https://www.twse.com.tw/fund/T86?response=html&date={YYYYMMDD}&selectType=ALL"
            url = f"https://www.twse.com.tw/fund/T86?response=html&date={YMD}&selectType=ALLBUT0999"
        # 取得網址-上櫃(用民國年)
        if self.m == "OTC":
            # 網頁取得自 https://www.tpex.org.tw/web/stock/3insti/daily_trade/3itrade_hedge.php?l=zh-tw (列印/匯出HTML)
            cymd = f"{str(int(YMD[0:4]) - 1911)}/{YMD[4:6]}/{YMD[6:8]}"
            url = f"https://www.tpex.org.tw/web/stock/3insti/daily_trade/3itrade_hedge_result.php?l=zh-tw&o=htm&se=EW&t=D&d={cymd}&s=0,asc"

        # 處理網址
        urlwithhead = req.get(url, headers = self.head_info)
        urlwithhead.encoding = "utf-8"
        # 決定是否把html寫入file
        if genfile != "":
            ## 寫網頁原始碼到檔案中cfg是config檔的路徑及檔名
            wpath = cfg().getConfigValue(key = "webpath")
            # 產生出的檔案存下來
            ## 建立目錄,不存在才建...
            if os.path.exists(wpath) == False:
                os.makedirs(wpath)
            rootlxml = bs(urlwithhead.text, "lxml")
            with open(f"{wpath}/{market}_三大法人買賣超日報_{YMD}.html", mode="w", encoding="UTF-8") as web_html:
                web_html.write(rootlxml.prettify())
        # 產生BeautifulSoup物件
        bsobj = bs(urlwithhead.text, "lxml")
        return bsobj

    def getTBobjectFromBSobject(self, in_bsobj = None, tbID:int = 0, market:str = None):
        if in_bsobj:
            self.obj = in_bsobj
        if tbID:
            self.tableID = tbID
        if market:
            self.m = market

        # 抓config檔決定是否要產生File
        genfile = cfg().getConfigValue(key = "genhtml")

        tbobj = self.obj.find_all("table")[self.tableID]
        
        # 決定是否把html寫入file
        if genfile != "":
            ## 寫網頁原始碼到檔案中cfg是config檔的路徑及檔名
            wpath = cfg().getConfigValue(key = "webpath")
            # 產生出的檔案存下來
            ## 建立目錄,不存在才建...
            if os.path.exists(wpath) == False:
                os.makedirs(wpath)
            with open(f"{wpath}/{self.m}_table.html", mode="w", encoding="UTF-8") as web_html:
                web_html.write(tbobj.prettify())
        return tbobj

    def getHeaderLine(self, in_tbobj = None):
        if in_tbobj:
            self.obj = in_tbobj

        headtext = []
        for head in self.obj.select(self.head_str):
            headtext.append(head.text)
        return headtext
    
    def getItemListForMarket(self, in_tbobj = None, market:str = None):
        if in_tbobj:
            self.obj = in_tbobj
        if market:
            self.m = market

        itemlist = []
        for rows in self.obj.select(self.item_str)[0:]:
            item = []
            colnum = 0
            for col in rows.select("td"):
                colnum += 1
                if colnum in (1, 2):
                    val = col.string.strip()
                else:                
                    val = int(col.text.replace(",", "").strip())
                if self.m == "OTC" and colnum in [9, 10, 11, 21, 22]:
                    continue
                item.append(val)
            if  self.m == "OTC":
                neworder = list(range(0,11)) + [17] + list(range(11,17)) + [18]
                item = [item[i] for i in neworder]
            itemlist.append(item)
        return itemlist