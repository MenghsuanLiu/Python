# %%
import json
import pandas as pd
import pymssql
import requests as req
import sqlalchemy       # pandas read_sql使用
import os
import re
import time
from datetime import date
from dateutil.relativedelta import relativedelta
from bs4 import BeautifulSoup as bs

# 由執行所在位置決定import的方式
if os.path.basename(os.getcwd()) == "util":
    from EncryptionDecrypt import dectry
    from Logger import create_logger
    logpath = "../log"
else:
    from util.EncryptionDecrypt import dectry
    from util.Logger import create_logger
    logpath = "./log"


wlog = create_logger(logpath)

class FileProcess:
    def __init__(self, obj: bs = None, idata: list =[]) -> None:
        self.cfg_fpath = "./config/config.json"
        self.xlsx_path = "./data/result_file"
        self.obj = obj

        # 資料input
        self.data = idata

        # 由執行所在位置決定檔案路徑
        if os.path.basename(os.getcwd()) == "util":
            self.cfg_fpath = f".{self.cfg_fpath}"
            self.xlsx_path = f".{self.xlsx_path}"

        # 先檢查資料夾是否存在,不存在就先建
        if not os.path.exists(self.xlsx_path):
            os.makedirs(self.xlsx_path)
        
    # 取得config檔中的資料
    def getConfigValue(self, fpath = None, key: str = "")-> any:
        # 如果有給檔案路徑就取代Default
        if fpath != None:
            self.cfg_fpath = fpath
        # 用key取得值
        try:
            with open(self.cfg_fpath, encoding = "UTF-8") as f:
                jfile = json.load(f)
            # return ({True: None, False: jfile[key]}[jfile[key] == "" or jfile[key] == "None"])
            # 當config中沒有值,就丟出一個False
            val = ({True: False, False: jfile[key]}[jfile[key] == "" or jfile[key] == "None"])
            # 這類的設定傳bool出去
            if key in ("gen_html", "update_db", "gen_xlsx") and val != False:
                val = True
            return val
        except:
            wlog.exception("message")
            return None

    # 把資料寫到檔案中
    def generateBSobjectToFile(self, fpath: str, fnam: str)-> None:
        if self.obj != None:
            try:
                # 判斷路徑資料夾是否存在..不存在就建立
                if not os.path.exists(fpath):
                    os.makedirs(fpath)
                # 寫File
                with open ( fnam, mode = "w", encoding = "UTF-8") as web_html:
                    web_html.write(self.obj.prettify())
            except:
                wlog.exception("message")
                # wlog.info(f"Create HTML File: {fpath} Fail!!")

    # 將資料產生成檔案
    def generateDataToExcelFile(self, fun: str, period: list)-> None:
        header = []
        # 判斷是否要產生檔案
        genFile = FileProcess().getConfigValue(key = "gen_xlsx")

        if not genFile:
            wlog.info(f"Config Setting: Write Excel is False!!")
            return
        # 檢查進來的資料
        if self.data == []:
            wlog.info(f"No Data Input to Write Excel!!")
            return

        # 每季財報
        if fun.upper() == "F":
            fpath = f"{self.xlsx_path}/Financial_{period[0]}_Q{period[1]}.xlsx"
            header = ["公司", "日期", "PSMC平均匯率", "WaferQty_8", "WaferQty_12"]
            # 處理三個Table的Header Text (i = 0~2)
            for i in range(3):
                iPer = period.copy()
                iPer.append(None)
                GL = self.getConfigValue(key = f"glst{i}")
                tbobj = Web(self.obj).getTBobject(inLst = iPer, findTB = str(i))
                for glkey in GL:
                    try:
                        text = tbobj.find("td", text = glkey).find_parent("tr").find("span", class_ ="zh").text.strip().replace("（","(").replace("）",")")
                    except:
                        text = glkey
                    header.append(text)
            
        
        # 每月營收
        if fun.upper() == "I":
            fpath = f"{self.xlsx_path}/Revenue_{period[0]}_{period[1]}.xlsx"
            header = ["日期", "市場別"]
            for txt in self.obj.select("table > tr:nth-child(2) > th"):
                header.append(re.sub('<br\s*?>', ' ', txt.text))
            # 抓備註
            header.append(self.obj.select("table > tr:nth-child(1) > th:nth-child(4)")[0].text) 
            # BU
            header.append("BU")
            # 最後一個欄位是為了寫資料庫加的
            self.data = [i[:-1] for i in self.data]
        # 產生File
        try:
            # 轉換成DataFrame
            xlsxDF = pd.DataFrame(self.data, columns = header)
            xlsxDF.to_excel(fpath, index = False)
            wlog.info(f"Create Excel File: {fpath} Success!!")
        except:
            wlog.exception("message")

class Calcuate:
    def __init__(self) -> None:
        pass

    # 計算年月值(網頁參數)baseday=>基準日, step=>-1往前一個單位, qm=>月或季, ce=>True西元/False民國
    def calYearQuarterMonthValue(baseday: date = date.today(), step: int = 0, qm: str = "m", ce: bool = True)-> list:
        
        # 月的處理
        if qm.upper() == "M":
            caldate = baseday + relativedelta(months = step)
            if ce:
                outvalue = [str(caldate.year), str(caldate.month)]
            else:
                outvalue = [str(caldate.year - 1911), str(caldate.month)]
        # 季的處理
        if qm.upper() == "Q":
            val = pd.Timestamp(baseday).quarter + step
            
            # 值為0表示為去年的最後一季
            if val <= 0:
                # base year - (商 + 1)
                result_Y = baseday.year - int(abs(val) / 4 + 1)
                # 4 - 餘數
                result_Q = 4 - ( abs(val) % 4 )
            else:
                # base year + 商
                result_Y = baseday.year + int((val - 1) / 4)
                result_Q = ( val % 4 )
                if result_Q == 0:
                    result_Q = 4
            # 處理西元年/民國年
            if ce:
                outvalue = [str(result_Y), str(result_Q)]
            else:
                outvalue = [str(result_Y - 1911), str(result_Q)]

        return outvalue

    # 計算指定 年季/年月 的第一天(period=>[Y, Q]/[Y, M] qm=>月或季 ce=>True西元/False民國)
    def calFirstDate(period: list, qm: str, ce: bool = True)-> date:
        # 民國/西元轉換
        if ce:
            myyear = int(period[0])
        else:
            myyear = int(period[0]) + 1911
        # 季換月
        if qm.upper() == "Q":
            mymonth = int(period[1]) * 3 - 2
        # 月換月
        if qm.upper() == "M":
            mymonth = int(period[1])

        return date(myyear, mymonth, 1)

class DB:
    def __init__(self, idata:any = None) -> None:    
        self.dbserver_1 = "8AEISS01"
        self.dbserver_2 = "RAOICD01"
        self.dbBIDC = "BIDC"
        self.dbSAP = "SAP"
        self.user_1 = "sap_user"
        self.user_2 = "owner_sap"
        self.pwd_1 = dectry("215_203_225_72_88_148_169_83_98_")
        self.pwd_2 = dectry("211_211_212_72_168_196_229_85_94_217_153_")
        self.mssqlcon = "mssql+pyodbc"
        self.dbdrive = "SQL+Server+Native+Client+11.0"
        self.inputdata = idata

    # 取得公司內部使用的 月/季 平均匯率
    def getAVGRateFromDB(self, period: list, qm: str)-> float:
        if qm.upper() == "Q":
            # 季度*3=當月最大月份
            MaxMon = int(period[1]) * 3
            MinMon = MaxMon - 2
            SQLstatement = f"SELECT UKURS FROM SAP.dbo.sapExchangeRateByMonth WHERE GJAHR = {period[0]} AND MONAT >= {MinMon} AND MONAT <= {MaxMon}"
        
        if qm.upper() == "M":
            SQLstatement = f"SELECT UKURS FROM SAP.dbo.sapExchangeRateByMonth WHERE GJAHR = {period[0]} AND MONAT = {period[1]}"
        
        conn = pymssql.connect( server = self.dbserver_1, user = self.user_1, password = self.pwd_1, database = self.dbBIDC)
        cursor = conn.cursor(as_dict = False)
        try:
            cursor.execute(SQLstatement)
            RateList = [float(v[0]) for v in cursor.fetchall()]
            conn.close()
            oVal = round(sum(RateList) / len(RateList), 2)
        except:
            wlog.exception("message")
            oVal = 0
        return oVal

    # 取得季 Ship Wafer Qty(PSMC抓不到就找8AEISS01的值來計算)->dict = {"StockID": [w8_qty, w12_qty]}
    def getWaferQtyByPeriod(self, fdate: date )-> dict:
        oDict = {}
        oDF = pd.DataFrame()
        engine8AEISS01 = sqlalchemy.create_engine(f"{self.mssqlcon}://{self.user_1}:{self.pwd_1}@{self.dbserver_1}/{self.dbBIDC}?driver={self.dbdrive}")
        engineRAOICD01 = sqlalchemy.create_engine(f"{self.mssqlcon}://{self.user_2}:{self.pwd_2}@{self.dbserver_2}/{self.dbBIDC}?driver={self.dbdrive}")
        oldSQLstatement = f"SELECT StockID, WaferQty_8, WaferQty_12 FROM BIDC.dbo.mopsFinancialByCompany WHERE YQ_Date = '{str(fdate)}'"
        newSQLstatement8 = f"SELECT '6770' as StockID, SUM(IIF( FKART NOT IN ('F2', 'L2'), FKIMG * -1, FKIMG)) as WaferQty_8 FROM SAP.dbo.sapRevenue WHERE DATEADD(qq, DATEDIFF(qq, 0, FKDAT) , 0) = '{str(fdate)}'"
        newSQLstatement12 = f"SELECT SUM(Qty) as WaferQty_12 FROM ( SELECT SUM(IIF( FKART NOT IN ('F2', 'L2'), FKIMG * -1, FKIMG)) as Qty FROM F12SAP.dbo.sapRevenue WHERE DATEADD(qq, DATEDIFF(qq, 0, FKDAT) , 0) = '{str(fdate)}' UNION SELECT SUM(IIF( FKART NOT IN ('F2', 'ZL2', 'Z001'), WQTY * -1, WQTY)) as Qty FROM M12SAP.dbo.sapRevenue WHERE DATEADD(qq, DATEDIFF(qq, 0, FKDAT) , 0) = '{str(fdate)}' ) as a"
        try:
            # mssqlcon = pymssql.connect(server = self.dbserver_2, user = self.user_2, password = self.pwd_2, database = self.dbBIDC, charset = "utf8")
            # 先從Financial抓資料
            oDF = pd.read_sql(sql = oldSQLstatement, con = engineRAOICD01).astype({"StockID": str, "WaferQty_8": int, "WaferQty_12": int})
            # 沒有取到資料就去計算PSMC的數量,同時其他競業就補0
            if oDF.empty:
                StkLst = FileProcess().getConfigValue(key = "stocklist")
                # mssqlcon = pymssql.connect(server = self.dbserver_1, user = self.user_1, password = self.pwd_1, database = self.dbBIDC, charset = "utf8")
                oDF  = pd.concat([pd.read_sql(newSQLstatement8, engine8AEISS01), pd.read_sql(newSQLstatement12, engine8AEISS01)], axis = 1)
                for id in StkLst:
                    if id == "6770":
                        break
                    oDF = pd.concat([oDF, pd.DataFrame([[id, 0, 0]], columns = ["StockID", "WaferQty_8", "WaferQty_12"])], axis = 0 )
            # DataFrame to Dict
            oDict = oDF.set_index("StockID").T.to_dict("list")
        except:
            wlog.exception("message")
        return oDict

    # 取得月 LSPF Revenue
    def getLSPFRevenueByPeriod(self, fdate: date)-> int:
        engine8AEISS01 = sqlalchemy.create_engine(f"{self.mssqlcon}://{self.user_1}:{self.pwd_1}@{self.dbserver_1}/{self.dbBIDC}?driver={self.dbdrive}")
        SQLstatement8 = f"SELECT SUM(IIF( FKART NOT IN ('F2', 'L2'), LNETW * -1, LNETW)) as Revenue_8 FROM SAP.dbo.sapRevenue WHERE DATEADD(mm, DATEDIFF(mm, 0, FKDAT) , 0) = '{str(fdate)}'"
        SQLstatement12 = f"SELECT SUM(IIF( FKART NOT IN ('F2', 'L2'), LNETW * -1, LNETW)) as Revenue_12 FROM F12SAP.dbo.sapRevenue WHERE DATEADD(mm, DATEDIFF(mm, 0, FKDAT) , 0) = '{str(fdate)}'"
        try:
            oDF  = pd.concat([pd.read_sql(SQLstatement8, engine8AEISS01), pd.read_sql(SQLstatement12, engine8AEISS01)], axis = 0)
            oVal = int(round(oDF.Revenue_8.values[0] + oDF.Revenue_12.values[0], -3)/1000)
        except:
            oVal = 0
            wlog.exception("message")
        return oVal

    # 更新Tbale
    def updateDataToTable(self, fdate: date, tbname: str)-> None:
        # 檢查設定檔是否需要更新DB Table
        DBupdate = FileProcess().getConfigValue(key = "update_db")
        if not DBupdate:
            wlog.info(f"Config Setting: UpDate DB is False!!")
            return
        # 檢查進來的資料
        if self.inputdata == None or self.inputdata == []:
            wlog.info(f"No Data Input to UpDate DB!!")
            return
        
        # 連線資訊
        conn = pymssql.connect( server = self.dbserver_2, user = self.user_2, password = self.pwd_2, database = self.dbBIDC)
        cursor = conn.cursor(as_dict = False)
        # 針對不同Table做處理
        if tbname == "BIDC.dbo.mopsFinancialByCompany":
            delSQL = f"DELETE FROM {tbname} WHERE YQ_Date ='{str(fdate)}'"
            # 公司, 日期, PSMC平均匯率, 8"數量, 12"數量, 總資產, 總負債, 流通在外張數, 營業收入, 營業毛利, 營業費用, 營業費用(其他), 營業利益, 營業外收支, 稅後純益(損), 所得稅費用, 稅後淨利, EPS, RD費用, 稅前淨利, 利息費用, 折舊費用, 攤銷費用
            insertSQL = "INSERT INTO BIDC.dbo.mopsFinancialByCompany (StockID, YQ_Date, PSMC_ExRate, WaferQty_8, WaferQty_12, Assets, Liabilities, OrdinaryShare, Oper_Revenue, GP_Oper, Oper_Expenses, NetOtherIncome, NetOperIncome, nonOperIncome, PF_AttrOwners, Tax_Expense, Profit, EPS, RD_Expense, PF_BeforeTax, Inter_Expense, DP_Expense, Amor_Expense) VALUES (%s, %s, %s, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %s, %d, %d, %d, %d, %d)"

        if tbname == "BIDC.dbo.mopsFinancialByCompany":
            delSQL = f"DELETE FROM {tbname} WHERE YearMonth ='{str(fdate)}'"
            # YearMonth, BU, StockID, Revenue, Remark
            insertSQL = "INSERT INTO BIDC.dbo.mopsRevenueByCompany (YearMonth, BU, StockID, Revenue, Remark) VALUES (%s, %s, %s, %d, %s)"
            # 取出需要的欄位
            # 日期/市場別/公司代號/公司名稱/當月營收/上月營收/去年當月營收/上月比較增減(%)/去年同月增減(%)/當月累計營收/去年累計營收/前期比較增減(%)/備註/BU/Revenue
            self.inputdata = [[i[0], i[-2], i[2], i[-1], i[-3]] for i in self.inputdata]
            
        
        if tbname == "BIDC.dbo.mopsStockCompanyInfo":
            engineRAOICD01 = sqlalchemy.create_engine(f"{self.mssqlcon}://{self.user_2}:{self.pwd_2}@{self.dbserver_2}/{self.dbBIDC}?driver={self.dbdrive}")
            quarySQL = f"SELECT StockID, StockName, Market, Industry, EnShowName FROM {tbname}"
            companyDF = pd.read_sql(sql = quarySQL, con = engineRAOICD01)
            pass
        
        # Nested List Data To Tuples
        insertData = [tuple(lst) for lst in self.inputdata]
        # Del Exist Data & Insert New Data
        try:
            cursor.execute(delSQL)
            conn.commit()
            cursor.executemany(insertSQL, insertData)
            conn.commit()
            wlog.info(f"Update {tbname} Success!!")
        except:
            wlog.exception("message")
        
        conn.close()





class Web:
    def __init__(self, obj: bs = None) -> None:
        self.pxy = {"http":"http://172.16.5.177:80", "https":"http://172.16.5.177:80"}
        self.head = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
        self.encoding = "big5"
        self.htmlfpath = "./data/html_file"
        self.stkinfo = []
        self.incomeGL = FileProcess().getConfigValue(key = "glst1")
        self.cashflowGL = FileProcess().getConfigValue(key = "glst2")
        self.stkLst = FileProcess().getConfigValue(key = "stocklist")

        # 由執行所在位置決定檔案路徑
        if os.path.basename(os.getcwd()) == "util":
            self.htmlfpath = "../data/html_file"
        # bs
        if obj:
            self.obj = obj

    # 取得BeautifulSoup的Object(inLst=>[年, 季/月, 股票代碼/產業類別], fun=>財報(F)/營收(I))    
    def getBSobject(self, inLst: list, fun: str)-> bs:
        rootlxml = None
        # 判斷是否要產生檔案
        genFile = FileProcess().getConfigValue(key = "gen_html")
        # 每季財報
        if fun.upper() == "F":
            url = f"https://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID={inLst[2]}&SYEAR={str(inLst[0])}&SSEASON={str(inLst[1])}&REPORT_ID=C"
            fname = f"{self.htmlfpath}/FinancialWeb_{inLst[2]}_{str(inLst[0])}Q{str(inLst[1])}.html"
            checkstr = "檔案不存在"

        # 每月營收
        if fun.upper() == "I":
            yearmonth = f"{str(inLst[0])}_{str(inLst[1])}"
            url = f"https://mops.twse.com.tw/nas/t21/{inLst[2]}/t21sc03_{yearmonth}_0.html"
            fname = f"{self.htmlfpath}/Income_{inLst[2]}_{yearmonth}.html"
            checkstr = "查無資料"

        # 處理網址(如果可以不用proxy就不要用)
        try:
            urlwithhead = req.get(url, headers = self.head)
        except:
            urlwithhead = req.get(url, headers = self.head, proxies = self.pxy)
        urlwithhead.encoding = self.encoding

        # 檢查網址是否存在, 產生要output的BeautifulSoup物件
        if urlwithhead.status_code == 200:
            rootlxml = bs(urlwithhead.text, "lxml")
            # 判斷是否需要寫檔案
            if genFile:
                FileProcess(rootlxml).generateBSobjectToFile(fpath = self.htmlfpath, fnam = fname)
        
        # 判斷網站內是否有"無資料"的字串,None表示沒有查到該字串
        if rootlxml.find(text = re.compile(checkstr)) != None:
            rootlxml = None

        return rootlxml

    # 由BeautifulSoup的Object中取得特定的Table(inLst=>[年, 季/月, 股票代碼/產業類別], findTB=>數字(第n個table),文字(找關鍵字),List(找關鍵字))
    def getTBobject(self, inLst: list, findTB: any)-> bs:
        tbObj = None
        # 判斷是否要產生檔案
        genFile = FileProcess().getConfigValue(key = "gen_html")
        # 如果StockID是空值,就不要產生檔案
        if inLst[2] == None:
            genFile = False

       
        # 檢查進來要抓的指令的Type,基本上數字抓"季財報",關鍵字抓"月營收"
        if isinstance(findTB, int):
            try:
                tbObj = self.obj.find_all("table")[findTB]
                fname = self.htmlfpath + "/tb_" + tbObj.find_all("th")[0].find("span", class_ ="en").text.strip().replace(" ","") + f"_{inLst[2]}_{str(inLst[0])}Q{str(inLst[1])}.html"
            except:
                wlog.exception("message")

        if isinstance(findTB, str):
            try:
                tbObj = self.obj.find("th", text = re.compile(".*" + findTB)).find_parent("table")
                fname = f"{self.htmlfpath}/tb_{findTB}_{inLst[2]}_{inLst[0]}_{inLst[1]}.html"
            except:
                wlog.exception("message")

        if isinstance(findTB, list):
            for industy in findTB:
                try:                        
                    tbObj = self.obj.find("th", text = re.compile(".*" + industy)).find_parent("table")
                    fname = f"{self.htmlfpath}/tb_{inLst[2]}_{inLst[0]}_{inLst[1]}_{industy}.html"
                    # 有抓到值就離開了..不然後面會再更新掉tbObj為空的
                    break
                except:
                    wlog.exception("message")
                    continue
            
        
        if genFile:
            FileProcess(tbObj).generateBSobjectToFile(fpath = self.htmlfpath, fnam = fname)

        return tbObj
        
    # 由Table Object取得值
    def getItemValue(self, key: any, fun: str)-> any:
        # 每季財報
        if fun.upper() == "F":
            try:
                outVal = self.obj.find("td", text = str(key)).find_parent("tr").find_all("td")[2].text.strip().replace(",", "").replace("(", "-").replace(")", "")
            except:
                outVal = 0

        # 每月營收
        if fun.upper() == "I":
            try:
                # 文字的欄位
                if int(key) in (1, 2, 11):
                    outVal = str(self.obj.select(f"td:nth-child({key})")[0].text.strip().replace("-", ""))
                # 有小數的欄位
                elif int(key) in (6, 7, 10):
                    outVal = float(self.obj.select(f"td:nth-child({key})")[0].text.strip())
                # 數值欄位(網頁上以千元為單位)
                else:
                    outVal = int(self.obj.select(f"td:nth-child({key})")[0].text.strip().replace(",", ""))
            except:
                outVal = 0

        return outVal

    # 取得當年度Income的累加
    def getCurrentYearIncomeAccumulate(self, period: list)-> dict:
        iData = []
        for stkID in self.stkLst:
            objLst = []
            dataLst = []
            # 組出資料的List([0] = StockID)
            dataLst.append(stkID)
            for i in range(len(self.incomeGL)):
                dataLst.append(0)
            iData.append(dataLst)
            # 前三季就換下一筆
            if int(period[1]) != 4:
                continue

            # 取得該Stock當年Q1~Q3的資料
            for Qutr in range(1, 4):
                dataLst = []
                # 組一個input的List
                objLst = [period[0], str(Qutr), stkID]
                bsObj = Web().getBSobject(inLst = objLst, fun = "F")
                # 組出資料的List
                dataLst.append(stkID)
                if bsObj == None:
                    for i in range(len(self.incomeGL)):
                        dataLst.append(0)
                else:
                    # 如果沒有要產生檔案objLst進去沒有用
                    tbObj = Web(bsObj).getTBobject(inLst = objLst, findTB = 1)
                    for glkey in self.incomeGL:
                        val = Web(tbObj).getItemValue(key = glkey, fun = "F")
                        dataLst.append(val)
                iData.append(dataLst)
            time.sleep(10)
        
        # 加一個StockID進原List在0的位置
        self.incomeGL.insert(0, "StockID")
        # 把各欄位的Type用Dict組出來
        typeDict = {}
        for colnam in self.incomeGL:
            if colnam == "StockID":
                tpval = str
            elif colnam == "9750":
                tpval = float
            else:
                tpval = int    
            typeDict[colnam] = tpval
        
        # Index = StockID, 其他欄位用sum
        oDict = pd.DataFrame(data = iData, columns = self.incomeGL).astype(typeDict).groupby(by = ["StockID"]).sum()
        # {<StockID1>: {<GL1>: <Value1>, <GL2>: <Value1>, ...}, <StockID2>: {<GL1>: <Value1>, <GL2>: <Value1>, ...}...}
        oDict = oDict.to_dict(orient = "index")
        return oDict

    # 取得前一季的CashFlow
    def getPreviousQuarterCashFlow(self, period: list)-> dict:
        iData = []
        for stkID in self.stkLst:
            # 1.先給一組都是0的資料
            dataLst = []
            ## 組出資料的List([0] = StockID)
            dataLst.append(stkID)
            for i in range(len(self.cashflowGL)):
                dataLst.append(0)
            iData.append(dataLst)

            # 2.取出前一個季的資料loop 1 to 2(有些公司只有年/半年報)
            for i in range(1, 3):
                dataLst = []
                # 如果前一季是0就離開這個loop
                if int(period[1]) - i == 0:
                    break
                # 組一個input的List(前一個季)
                objLst = [period[0], str(int(period[1]) - i), stkID]
                bsObj = Web().getBSobject(inLst = objLst, fun = "F")
                if bsObj == None:
                    continue
                else:
                    # 如果沒有要產生檔案objLst進去沒有用
                    tbObj = Web(bsObj).getTBobject(inLst = objLst, findTB = 2)
                    dataLst.append(stkID)
                    for glkey in self.cashflowGL:
                        val = Web(tbObj).getItemValue(key = glkey, fun = "F")
                        dataLst.append(val)
                    iData.append(dataLst)
                    break
        # 加一個StockID進原List在0的位置
        self.cashflowGL.insert(0, "StockID")
        # 把各欄位的Type用Dict組出來
        typeDict = {}
        for colnam in self.cashflowGL:
            if colnam == "StockID":
                tpval = str
            else:
                tpval = int    
            typeDict[colnam] = tpval        
        # Index = StockID, 其他欄位用sum
        oDict = pd.DataFrame(data = iData, columns = self.cashflowGL).astype(typeDict).groupby(by = ["StockID"]).sum()
        # {<StockID1>: {<GL1>: <Value1>, <GL2>: <Value1>, ...}, <StockID2>: {<GL1>: <Value1>, <GL2>: <Value1>, ...}...}
        oDict = oDict.to_dict(orient = "index")
        return oDict    





# %%
if __name__ == "__main__":
    # print(FileProcess().getConfigValue(key = "stocklist"))
    # a = Calcuate().calYearQuarterMonthValue()
    lstA = [2021, 4]
    lstA = [2021, 2]
    # lstA.append("2330")
    print(DB().getAVGRateFromDB([2021, 2], "m"))
    # a = Web().getBSobject(inLst = lstA, fun = "f")
    # aTB = Web(obj = a).getTBobject(inLst = lstA, findTB = 1)
    
    
    lstB = [111, 1]
    # lstB.append("otc")
    # lst1 = ["半導體", "電子工業"]
    # b = Web().getBSobject(inLst = lstB, fun = "i")    
    # bTB1 = Web(obj = b).getTBobject(inLst = lstB, findTB = lst1)
    # bTB2 = Web(obj = b).getTBobject(inLst = lstB, findTB = "半導體")

    # print(Calcuate.calFirstDate(period = lstA, qm = "q"))
    # print(Calcuate.calFirstDate(period = lstB, qm = "m", ce = False))



    YQLst = Calcuate.calYearQuarterMonthValue(baseday = date.today(), step = -1, qm = "Q", ce = True)
    # # 取得這一季的第一天
    FirstDate = Calcuate.calFirstDate(period = YQLst, qm = "Q")   
    wQtyDF1 = DB().getWaferQtyByPeriod(fdate = FirstDate)
    # a = Web().getCurrentYearIncomeAccumulate(lstA)
    # b = Web().getPreviousQuarterCashFlow(lstA)
    DB().updateDataToTable(fdate = FirstDate, tbname = "BIDC.dbo.mopsFinancialByCompany")
# %%
