# %%
import json
import pandas as pd
import pymssql
import requests
import urllib3
import os
from datetime import date
# %%
# 當requests.get時用verify = False會出現一些WARNING,可加這段讓WARNING不出現
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
# 由執行所在位置決定import的方式
if os.path.basename(os.getcwd()) == "util":
    from EncryptionDecrypt import dectry
    from Python.MOPS.Util.Logger import create_logger
    logpath = "../log"
else:
    from util.EncryptionDecrypt import dectry
    from util.Logger import create_logger
    logpath = "./log"


wlog = create_logger(logpath)

class FileProcess:
    def __init__(self) -> None:
        self.cfg_fpath = "./config/config.json"
        self.xlsx_path = "./data"

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

    # 產生Excel檔
    def genDataToExcel(self, fn: str, fname: str, df: pd.DataFrame)-> None:
        # 判斷是否要產生檔案
        gen = FileProcess().getConfigValue(key = "gen_xlsx")
        # False就寫Log離開
        if not gen:
            wlog.info(f"Config Setting: no need to Create Excel!!")
            return
        if fn.upper() == "R":
            fpath = f"{self.xlsx_path}/Revenue_{fname}.xlsx"
        if fn.upper() == "C":
            # fpath = f"{self.xlsx_path}/Company_{date.today().strftime("%Y%m%d")}.xlsx"
            fpath = f"{self.xlsx_path}/Company.xlsx"
        if fn.upper() == "F":
            fpath = f"{self.xlsx_path}/Finance_{fname}.xlsx"
        df.to_excel(fpath, index=False)
        wlog.info(f"Excel檔案己產生: {fpath}")
        return

class Calcuate:
    def __init__(self) -> None:
        pass
    # 計算指定 年季/年月 的第一天(yyymm=>民國年月 qm=>月或季)
    def getFirstDate(yyymm: str, qm: str)-> date:
        year, month = int(yyymm) // 100 + 1911, int(yyymm) % 100
        # 季換月
        if qm.upper() == "Q":
            month = month * 3 - 2
        return date(year, month, 1)

class DB:
    def __init__(self) -> None:    
        self.dbserver = "8AEISS01"
        self.dbBIDC = "BIDC"
        # self.dbSAP = "SAP"
        self.dbreader = FileProcess().getConfigValue(key = "db_r")
        self.dbwriter = FileProcess().getConfigValue(key = "db_w")
        self.readpwd = dectry("215_203_225_72_88_148_169_83_98_")
        self.writepwd = dectry("215_203_225_101_117_149_165_84_99_160_")
        # self.pwd_1 = dectry("215_203_225_101_117_149_165_84_99_160_")
        # self.pwd_2 = dectry("211_211_212_72_168_196_229_85_94_217_153_")
        # self.mssqlcon = "mssql+pyodbc"
        # self.dbdrive = "SQL+Server+Native+Client+11.0"

    # 取得目前Table最新的日期<yyymm>或DataFrame
    def getTableLastPeriodData(self, tbname: str)-> any:
        if tbname == "mopsRevenueByCompany":
            SQLstatement = "SELECT CONCAT(Year(MAX(YearMonth)) - 1911, FORMAT(MAX(YearMonth),'MM')) FROM BIDC.dbo.mopsRevenueByCompany"
        if tbname == "mopsFinancialByCompany":
            SQLstatement = "SELECT Year(YQ_Date) - 1911 as 年度, CEILING(MONTH(YQ_Date)/3.0) as 季別, StockID as 公司代號 FROM BIDC.dbo.mopsFinancialByCompany WHERE YQ_Date = ( SELECT MAX(YQ_Date) FROM BIDC.dbo.mopsFinancialByCompany )"
        conn = pymssql.connect( server = self.dbserver, user = self.dbreader, password = self.readpwd, database = self.dbBIDC)
        cursor = conn.cursor(as_dict = False)
        try:
            cursor.execute(SQLstatement)

            # 用fetchall會長成[(val,val,...)]
            if tbname == "mopsRevenueByCompany":
                oVal = cursor.fetchone()[0]
            if tbname == "mopsFinancialByCompany":
                oVal = cursor.fetchall()
                oVal = pd.DataFrame(oVal)
                oVal.columns = [desc[0] for desc in cursor.description]
                oVal["年度"] = oVal["年度"].astype(str)
                oVal["季別"] = oVal["季別"].astype(str)
            conn.close()
            return oVal
        except:
            wlog.exception("message")

    # 取得L BU的Revenue資料
    def getLRevenueByPeriod(self, yyymm: str)-> int:
        # 把進來的民國年月轉成二個變數 西元年,月 註:zfill用於將月份補零
        year, month = str(int(yyymm) // 100 + 1911), str(int(yyymm) % 100).zfill(2)
        SQLstatement = f"""SELECT 
                                (
                                SELECT SUM(IIF( FKART NOT IN ('F2', 'L2', 'Z001'), LNETW * -1, LNETW)) 
                                    FROM	SAP.dbo.sapRevenue
                                    WHERE	SUBSTRING(FKDAT, 1, 6) = {year+month}
                                ) +
                                (
                                SELECT SUM(IIF( FKART NOT IN ('F2', 'L2', 'Z001'), LNETW * -1, LNETW)) 
                                    FROM	F12SAP.dbo.sapRevenue
                                    WHERE	SUBSTRING(FKDAT, 1, 6) = {year+month}
                                ) +
                                (
                                SELECT SUM(TOTAL) 
                                    FROM	SAP.dbo.sapGrossProfit
                                    WHERE	GJAHR = {year}
                                    AND     MONAT = {month}
                                    AND		PRODCATG = 'ADJUSTS'
                                ) +
                                (
                                    SELECT SUM(TOTAL) 
                                    FROM	F12SAP.dbo.sapGrossProfit
                                    WHERE	GJAHR = {year}
                                    AND     MONAT = {month}
                                    AND		PRODCATG = 'ADJUSTS'
                                )"""
        conn = pymssql.connect( server = self.dbserver, user = self.dbreader, password = self.readpwd)
        cursor = conn.cursor(as_dict = False)
        try:
            cursor.execute(SQLstatement)
            # 用fetchall會長成[(val,val,...)]
            oVal = int(round(cursor.fetchone()[0],-3))
            conn.close()
            return oVal
        except:
            wlog.exception("message")

    # 取得指定Table所有的資料
    def getTableData(self, tbname: str)-> pd.DataFrame | None:
        if tbname == "mopsFinancialByCompany":
            year = str(date.today().year - 1)
            SQLstatement = f""" SELECT	Year(YQ_Date) - 1911 as Year,
		                                StockID,
                                        SUM(Oper_Revenue) as Oper_Revenue,
                                        SUM(GP_Oper) as GP_Oper,
                                        SUM(Oper_Expenses) as Oper_Expenses,
                                        SUM(NetOtherIncome) as NetOtherIncome,
                                        SUM(NetOperIncome) as NetOperIncome,
                                        SUM(nonOperIncome) as nonOperIncome,
                                        SUM(PF_BeforeTax) as PF_BeforeTax,
                                        SUM(Profit) as Profit,
                                        SUM(PF_AttrOwners) as PF_AttrOwners,
                                        SUM(Inter_Expense) as xInter_Expense,
                                        SUM(Tax_Expense) as Tax_Expense,
                                        SUM(DP_Expense) as xDP_Expense,
                                        SUM(Amor_Expense) as xAmor_Expense,
                                        SUM(EPS) as EPS,
                                        SUM(RD_Expense) as xRD_Expense
                                FROM BIDC.dbo.mopsFinancialByCompany
                                WHERE Year(YQ_Date) >= {year}
                                GROUP BY Year(YQ_Date), StockID"""
        else:
            SQLstatement = f"SELECT * FROM {tbname}"
        conn = pymssql.connect( server = self.dbserver, user = self.dbreader, password = self.readpwd)
        cursor = conn.cursor(as_dict = False)
        try:
            cursor.execute(SQLstatement)
            # 用fetchall會長成[(val,val,...)]
            rows = cursor.fetchall()
            conn.close()
            df = pd.DataFrame(rows)
            df.columns = [desc[0] for desc in cursor.description]
            return df
        except:
            wlog.exception("message")
        return
    
    # 計算平均匯率(先做季平均)
    def getPSMCAvgRate(self, fdate: date )-> float:
        SQLstatement = f"SELECT ROUND(AVG(UKURS),2) FROM SAP.dbo.sapExchangeRateByMonth WHERE GJAHR = {fdate.year} and monat between {fdate.month} and {fdate.month + 2}"
        conn = pymssql.connect( server = self.dbserver, user = self.dbreader, password = self.readpwd, database = self.dbBIDC)
        cursor = conn.cursor(as_dict = False)
        try:
            cursor.execute(SQLstatement)
            oVal = float(cursor.fetchone()[0])
            conn.close()
            return oVal
        except:
            wlog.exception("message")

    # 取得Ship Wafer Qty
    def getPSMCWaferQty(self, fdate: date )-> pd.DataFrame | None:
        SQLstatement = f"""SELECT (
	                            SELECT SUM(IIF( FKART NOT IN ('F2', 'L2'), FKIMG * -1, FKIMG))
                                    FROM SAP.dbo.sapRevenue
                                    WHERE DATEADD(qq, DATEDIFF(qq, 0, FKDAT) , 0) = '{str(fdate)}'
                                ) as WaferQty_8,
		                        (
                                SELECT SUM(Qty) 
                                    FROM (
                                        SELECT SUM(IIF( FKART NOT IN ('F2', 'L2'), FKIMG * -1, FKIMG)) as Qty
                                            FROM F12SAP.dbo.sapRevenue 
                                            WHERE DATEADD(qq, DATEDIFF(qq, 0, FKDAT) , 0) = '{str(fdate)}' 
                                        UNION
                                        SELECT SUM(IIF( FKART NOT IN ('F2', 'ZL2', 'Z001'), WQTY * -1, WQTY)) as Qty
                                            FROM M12SAP.dbo.sapRevenue
                                            WHERE DATEADD(qq, DATEDIFF(qq, 0, FKDAT) , 0) = '{str(fdate)}'
                                        ) as a
		                        ) as WaferQty_12"""
        conn = pymssql.connect( server = self.dbserver, user = self.dbreader, password = self.readpwd)
        cursor = conn.cursor(as_dict = False)
        try:
            cursor.execute(SQLstatement)
            # 用fetchall會長成[(val,val,...)]
            rows = cursor.fetchall()
            conn.close()
            df = pd.DataFrame(rows)
            df.columns = [desc[0] for desc in cursor.description]
            return df
        except:
            wlog.exception("message")
            return
        
    # 把資料寫入Table
    def updateDataToTable(self, df: pd.DataFrame, tbname: str, fdate: date)-> None:
        # 檢查config內的設定
        upfg = FileProcess().getConfigValue(key = "update_db")
        if not upfg:
            wlog.info(f"Config Setting: UpDate DB is False!!") 
            return
        # 進來的DataFrame是空的就離開
        if df.empty:
            return
        # 每月營收資料
        if tbname == "mopsRevenueByCompany":
            dSQLstat = f"DELETE FROM BIDC.dbo.{tbname} WHERE YearMonth ='{fdate}'"
            # YearMonth, BU, StockID, Revenue, Remark
            iSQLstat = "INSERT INTO BIDC.dbo.mopsRevenueByCompany (StockID, Revenue, Remark, BU, YearMonth) VALUES (%s, %d, %s, %s, %s)"
        # 新的公司
        if tbname == "mopsStockCompanyInfo":
            iSQLstat = "INSERT INTO BIDC.dbo.mopsStockCompanyInfo (StockID, StockName, Market,  Industry) VALUES (%s, %s, %s, %s)"

        # 每季財報資料
        if tbname == "mopsFinancialByCompany":
            iSQLstat = "INSERT INTO BIDC.dbo.mopsFinancialByCompany (YQ_Date, StockID, Assets, Liabilities, Oper_Revenue, GP_Oper, Oper_Expenses, NetOtherIncome, NetOperIncome, nonOperIncome, PF_BeforeTax, Profit, PF_AttrOwners, Inter_Expense, Tax_Expense, DP_Expense, Amor_Expense, EPS, RD_Expense, OrdinaryShare, WaferQty_12, WaferQty_8, PSMC_ExRate) VALUES (%s, %s, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %s, %d, %d, %d, %d, %s)"

        # DF資料轉List
        lst_data = df.values.tolist()
        # Nested List Data To Tuples
        tpl_data = [tuple(lst) for lst in lst_data]

        conn = pymssql.connect( server = self.dbserver, user = self.dbwriter, password = self.writepwd, database = self.dbBIDC)
        cursor = conn.cursor(as_dict = False)

        try:
            if tbname == "mopsRevenueByCompany":
                cursor.execute(dSQLstat)
                conn.commit()
                wlog.info(f"Delete {tbname} Record By Condition Success!!")
            cursor.executemany(iSQLstat, tpl_data)
            conn.commit()
            wlog.info(f"Update {tbname} Success!!")
        except:
            wlog.exception("message")

        conn.close()

class Web:
    def __init__(self) -> None:
        pass

    def fetchDataFromAPI(url: str, source_name: str)-> any:
        try:
            response = requests.get(url, verify = False)
            response.raise_for_status()  # 如果請求返回錯誤狀態碼，拋出異常
            data = response.json()
            wlog.info(f"成功從 {source_name} 獲取數據: {len(data)} 筆記錄")
            return pd.DataFrame(data)
        except requests.exceptions.RequestException as e:
            wlog.error(f"從 {source_name} 獲取數據時出錯: {e}")
            return []
# %%
if __name__ == "__main__":

    df = DB().getTableData(tbname = "mopsFinancialByCompany")
    # print(FileProcess().getConfigValue(key = "stocklist"))
    # a = Calcuate().calYearQuarterMonthValue()
    # lstA = [2021, 4]
    # lstA = [2021, 2]
    # lstA.append("2330")
    # ym = DB().getTableLastPeriod(tabname = "mopsRevenueByCompany")
    # print(DB().getLRevenueByPeriod(yyymm = ym))
    
    # print(DB().getTableLastPeriod(tabname = "mopsFinancialByCompany"))

    # a = Web().getBSobject(inLst = lstA, fun = "f")
    # aTB = Web(obj = a).getTBobject(inLst = lstA, findTB = 1)
    
    
    # lstB = [111, 1]
    # lstB.append("otc")
    # lst1 = ["半導體", "電子工業"]
    # b = Web().getBSobject(inLst = lstB, fun = "i")    
    # bTB1 = Web(obj = b).getTBobject(inLst = lstB, findTB = lst1)
    # bTB2 = Web(obj = b).getTBobject(inLst = lstB, findTB = "半導體")

    # print(Calcuate.calFirstDate(period = lstA, qm = "q"))
    # print(Calcuate.calFirstDate(period = lstB, qm = "m", ce = False))



    # YQLst = Calcuate.calYearQuarterMonthValue(baseday = date.today(), step = -1, qm = "Q", ce = True)
    # # 取得這一季的第一天
    # FirstDate = Calcuate.calFirstDate(period = YQLst, qm = "Q")   
    # wQtyDF1 = DB().getWaferQtyByPeriod(fdate = FirstDate)
    # a = Web().getCurrentYearIncomeAccumulate(lstA)
    # b = Web().getPreviousQuarterCashFlow(lstA)
    # DB().updateDataToTable(fdate = FirstDate, tbname = "BIDC.dbo.mopsFinancialByCompany")
# %%
