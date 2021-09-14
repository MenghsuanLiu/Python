import shioaji as sj
import json
import sqlalchemy
import pymysql
import pandas as pd


class con:
    # def __init__(self, user, pwd):
    #     self.db_user = user
    #     self.db_pwd = pwd

    def connectToServer(loginfile):
        # 登入帳號
        api = sj.Shioaji(backend = "http", simulation = False) 
        with open(loginfile, "r") as f:
            login_cfg = json.loads(f.read())
        api.login(**login_cfg, contracts_timeout = 0)
        return api
    
    def connectToSimServer():
        # 登入帳號
        api = sj.Shioaji(simulation = True) 
        api.login(
            # PAPIUSER01~PAPIUSER08
            person_id = "PAPIUSER07", 
            passwd = "2222", 
            contracts_cb = lambda security_type: print(f"{repr(security_type)} fetch done.")
        )
        return api

    def InsertCAbyConfig(api, cafile):
        with open(cafile, "r") as f:
            ca_cfg = json.loads(f.read())
        remsg = api.activate_ca(**ca_cfg)
        return print(remsg)

    def InsertCAbyID(api, id):
        remsg = api.activate_ca(
                            ca_path = fr"C:\ekey\551\{id}\S\Sinopac.pfx",
                            ca_passwd = id,
                            person_id = id,
)
        return remsg

    def SetDefaultAccount(api, acctype, name):
        account_cfg = "./config/account.json"
        # acctype => S:股票 F:期貨 H:
        acctid = cfg.getConfigValue(account_cfg, name.lower())
        acct = []
        i = 0
        # 取出這個帳號裡面有多少帳戶可以做交易
        while True:    
            try:
                acct.append([api.list_accounts()[i].account_type.value, api.list_accounts()[i].person_id, api.list_accounts()[i].account_id, api.list_accounts()[i].username])
                i += 1
            except:
                break
        acctDF = pd.DataFrame(acct, columns = ["Type", "ID", "AccountID", "Name"])
        # 取得帳戶的Index,後面可以設交易帳戶
        idx = acctDF.index[(acctDF.Type == acctype) & (acctDF.AccountID == acctid)].values[0]
        # 設定預設交易帳戶
        api.set_default_account(api.list_accounts()[int(idx)])
        # 取得身份證字號,然後把慼證餵進去
        PID = acctDF.ID[(acctDF.Type == acctype) & (acctDF.AccountID == acctid)].values[0]
        msg = con.InsertCAbyID(api, PID)
        # 憑證若失敗會跳error message
        if msg == True:
            return print(f"目前使用憑證:{PID}成功!!")
        else:
            return
        




class cfg:
    # def __init__(self, cfgfile):
    #     self.file = cfgfile

    def getConfigValue(cfgfile, key):
        try:
            with open(cfgfile, encoding="UTF-8") as f:
                jfile = json.load(f)
            val = jfile[key]    
            # val =  ({True: "", False: jfile[datatype]}[jfile[datatype] == "" | jfile[datatype] == "None"])
        except:
            val = ""
        return val

class db:
    def __init__(self):
        self.user = "root"
        self.pwd = "670325"

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

class  file:
    def genFiles(cfgname, df, filename, ftype):
        gen = cfg.getConfigValue(cfgname, "genData")
        if gen.lower() == "x":
            if ftype.lower() == "csv":
                df.to_csv(filename, index = False, encoding = "utf_8_sig")
            if ftype.lower() == "xlsx":
                df.to_excel(filename, index = False)
        return