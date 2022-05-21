import shioaji as sj
import pandas as pd
import json
from datetime import datetime, date, timedelta
import random
from vnpy.trader.database import get_database
from vnpy.trader.object import BarData, Exchange, Interval
import pytz


class config:
    def __init__(self, cfg: str = None)->None:
        self.cfg_file = "../Stock/config/config.json"
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


class connect:
    def __init__(self, insrt_api = sj.Shioaji) -> None:
        self.api = insrt_api
        self.acct_file = "../Stock/config/account.json"    # 帳號設定檔
        self.simulation = True  # 是否為測試環境
        self.id = "PAPIUSER0" + str(random.randint(1,8))    # 測試環境帳號
        self.pwd = "2222"   # 測試環境密碼
        self.ca_acct = "chris"  # 憑證預設使用者名
        self.ca_userID = None   # 憑證ID(身份證字號)
        self.ca_cuname = None   # 憑證裡面對應的中文名
        # 在json中的key
        self.key_login = "login_usr"
        self.key_tradeacct = "trade_account"
        self.key_capwd = "ca_pwd"
        self.key_capath = "ca_path"
        
        self.opening = "09:00"

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

    def ServerConnectLogin(self, simulte: bool = False, user: str = "chris", ca: str = None)->sj.Shioaji:
        self.api = sj.Shioaji(simulation = simulte)
        if simulte == False:
            idpwd_Dict = config(self.acct_file).getValueByConfigFile(key = self.key_login)
            self.id = idpwd_Dict.get(user.lower())[0]
            self.pwd = idpwd_Dict.get(user.lower())[1]
            env_name = "Actural"
        else:
            env_name = "Simulation"         
        
        try:
            self.api.login(person_id = self.id, passwd = self.pwd, contracts_timeout = 0)
            
            print(f"Login {env_name} Environment Success!!({self.id})")
            if env_name == "Actural" and ca:
                self.ca_acct = ca
                self.SetTreadAccount()
                self.InsertCAFile()
            return self.api
        except Exception as exc:
            return print(f"user: {self.id}, pwd: {self.pwd}, Login Fail!...{exc}") 
    
    def getKbarData(self, stkid:str = None, sdate:str = str(date.today() - timedelta(days = 365)), edate:str = str(date.today()))->pd.DataFrame:
        if sdate:
            self.startdate = sdate
            self.enddate = sdate 
        
        if edate:
            self.enddate = edate

        outDF = pd.DataFrame()
        try:
            outDF = pd.DataFrame({**self.api.kbars(self.api.Contracts.Stocks[stkid], start = self.startdate, end = self.enddate)})
            outDF.ts = pd.to_datetime(outDF.ts)
            # outDF["TradeDate"] = pd.to_datetime(outDF.ts).dt.strftime("%Y%m%d")
            # outDF["TradeTime"] = pd.to_datetime(outDF.ts).dt.time
            # outDF["DateTime"] = pd.to_datetime(outDF.ts)
            # outDF.insert(0, "StockID", str(stkid))
            # outDF = outDF.sort_values(by = "ts")
        except Exception as exc:
            return print(exc)
        return outDF

class file:
    def GeneratorFromDF(genDF: pd.DataFrame, fname: str, ftype: str = "xlsx")->None:
        if ftype.lower() == "csv":
            genDF.to_csv(fname, index = False, encoding = "utf_8_sig")
        if ftype.lower() == "xlsx":
            genDF.to_excel(fname, index = False)

class database:

    def importDataToVnpyDB(df: pd.DataFrame, stkid: str)->None:
        bar_data = []
        TW_TZ = pytz.timezone("Asia/Taipei")

        if df is None:
            return print("資料不存在")
            
        for index, row in df.iterrows():
            bar = BarData(
                symbol = stkid,
                exchange = Exchange.LOCAL,
                datetime = TW_TZ.localize(row['ts'].to_pydatetime()) - timedelta(minutes = 1),
                interval = Interval.MINUTE,
                volume = row.Volume,
                open_price = row.Open,
                high_price = row.High,
                low_price = row.Low,
                close_price = row.Close,
                gateway_name = "Sinopac"
            )

            bar_data.append(bar)

        database = get_database()
        database.save_bar_data(bar_data)
        print(f"股票代號:{stkid}｜{bar_data[0].datetime}-{bar_data[-1].datetime} 歷史數據匯入成功，總共{len(bar_data)}筆資料")
