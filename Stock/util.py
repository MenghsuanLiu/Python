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
import talib
from bs4 import BeautifulSoup as bs
from datetime import datetime, date, timedelta


class cfg:
    def __init__(self, cfg: str = None)->None:
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


    # def getConfigValue(cfgfile, key):
    #     try:
    #         with open(cfgfile, encoding="UTF-8") as f:
    #             jfile = json.load(f)
    #         val = jfile[key]    
    #         # val =  ({True: "", False: jfile[datatype]}[jfile[datatype] == "" | jfile[datatype] == "None"])
    #     except:
    #         val = ""
    #     return val

class connect: 
    def __init__(self, insrt_api = sj.Shioaji) -> None:
        self.acct_mapping = "./config/account.json"
        self.loginfile = cfg().getValueByConfigFile(key = "login")
        self.api = insrt_api
        self.simulation = True  # 是否為測試環境
        self.id = "PAPIUSER0" + str(random.randint(1,8))
        self.pwd = "2222"
        self.ca_active = False
        self.ca_acct = "chris"
        self.ca_userid = None
        self.start_time = "09:00:00"
        self.end_time = "13:30:00"
        self.startdate = datetime.today().strftime("%Y-%m-%d")
        self.enddate = datetime.today().strftime("%Y-%m-%d")
        self.markets = ["TSE", "OTC"]
        self.mkt_mapping = {"TSE": "上市", "OTC": "上櫃", "OES": "興櫃"}
        self.ex_cate = ["00", "", "17"] # 排除類別00:權證, 17:金融
        self.ex_price = 20 # 排除股價
        self.tb_basic = "basicdata"
        self.tb_dohlc = "dailyholc"
        self.tb_minohlc = "dailyminsholc"
        self.trade_action = "Buy"
        self.trade_qty = 1
        
        
    def LoginToServerForStock(self, simulate: bool = True, id = None, pwd = None, ca_acct = None):
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
        if simulation().checkSimulationTime():
            outDF = self.getMinSnapshotData(contract)
            return outDF

        while True:    
            if datetime.now().strftime("%H:%M:%S") == self.start_time:
                outDF = self.getMinSnapshotData(contract)
                break
        return outDF 

    def getMinSnapshotData(self, ctract:list):
        minDF = pd.DataFrame(self.api.snapshots(ctract)).filter(items = ["code", "ts", "open", "high", "low", "close", "volume" ]).rename(columns = {"code": "StockID", "ts": "DateTime", "open": "Open", "high": "High", "low": "Low", "close": "Close", "volume": "Volume"})
        minDF.DateTime = pd.to_datetime(minDF.DateTime)
        minDF["TradeDate"] = pd.to_datetime(minDF.DateTime).dt.strftime("%Y%m%d")
        minDF["TradeTime"] = pd.to_datetime(minDF.DateTime).dt.time
        minDF["SnapShotTime"] = datetime.now().strftime("%H:%M:%S")
        minDF.StockID = minDF.StockID.astype(str)
        return minDF

    def getKbarData(self, stkid:str = None, sdate:str = None, edate:str = None):
        if sdate:
            self.startdate = sdate
            self.enddate = sdate
        
        if edate:
            self.enddate = edate

        outDF = pd.DataFrame()
        try:
            outDF = pd.DataFrame({**self.api.kbars(self.api.Contracts.Stocks[stkid], start = self.startdate, end = self.enddate)})
            outDF["TradeDate"] = pd.to_datetime(outDF.ts).dt.strftime("%Y%m%d")
            outDF["TradeTime"] = pd.to_datetime(outDF.ts).dt.time
            outDF["DateTime"] = pd.to_datetime(outDF.ts)
            outDF.insert(0, "StockID", str(stkid))
            outDF = outDF.sort_values(by = "ts")
        except Exception as exc:
            return print(exc)
        return outDF

    def StockNormalBuySell(self, stkid, price = "now", qty:int = 1, action:str = None):
        # Order參數說明  action{Buy, Sell}, price_type{LMT(限價), MKT(市價), MKP(範圍市價)} p.s MKT/MKP只能搭IOC, price = 0
        #               order_type{ROD, IOC, FOK}, order_cond{Cash(現股), MarginTrading(融資), ShortSelling(融券)}
        #               order_lot{Common(整股), Fixing(定盤), Odd(盤後零股), IntradayOdd(盤中零股)}
        Ctract = self.api.Contracts.Stocks[stkid]
        if action:
            self.trade_action = action
        if qty:
            self.trade_qty = qty
        
        myotype = "ROD"
        myptype = "LMT"
        myprice = price
        # 漲停
        if price == "up":
            myprice = Ctract.limit_up
        # 跌停
        if price == "down":
            myprice = Ctract.limit_down    
        # 現價
        if price == "now":
            myprice = 0
            myotype = "IOC"
            myptype = "MKT"   
        # 下單    
        order = self.api.Order(
                                price = myprice, 
                                quantity = self.trade_qty, 
                                action = self.trade_action, 
                                price_type = myptype, 
                                order_type = myotype,
                                order_cond = "Cash",
                                order_lot = "Common",                     
                                account = self.api.stock_account
                             )
        self.api.place_order(Ctract, order)

    def StockCancelOrder(self, stkid:str = "all"):
        data = []
        # 先更新一下
        self.api.update_status(self.api.stock_account)
        for i in range(0, len(self.api.list_trades())):
            if self.api.list_trades()[i].status.status.value != "Cancelled":
                # <-log用        
                l = []
                l.append(self.api.list_trades()[i].contract.code)
                l.append(self.api.list_trades()[i].status.status.value)
                l.append(datetime.now().strftime("%H:%M:%S"))
                data.append(l)
                # ->log用        
                if stkid != "all" and  self.api.list_trades()[i].contract.code == stkid:
                    self.api.cancel_order(self.api.list_trades()[i])
                    continue
                # 以下是全刪要走的部份
                try:
                    self.api.cancel_order(self.api.list_trades()[i])
                    id = self.api.list_trades()[i].contract.code
                    ts = self.api.list_trades()[i].status.order_datetime.strftime("%Y/%m/%d %H:%M:%S")
                    print(f"己取消股票代碼:{id},於{ts}下的單")
                except:
                    continue
        # <-log用        
        if data != []:
            DF = pd.DataFrame(data, columns = ["StockID", "Status", "Time"])
            path = "./data/ActuralTrade/" + datetime.now().strftime("%Y%m")
            ymd = datetime.now().strftime("%Y%m%d_%H%M%S")
            fpath = f"{path}/cancellog_{ymd}.xlsx"
            file.GeneratorFromDF(DF, fpath)
        # ->log用        
        # if stkid == "all":
        #     for i in range(0, len(self.api.list_trades())):
        #         if self.api.list_trades()[i].status.status.value != "Cancelled":
        #             self.api.cancel_order(self.api.list_trades()[i])
        #             id = self.api.list_trades()[i].contract.code
        #             ts = self.api.list_trades()[i].status.order_datetime.strftime("%Y/%m/%d %H:%M:%S")
        #             print(f"己取消股票代碼:{id},於{ts}下的單")
 

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

    def getOrderStatusDF(self):
        pass

    def SubscribeTick(self, contract):
        self.api.quote.subscribe(contract, quote_type = sj.constant.QuoteType.Tick)

    def UnsubscribeTick(self, contract):
        self.api.quote.unsubscribe(contract, quote_type=sj.constant.QuoteType.Tick)

    # def getMinsSnapshotData(self, contract = None, times: int = 10, usecs:int = 60):
    #     self.start_time = (datetime.strptime(self.start_time, "%H:%M:%S") + timedelta(minutes = times)).strftime("%H:%M:%S")
    #     outDF = pd.DataFrame()
    #     # 收盤後只要取一次就好
    #     if simulation().checkSimulationTime():
    #         outDF = self.getMinSnapshotData(contract)
    #         return outDF
        
    #     while True:
    #         outDF = outDF.append(self.getMinSnapshotData(contract))            
    #         if datetime.now().strftime("%H:%M:%S") == self.start_time:
    #             break
    #         tool.WaitingTimeDecide(usecs)
  
class db:
    def __init__(self):
        self.tb_name = None
        self.dbusr = "root"
        self.dbpwd = "670325"
        self.dbname = "stock"
        self.dbmode = None
        self.statment = None
        self.col_name = None
        self.trade_date = None

    def getStockBasicData(self):
        basicDF = self.selectDatatoDF(cfg().getValueByConfigFile(key = "tb_basic")).filter(items = ["StockID", "categoryID"]).rename(columns = {"categoryID": "cateID"})
        cateDF = self.selectDatatoDF(cfg().getValueByConfigFile(key = "tb_ind")).filter(items = ["cateID", "cateDesc"])
        return basicDF.merge(cateDF, on = "cateID", how = "left")

    def connLoclmySQL(self, db_name:str = None, con_mode:str = None):
        # 有指定db就用指定的,其他用預設
        if db_name:
            self.dbname = db_name

        # mode中有給值就是要做update
        if con_mode:
            self.dbmode = con_mode
            return sqlalchemy.create_engine(f"mysql+pymysql://{self.dbusr}:{self.dbpwd}@localhost/{self.dbname}?charset=utf8")
        
        return pymysql.connect(host = "localhost", user = self.dbusr, passwd = self.dbpwd, database = self.dbname)

    def selectDatatoDF(self, tb_name:str = None, sql_statment:str = None):
        outDF = pd.DataFrame()
        if tb_name:
            self.tb_name = tb_name  
            self.statment = f"SELECT * FROM {self.tb_name}"

        if sql_statment:
            self.statment = sql_statment

        try:
            dbcon = self.connLoclmySQL()
            outDF = pd.read_sql(self.statment, con = dbcon)
        except Exception as exc:
            print(exc) 
        return outDF
    
    def updateDFtoDB(self, insertDF: pd.DataFrame, tb_name:str = None):
        if not tb_name:
            return print("請輸入需要upDate的Table Name")
        else:
            self.tb_name = tb_name

        dbcon = self.connLoclmySQL(con_mode = "update")
        try:
            insertDF.to_sql(con = dbcon, name = self.tb_name, if_exists = "append", index = False)
            return print(f"Update Table {self.tb_name} Success!")
        except Exception as exc:
            print(f"Fail to Update Table {self.tb_name}, Check It Please!!!!!")
            print(exc)
            return 
        
    def getMAXvalueFromDBTableColumn(self, tb_name:str = None, col_name:str = None):
        if tb_name:
            self.tb_name = tb_name
        if col_name:
            self.col_name = col_name
        maxvalue = None
        try:
            maxvalue =  self.selectDatatoDF(sql_statment = f"SELECT MAX({self.col_name}) as col FROM {self.tb_name}").iloc[0, 0]
        except:
            pass
        return maxvalue

    def getDailySanpshotFromDBbyDF(self, inDF: pd.DataFrame, t_date:str = None, tb_type:str = "mins"):        
        if t_date:
            self.trade_date = t_date.replace("/", "").replace("-", "")

        tup_stk = tuple(tool.DFcolumnToList(inDF = inDF, colname = "StockID"))

        if tb_type == "mins":    
            tb = cfg().getValueByConfigFile(key = "tb_mins")
            sql = f"SELECT *, TIMESTAMP(TradeDate, TradeTime) as DateTime FROM {tb} WHERE TradeDate = {self.trade_date} AND StockID IN {tup_stk}"
            # 這個出來沒有值就會是 DF.empty
            return self.selectDatatoDF(sql_statment = sql).sort_values(by = ["StockID", "DateTime"], ascending = True).drop(columns = ["modifytime", "TradeDate", "TradeTime"])

        if tb_type == "day":
            tb = cfg().getValueByConfigFile(key = "tb_daily")
            sql = f"SELECT * FROM {tb} WHERE TradeDate = {self.trade_date} AND StockID IN {tup_stk}"
            # 這個出來沒有值就會是 DF.empty
            return self.selectDatatoDF(sql_statment = sql).sort_values(by = ["StockID", "TradeDate"], ascending = True).drop(columns = ["modifytime"])

    # def mySQLconn(dbname, fn):
    #     db_usr = "root"
    #     db_pwd = "670325"
    #     if fn == "pd_update":
    #         return sqlalchemy.create_engine(f"mysql+pymysql://{db_usr}:{db_pwd}@localhost/{dbname}?charset=utf8")
    #     else:
    #         return pymysql.connect(host = "localhost", user = db_usr, passwd = db_pwd, database = dbname)

    # def delDataFromDB(tbfullname, cond_dict):
    #     cols, vals = list(cond_dict.items())[0]
        
    #     db_con = db.mySQLconn(tbfullname.split(".")[0], "delete")
    #     cur = db_con.cursor()
    #     if isinstance(vals, str):
    #         cur.execute(f"DELETE FROM {tbfullname} WHERE {cols} = {vals}")
    #     else:
    #         cur.execute(f"DELETE FROM {tbfullname} WHERE {cols} IN {vals}")
    #     db_con.commit()
    #     return print(f"Delete Table {tbfullname} Value Success!")        

    # def updateDataToDB(tbfullname, updf):
    #     updb_con = db.mySQLconn(tbfullname.split(".")[0], "pd_update")
    #     new_df = updf
    #     # 不同Table處理方式不太一樣,就只要一直加(不需刪舊的)        
    #     if tbfullname.split(".")[1] == "basicdata":
    #         df_org = db.readDataFromDBtoDF(tbfullname, "")         
    #         if not df_org.empty:
    #             new_df = new_df.append(df_org)
    #             # 差集(這次DF沒有, DB有要再處理)
    #             new_df = new_df.drop_duplicates(subset = ["StockID"], keep = False)
    #             # 留下DB有但這次沒有
    #             new_df = pd.merge(new_df, updf.filter(items = ["StockID"]), on = ["StockID"]).dropna(axis = "columns")
    #     # else:
    #         # # 取得要做Delete的ColumnName
    #         # colname = ""
    #         # if tbfullname.split(".")[1] in ["dailyvolume", "dailyminsholc"]:
    #         #     colname = "TradeDate"
    #         # if tbfullname.split(".")[1] in ["dailyholc", "testable"]:
    #         #     colname = ("StockID", "TradeDate")
    #         #     del_df = updf.filter(items = ["StockID", "TradeDate"])
    #         #     del_df["TradeDate"] = del_df["TradeDate"].apply(lambda x: x.strftime("%Y%m%d"))
    #         #     subsetlst = tuple(zip(del_df.StockID, del_df.TradeDate))
    #         # new_df = updf
    #     if not new_df.empty:
    #         try:
    #             new_df.to_sql(con = updb_con, name = tbfullname.split(".")[1], if_exists = "append", index = False)
    #             return print(f"Update Table {tbfullname} Success!")
    #         except:
    #             return print(f"Fail to Update Table {tbfullname} !!!!!")
    #     else:
    #         return print(f"No New Data need to Update ({tbfullname})!")

    # def readDataFromDBtoDF(tbfullname, dict_filter):
    #     db_con = db.mySQLconn(tbfullname.split(".")[0], "read")
    #     if dict_filter == "":
    #         return pd.read_sql(f"SELECT * FROM {tbfullname}", con = db_con)
    #     else:
    #         col, value = list(dict_filter.items())[0]
    #         if isinstance(value, str):
    #             return pd.read_sql(f"SELECT * FROM {tbfullname} WHERE {col} = {value}", con = db_con)
    #         else:
    #             return pd.read_sql(f"SELECT * FROM {tbfullname} WHERE {col} IN {value}", con = db_con)

class file:
    stkDF = pd.DataFrame()
    def __init__(self) -> None:
        self.beforedays = 0

    # days決定往前或往後的天數
    def getLastFocusStockDF(self, days:int = 0):
        if days:
            self.beforedays = days

        matching = []
        i = 0
        while True:
            # 算出最近有資料的那一天
            ymd = (date.today() - timedelta(days = i)).strftime("%Y%m%d")
            filelst = os.listdir(cfg().getValueByConfigFile(key = "dailypath") + f"/{ymd[0:6]}")
            fname = cfg().getValueByConfigFile(key = "resultname") + f"_{ymd}.xlsx"
            matching = [s for s in filelst if fname in s]
            i += 1
            if matching !=[]:
                break
            
        while True:
            if self.beforedays != 0:
                matching = []
                ymd = (datetime.strptime(ymd, "%Y%m%d") + timedelta(days = self.beforedays)).strftime("%Y%m%d")
                filelst = os.listdir(cfg().getValueByConfigFile(key = "dailypath") + f"/{ymd[0:6]}")
                fname = cfg().getValueByConfigFile(key = "resultname") + f"_{ymd}.xlsx"
                matching = [s for s in filelst if fname in s]
            
            if matching == []:
                if self.beforedays < 0:
                    self.beforedays -= 1
                if self.beforedays > 0:
                    self.beforedays += 1
                continue
            ffpath = cfg().getValueByConfigFile(key = "dailypath") + f"/{ymd[0:6]}/" + cfg().getValueByConfigFile(key = "resultname") + f"_{ymd}.xlsx"
            break

        stkDF = pd.read_excel(ffpath)
        stkDF.StockID = stkDF.StockID.astype(str)
        return stkDF

    def GeneratorFromDF(genDF: pd.DataFrame, fname: str, ftype: str = "xlsx"):
        if ftype.lower() == "csv":
            genDF.to_csv(fname, index = False, encoding = "utf_8_sig")
        if ftype.lower() == "xlsx":
            genDF.to_excel(fname, index = False)

    # def genFiles(cfgname, df, filename, ftype):
    #     gen = cfg.getConfigValue(cfgname, "genData")
    #     if gen.lower() == "x":
    #         if ftype.lower() == "csv":
    #             df.to_csv(filename, index = False, encoding = "utf_8_sig")
    #         if ftype.lower() == "xlsx":
    #             df.to_excel(filename, index = False)
    #     return

class strategy:
    def __init__(self, DF: pd.DataFrame):
        self.basicDF = db().getStockBasicData()
        self.in_DF = DF
        self.in_DFchangename = DF.rename(columns = {"投信(股數)": "Credit"})
        self.out_DF = pd.DataFrame()
        self.rows = int(round(DF.StockID.count() * 0.1, 0)) # 前10%的交易量
        self.method = 0

    def SMA_Volume(self):
        out_DF =  self.in_DF.loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.Volume >= 5000)]
        return out_DF.merge(self.basicDF, on = ["StockID"], how = "left").drop(columns = ["cateID"])

    def getFromFocusOnByStrategy(self, no_credit:bool = False):
        self.SMA_SAR_Volume_MAXMIN()

        if self.out_DF.empty:
            self.SMA_SAR_Volume()

        if self.out_DF.shape[0] > 20 and no_credit == False:
            self.SMA_SAR_Volume_CreditBuy()

        return self.out_DF

    # 邏輯: 前一交易日成交價 > 60MA & 10MA,且成交量 >= 1/10, 股價不要超過150
    def SMA_SAR_Volume(self):
        try:
            # out_DF =  self.in_DF.loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.Volume >= 5000) & (self.in_DF.sgl_SAR > 0)]
            # self.out_DF = self.in_DF.nlargest(self.rows, "Volume").loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.sgl_SAR > 0)]
            self.out_DF = self.in_DF.nlargest(self.rows, "Volume").loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.sgl_SAR > 0) & (self.in_DF.Close <= 150)]
            self.out_DF = self.out_DF.merge(self.basicDF, on = ["StockID"], how = "left").drop(columns = ["cateID"])
            self.method = 2
        except:
            pass


    def SMA_SAR_Volume_MAXMIN(self):
        try:
            # out_DF = self.in_DF.loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.Volume >= 5000) & (self.in_DF.sgl_SAR > 0) & (self.in_DF.sgl_MAXMIN > 0)]
            # self.out_DF = self.in_DF.nlargest(self.rows, "Volume").loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.sgl_SAR > 0) & (self.in_DF.sgl_MAXMIN > 0)]
            self.out_DF = self.in_DF.nlargest(self.rows, "Volume").loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.sgl_SAR > 0) & (self.in_DF.sgl_MAXMIN > 0) & (self.in_DF.Close <= 150)]
            self.out_DF = self.out_DF.merge(self.basicDF, on = ["StockID"], how = "left").drop(columns = ["cateID"])
            self.method = 1
        except:
            pass

    # 多加一個投信買超
    def SMA_SAR_Volume_CreditBuy(self):
        self.out_DF = pd.DataFrame()
        if self.method == 1:
            self.out_DF = self.in_DFchangename.nlargest(self.rows, "Volume").loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.sgl_SAR > 0) & (self.in_DF.sgl_MAXMIN > 0) & (self.in_DF.Credit > 0) & (self.in_DF.Close <= 150)]
        if self.method == 2:
            self.out_DF = self.in_DFchangename.nlargest(self.rows, "Volume").loc[(self.in_DF.sgl_SMA > 0) & (self.in_DF.sgl_SAR > 0) & (self.in_DF.Credit > 0)].rename(columns = {"Credit": "投信(股數)"})
        self.out_DF = self.out_DF.merge(self.basicDF, on = ["StockID"], how = "left").drop(columns = ["cateID"])


    # 買進策略:5min的Close < 前一天的Close * 1.05
    def BuyStrategyFromOpenSnapDF_01(self, snap_DF: pd.DataFrame)->pd.DataFrame:
        MergeDF = self.in_DF.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).merge(snap_DF.filter(items = ["StockID", "Open", "High", "Close"]).rename(columns = {"Close": "snapClose"}), on = ["StockID"], how = "left")
        MergeDF["BuyFlag"] = ""
        
        MergeDF.loc[(MergeDF["snapClose"] < MergeDF["Close"] * 1.05), "BuyFlag"] = "X"
        BuyDF = MergeDF.loc[MergeDF.BuyFlag == "X"]
        return BuyDF.drop(columns = ["BuyFlag", "High", "snapClose", "Close"])
    # 買進策略:a.5min價 < 前一交易收盤價+5% b.5min價 >= 開盤價(紅K) c.5min價>= 最高價*(1 - 0.01)
    def BuyStrategyFromOpenSnapDF_02(self, snap_DF: pd.DataFrame)->pd.DataFrame:
        MergeDF = self.in_DF.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).merge(snap_DF.filter(items = ["StockID", "Open", "High", "Close"]).rename(columns = {"Close": "snapClose"}), on = ["StockID"], how = "left")
        MergeDF["BuyFlag"] = ""

        MergeDF.loc[(MergeDF["snapClose"] < MergeDF["Close"] * 1.05) & (MergeDF["snapClose"] >= MergeDF["Open"]) & (MergeDF["snapClose"] >= MergeDF["High"] * (1 - 0.01)), "BuyFlag"] = "X"
        BuyDF = MergeDF.loc[MergeDF.BuyFlag == "X"]        
        return BuyDF.drop(columns = ["BuyFlag", "High", "snapClose", "Close"])

    def BuyStrategyFromOpenSnapDF_03(self, snap_DF: pd.DataFrame)->pd.DataFrame:
        snap_DF = snap_DF.set_index("DateTime").groupby("StockID").resample("5T", label = "right", closed = "right").agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
        ymd = datetime.now().strftime("%Y%m%d")
        if snap_DF != []:
            file.GeneratorFromDF(snap_DF, f"./data/ActuralTrade/snap_{ymd}.xlsx")

class indicator:
    def __init__(self, inDF):
        self.DF = inDF         
        self.MAtype = "SMA"
        self.MAperiod = [5, 10, 20, 60]
        self.MAXMINperiod = [120, 240]
        self.MAXMINtype = ["MAX", "MIN"]
        self.indicators = ["SMA", "SAR", "MAXMIN", "BBANDS", "RSI", "MACD", "KDJ"]

    # https://rich01.com/what-is-moving-average-line/
    def addMAvalueToDF(self, ma_type:str = None, period = None):
        # talib只有SMA / EMA / WMA
        if ma_type:
            self.MAtype = ma_type
        if period:
            self.MAperiod = period

        outDF = pd.DataFrame()
        for stockid, gpDF in self.DF.groupby("StockID"):
            if type(self.MAperiod) is int:
                # https://www.kite.com/python/answers/how-to-call-a-function-by-its-name-as-a-string-in-python 用字串弄成Function
                gpDF[f"{self.MAtype}_{self.MAperiod}"] = eval("talib." + self.MAtype + "(gpDF.Close, timeperiod = self.MAperiod)")
                outDF = outDF.append(gpDF)
                continue

            for p in self.MAperiod:
                gpDF[f"{self.MAtype}_{p}"] = eval("talib." + self.MAtype + "(gpDF.Close, timeperiod = p)")
            
            outDF = outDF.append(gpDF)
        return outDF

     # https://rich01.com/what-is-macd-indicator/
    
    # https://rich01.com/what-is-macd-indicator/
    def addMACDvalueToDF(self, f_period:int = 12, s_period:int = 26, sign_period:int = 9):
        # 當柱狀(HIST)圖由負轉正，可視為買進訊號；(代表快線向上穿過慢線，黃金交叉)
        # 柱狀圖由正轉負，可視為賣出訊號。(代表快線向下穿過慢線，死亡交叉)
        outDF = pd.DataFrame()
        for stockid, gpDF in self.DF.groupby("StockID"):
            gpDF["MACD"], gpDF["MACD_DIF"], gpDF["HIST"] = talib.MACD(gpDF.Close.values, fastperiod = f_period, slowperiod = s_period, signalperiod = sign_period)

            outDF = outDF.append(gpDF)
        return outDF

    # https://rich01.com/rsi-index-review/
    # cnam_noprd =>指欄位名不要加"_period",只要RSI
    def addRSIvalueToDF(self, period:int = 0, cnam_noprd:bool = False):
        outDF = pd.DataFrame()
        if cnam_noprd == True:
            colname = "RSI"
        else:
            colname = f"RSI_{period}"
        for stockid, gpDF in self.DF.groupby("StockID"):
            gpDF[colname] = talib.RSI(gpDF.Close, timeperiod = period)
            outDF = outDF.append(gpDF)
        return outDF

    # https://rich01.com/what-is-bollinger-band/
    def addBBANDvalueToDF(self, period:int = 10, sigma:int = 2):
        outDF = pd.DataFrame()
        for stockid, gpDF in self.DF.groupby("StockID"):
            gpDF["BBU"], gpDF["BBM"], gpDF["BBL"] = talib.BBANDS(gpDF.Close, timeperiod = period, nbdevup = sigma, nbdevdn = sigma, matype = 0)
            outDF = outDF.append(gpDF)
        return outDF
    
    def addKDJvalueToDF(self, fk_perd:int = 9, s_perd:int = 3):
        outDF = pd.DataFrame()
        for stockid, gpDF in self.DF.groupby("StockID"):
            gpDF["SlowK"], gpDF["SlowD"] = talib.STOCH(gpDF.High, gpDF.Low, gpDF.Close, fastk_period = fk_perd, slowk_period = s_perd, slowd_period = s_perd)
            # 求出J值，J = (3 * D) - (2 * K)
            gpDF["SlowJ"] = list(map(lambda x,y: 3 * x - 2 * y, gpDF.SlowK, gpDF.SlowD))

            outDF = outDF.append(gpDF)
        return outDF

    def addSARvalueToDF(self, acc:float = 0.02, max:float = 0.2):
        col = str(acc).replace(".", "")
        outDF = pd.DataFrame()
        for stockid, gpDF in self.DF.groupby("StockID"):
            gpDF[f"SAR_{col}"] = talib.SAR(gpDF.High, gpDF.Low, acceleration = acc, maximum = max)
            outDF = outDF.append(gpDF)
        return outDF

    def addMAXMINvalueToDF(self, period:list = None, fn:list = None):
        if period:
            self.MAXMINperiod = period
        
        if fn:
            self.MAXMINtype = fn

        outDF = pd.DataFrame()
        for stockid, gpDF in self.DF.groupby("StockID"):
            for f in self.MAXMINtype:
                fn_name = f.lower()
                for p in self.MAXMINperiod:
                    gpDF[f"{f}_{p}"] = eval(f"gpDF.Close.rolling(p).{fn_name}()")
            outDF = outDF.append(gpDF)
        return outDF

    def addMFIvalueToDF(self):
        outDF = pd.DataFrame()
        for stockid, gpDF in self.DF.groupby("StockID"):
            gpDF["MFI"] = talib.MFI(gpDF.High, gpDF.Low, gpDF.Close, gpDF.Volume)
            outDF = outDF.append(gpDF)
        return outDF
    # 這個是給getSignalByIndicator使用
    def addMAXMINvalueWithColumnToDF(self, period:list = [], fn_col: dict = {}):
        if period:
            self.MAXMINperiod = period
        
        if fn_col:
            self.MAXMINtype = fn_col
        
        outDF = pd.DataFrame()
        for stockid, gpDF in self.DF.groupby("StockID"):
            for key in self.MAXMINtype:
                colname = self.MAXMINtype[key]
                fn_name = key.lower()
                for p in self.MAXMINperiod:
                    gpDF[f"{key}_{p}"] = eval(f"gpDF.{colname}.rolling(p).{fn_name}()")
            outDF = outDF.append(gpDF)
        self.DF = outDF

    def addShiftColumnValueToDF(self, colname:str = None, sfnum:int = 1):
        outDF = pd.DataFrame()
        for stockid, gpDF in self.DF.groupby("StockID"):
            gpDF[f"{colname}_shift{sfnum}"] = eval(f"gpDF.{colname}.shift({sfnum})")
            outDF = outDF.append(gpDF)
        self.DF = outDF
        
        self.DF["HIST_SHIFT_1"] = self.DF.HIST.shift(1)

    def getSignalByIndicator(self, inds:list = []):        
        if inds:
            self.indicators = inds

        for ind in self.indicators:
            colnam = f"sgl_{ind}"
            self.DF[colnam] = 0
            
            if ind.lower() == "sma":
                self.DF.loc[(self.DF.Close > self.DF.SMA_10) & (self.DF.Close > self.DF.SMA_60), colnam] = 1
                self.DF.loc[(self.DF.Close < self.DF.SMA_10) & (self.DF.Close < self.DF.SMA_60), colnam] = -1
            if ind.lower() == "sar":
                self.addMAXMINvalueWithColumnToDF(period = [9, 26, 52], fn_col = {"MAX": "High", "MIN": "Low"})
                self.DF["tenkan_sen_line"] = (self.DF.MAX_9 + self.DF.MIN_9) / 2
                self.DF["kijun_sen_line"] = (self.DF.MAX_26 + self.DF.MIN_26) / 2
                self.DF["senkou_spna_A"] = ((self.DF.tenkan_sen_line + self.DF.kijun_sen_line) / 2).shift(26)
                self.DF["senkou_spna_B"] = ((self.DF.MAX_52 + self.DF.MIN_52) / 2).shift(26)
                self.DF["chikou_span"] = self.DF.Close.shift(-26)

                self.DF.loc[(self.DF.Close > self.DF.senkou_spna_A) & (self.DF.Close > self.DF.senkou_spna_B) & (self.DF.Close > self.DF.SAR_002) & (self.DF.Close > self.DF.SAR_003), colnam] = 1
                self.DF.loc[(self.DF.Close < self.DF.senkou_spna_A) & (self.DF.Close < self.DF.senkou_spna_B) & (self.DF.Close < self.DF.SAR_002) & (self.DF.Close < self.DF.SAR_003), colnam] = -1
                self.DF = self.DF.drop(columns = ["tenkan_sen_line", "kijun_sen_line", "senkou_spna_A", "senkou_spna_B", "chikou_span", "MAX_9", "MIN_9", "MAX_26", "MIN_26", "MAX_52", "MIN_52"])
            
            if ind.lower() == "bbands":
                # ❶股價由下往上穿越下線：股價可能短期會反轉。
                # ❷股價由下往上穿越中線：股價可能會加速向上，是買進訊號。
                # ❸股價在中線與上線之間：代表目前為多頭行情。
                # ➍股價由上往下跌破上線：暗示上漲趨勢結束，是賣出的訊號。
                # ❺股價由上往下跌破中線：股價可能會下跌，是賣出訊號。
                # ❻股價在中線與下線之間：代表目前為空頭行情。
                self.addShiftColumnValueToDF(colname = "Close", sfnum = 1)
                self.DF.loc[(self.DF.Close > self.DF.Close_shift1) & (self.DF.Close > self.DF.BBL), colnam] = 2
                self.DF.loc[(self.DF.Close > self.DF.Close_shift1) & (self.DF.Close > self.DF.BBM), colnam] = 1
                self.DF.loc[(self.DF.Close < self.DF.Close_shift1) & (self.DF.Close < self.DF.BBU), colnam] = -2
                self.DF.loc[(self.DF.Close < self.DF.Close_shift1) & (self.DF.Close < self.DF.BBM), colnam] = -1
                # self.DF.loc[self.DF.Close > self.DF.BBU, colnam] = -1
                # self.DF.loc[self.DF.Close < self.DF.BBL, colnam] = 1

            if ind.lower() == "maxmin":
                self.DF.loc[(self.DF.Close >= self.DF.MAX_120) & (self.DF.Close >= self.DF.MAX_240), colnam] = 2
                self.DF.loc[(self.DF.Close >= self.DF.MAX_120) & (self.DF.Close <  self.DF.MAX_240), colnam] = 1
                self.DF.loc[(self.DF.Close <= self.DF.MIN_120) & (self.DF.Close >  self.DF.MIN_240), colnam] = -1
                self.DF.loc[(self.DF.Close <= self.DF.MIN_120) & (self.DF.Close <= self.DF.MIN_240), colnam] = -2

            if ind.lower() == "macd":
                self.addShiftColumnValueToDF(colname = "HIST", sfnum = 1)
                self.DF.loc[(self.DF.HIST >= 0) & (self.DF.HIST_shift1 < 0), colnam] = 1   # 前一期是-,這一期是+
                self.DF.loc[(self.DF.HIST < 0) & (self.DF.HIST_shift1 >= 0), colnam] = -1   # 前一期是+,這一期是-
                self.DF = self.DF.drop(columns = ["HIST_shift1"])

        return self.DF

class tool:

    def DFcolumnToList(inDF: pd.DataFrame, colname:str):
        col_list = []
        col_list = inDF[colname].astype(str).tolist()
        return col_list
    
    def WaitingTimeDecide(secs:int = 30):
        # closetime = "14:00:00"
        # 這段是防止開盤後run時跑去等開盤時間
        # if datetime.now().time() > datetime.strptime(closetime, "%H:%M:%S").time() or datetime.today().weekday() in (5, 6):
        if simulation().checkSimulationTime():
            wait = 0.1
        else:
            wait = secs - (int(datetime.now().strftime("%S")) % secs)
        time.sleep(wait)
    
    def calcuateFrequencyBetweenTwoTime(stime:str = "09:00:00", etime:str = "13:30:00", feq:int = 30):
        step = 0
        if stime > etime:
            step = 10
        else:
            step = int((datetime.strptime(etime, "%H:%M:%S") - datetime.strptime(stime, "%H:%M:%S")).seconds / feq )        
        return step

    def checkPathExist(c_path:str, build:bool = True)->bool:
        if build:
            if not os.path.exists(c_path):    
                os.makedirs(c_path)
                return True
        return os.path.exists(c_path)

    def checkFileExist(fname:str)->bool:
        return os.path.isfile(fname)

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
        genfile = cfg().getValueByConfigFile(key = "genhtml")
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
            wpath = cfg().getValueByConfigFile(key = "webpath")
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
        genfile = cfg().getValueByConfigFile(key = "genhtml")

        tbobj = self.obj.find_all("table")[self.tableID]
        
        # 決定是否把html寫入file
        if genfile != "":
            ## 寫網頁原始碼到檔案中cfg是config檔的路徑及檔名
            wpath = cfg().getValueByConfigFile(key = "webpath")
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

class simulation:
    def __init__(self):
        self.chk_date = datetime.today().date()
        self.chk_time = datetime.today().time()
        self.opentime = datetime.strptime("09:00:00", "%H:%M:%S").time()
        self.closetime = datetime.strptime("13:30:00", "%H:%M:%S").time()

    def checkSimulationTime(self, i_date:str = None, i_time:str = None)->bool:
        if i_date:
            self.chk_date = datetime.strptime(i_date.replace("/","").replace("-", ""), "%Y%m%d").date()
        if i_time:
            self.chk_time = datetime.strptime(i_time.replace(":", ""), "%H%M%S").time()

        if self.chk_time >= self.opentime and self.chk_time <= self.closetime:
            if self.chk_date.weekday() in range(0, 5):
                return False
        return True

    def useRSItoMakeResultDF(self, p_days:int = -1, RSI_period:int = 12, buyRSIval:int = 30, sellRSIval:int = 70):
        if not self.checkSimulationTime():
            return pd.DataFrame()
        # Sim跑下面這段
        FocusDF = file().getLastFocusStockDF(p_days)
        FocusDF = strategy(FocusDF).getFromFocusOnByStrategy(no_credit = True)
        # 1.取snapshot的資料,取出最新一天的資料(用File資料中的日期+1)
        # 2.檔案的日期要用第二天的snapshotData
        tb = cfg().getValueByConfigFile(key = "tb_mins")
        maxday_db = db().getMAXvalueFromDBTableColumn(tb_name = tb, col_name = "TradeDate")
        maxday_file = (FocusDF.TradeDate.max() + timedelta(days = 1)).date()
        # file_day + 1 > db_maxday,表示沒有更新...(這段可以考慮用更新程式)
        if maxday_db < maxday_file:
            return print(f"需要更新{tb}的資料")
        # file_day + 1 < db_maxday,表示抓的可能是多天前的資料,或是遇到休假,就一天一天加,直到抓到資料才離開
        if maxday_db > maxday_file:    
            test_date = maxday_file
            while True:
                dsnapDF = db().getDailySanpshotFromDBbyDF(FocusDF, t_date = test_date.strftime("%Y%m%d"), tb_type = "mins")
                # 沒抓到值測試日期就往上加一天
                if dsnapDF.empty:
                    test_date += timedelta(days = 1)
                    continue
                # 有抓到資料..就離開這個loop
                break
        # file_day + 1 = db_maxday,就可以直接抓資料
        if maxday_db == maxday_file:
            dsnapDF = db().getDailySanpshotFromDBbyDF(FocusDF, t_date = maxday_file.strftime("%Y%m%d"), tb_type = "mins")
        
        wiIndDF = indicator(dsnapDF).addRSIvalueToDF(period = RSI_period, cnam_noprd = True)
        wiIndDF["Buy"] = 0
        wiIndDF["Sell"] = 0
        wiIndDF.loc[(wiIndDF.RSI <= buyRSIval) & (wiIndDF.RSI > 0), "Buy"] = wiIndDF.Close
        wiIndDF.loc[(wiIndDF.RSI >= sellRSIval), "Sell"] = wiIndDF.Close
        # 留下第一個Buy及Sell
        result = []
        sell_deadline = "13:25:00"
        for stockid, gpDF in wiIndDF.groupby("StockID"):
            Buyidx = 0
            Freq = 0
            l = []            
            # 一筆一筆下去找
            for idx, row in gpDF.iterrows():
                # 先找Buy
                if Buyidx == 0 and row.Buy > 0:
                    Freq += 1
                    l.append(row.DateTime.strftime("%Y%m%d"))
                    l.append(row.StockID)
                    l.append(Freq)                    
                    l.append(row.DateTime.strftime("%H:%M:%S"))
                    l.append(row.Buy)                
                    Buyidx = idx
                    continue
                # 再找Sell
                if Buyidx > 0:
                    # 1.找到若Sell欄位有值,就留下值,清Buyidx,就可以再找下一個買
                    if row.Sell > 0:
                        l.append(row.DateTime.strftime("%H:%M:%S"))
                        l.append(row.Sell)                    
                        result.append(l)
                        Buyidx = 0
                        l = []
                        continue
                    # 2.若到了尾盤..就直接取最後的值
                    if row.DateTime.strftime("%H:%M:%S") == sell_deadline:
                        l.append(sell_deadline)
                        l.append(row.Close)
                        result.append(l)
                        break
        # 取到的List變成DF
        resultDF = pd.DataFrame()
        resultDF = pd.DataFrame(result, columns = ["TradeDate", "StockID", "Frequency","BuyTime", "Buy", "SellTime", "Sell"])
        resultDF["Profit"] = resultDF.Sell - resultDF.Buy
        return resultDF
        