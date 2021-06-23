# %%
import os
import requests as req
from bs4 import BeautifulSoup as bs
import pandas as pd
import numpy as np
import datetime
from datequarter import DateQuarter
import pymssql
import time
import json
from util.EncryptionDecrypt import dectry

# 取得config檔中的資料
def getConfigData(file_path, datatype):
    try:
        with open(file_path, encoding = "UTF-8") as f:
            jfile = json.load(f)
        return ({True: None, False: jfile[datatype]}[jfile[datatype] == "" or jfile[datatype] == "None"])
    except:
        return None

# 取得前一個年季, Base on Today or config File
def getPerviousQuarter(cfgfile):
    y = getConfigData(cfgfile, "manual_year")
    q = getConfigData(cfgfile, "manual_quarter")

    PreviousQuarter = DateQuarter.from_date(datetime.date.today()) - 1
    if y == None:
        y = str(PreviousQuarter._year)
    else:
        y = str(y)

    if q == None:    
        q = str(PreviousQuarter._quarter)
    else:
        q = str(q)
    return y, q

# 取得季的平均Rate
def getQuarterAVGRate_mssql(Fyear, Fquarter):
    pwd_enc = "215_203_225_72_88_148_169_83_98_"
    # 季轉月區間
    max_mon = int(Fquarter) * 3
    min_mon = max_mon - 2
    try:
        with pymssql.connect( server = "8AEISS01", user = "sap_user", password = dectry(pwd_enc), database = "BIDC" ) as conn:
            with conn.cursor() as cursor:
                try:
                    cursor.execute(f"SELECT UKURS FROM SAP.dbo.sapExchangeRateByMonth WHERE GJAHR = {Fyear} AND MONAT >= {min_mon} AND MONAT <= {max_mon}")
                    # val = cursor.fetchall()
                    ratelist = [ float(r[0]) for r in cursor.fetchall() ]
                    return round(sum(ratelist) / len(ratelist), 2)
                except:
                    # logger.exception("message")
                    return 0
    except:
        return 0

# 取得片數(PSMC從實際資料取,其他取己存入的資料)
def getWaferQty_mssql(CompID, QDate, wafersize):    
    try:
        if CompID == "6770":
            pwd_enc = "215_203_225_72_88_148_169_83_98_"
            with pymssql.connect( server = "8AEISS01", user = "sap_user", password = dectry(pwd_enc) ) as conn:
                with conn.cursor() as cursor:
                    try:
                        if wafersize == 8:
                            cursor.execute(f"SELECT SUM(IIF( FKART NOT IN ('F2', 'L2'), FKIMG * -1, FKIMG)) as Qty FROM SAP.dbo.sapRevenue WHERE DATEADD(qq, DATEDIFF(qq, 0, FKDAT) , 0) = '{QDate}'")
                        if wafersize == 12:
                            cursor.execute(f"SELECT SUM(Qty) as Qty FROM ( SELECT SUM(IIF( FKART NOT IN ('F2', 'L2'), FKIMG * -1, FKIMG)) as Qty FROM F12SAP.dbo.sapRevenue WHERE DATEADD(qq, DATEDIFF(qq, 0, FKDAT) , 0) = '{QDate}' UNION SELECT SUM(IIF( FKART NOT IN ('F2', 'ZL2', 'Z001'), WQTY * -1, WQTY)) as Qty FROM M12SAP.dbo.sapRevenue WHERE DATEADD(qq, DATEDIFF(qq, 0, FKDAT) , 0) = '{QDate}' ) as a")
                        return round(cursor.fetchall()[0][0] / 1000, 0)
                    except:
                        return 0        
        else:
            pwd_enc = "211_211_212_72_168_196_229_85_94_217_153_"
            pwd = dectry(pwd_enc)
            with pymssql.connect( server = "RAOICD01", user = "owner_sap", password = pwd, database = "BIDC" ) as conn:
                with conn.cursor() as cursor:                    
                    try:
                        cursor.execute(f"SELECT WaferQty_{str(wafersize)} FROM BIDC.dbo.mopsFinancialByCompany WHERE YQ_Date = '{QDate}' AND StockID = '{CompID}'")
                        return cursor.fetchall()[0][0]
                    except:
                        return 0
    except:
        return 0

# 取BeautifulSoup物件
def getBSobj_genFile(StockID_List, genfile):
    head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
    url= f"https://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID={StockID_List[0]}&SYEAR={StockID_List[1]}&SSEASON={StockID_List[2]}&REPORT_ID=C"
    
    # 處理網址
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "big5"

    chk_nodata = bs(urlwithhead.text, "lxml").find("body").text
    if chk_nodata[0:5] == "檔案不存在":
        return None

    ## 寫網頁原始碼到檔案中(有值就要產生File)
    if genfile != None:
        wpath = getConfigData(StockID_List[3], "webpath")
        # 產生出的檔案存下來
        ## 建立目錄,不存在才建...    
        if os.path.exists(wpath) == False:
            os.makedirs(wpath)
        rootlxml = bs(urlwithhead.text, "lxml")
        with open ( f"{wpath}/FinancialWeb_{StockID_List[0]}_{StockID_List[1]}Q{StockID_List[2]}.html", mode = "w", encoding = "UTF-8") as web_html:
            web_html.write(rootlxml.prettify())
    #傳出BeautifulSoup物件
    return bs(urlwithhead.text, "lxml")

# 從BS物件中抓出特定的Table
def getTBobj_genFile(bsobj, tbID, genfile, StockID_List):
    tb_data = bsobj.find_all("table")[tbID]
    if genfile != None:
        wpath = getConfigData(StockID_List[3],"webpath")
        fname = "tb_" + tb_data.find_all("th")[0].find("span", class_ ="en").text.strip().replace(" ","")
        with open (f"{wpath}/{fname}_{StockID_List[0]}_{StockID_List[1]}Q{StockID_List[2]}.html", mode = "w", encoding = "UTF-8") as web_html:
            web_html.write(tb_data.prettify())
    return  tb_data

# 取得Header Text
def getHeadText(tbobj, GL_Account):
    try:
        text = tbobj.find("td", text = GL_Account).find_parent("tr").find("span", class_ ="zh").text.strip().replace("（","(").replace("）",")")
    except:
        text = GL_Account
    return text

# 取得Header
def getHeaderLine(bsobj, cfg):
    data_head = []
    FixList = ["公司", "日期", "PSMC平均匯率", "WaferQty_8", "WaferQty_12"]
    # 處理固定欄位
    for fixval in FixList:
        data_head.append(fixval)
    # 處理三個Table的Header Text (i = 0~2)
    for i in range(3):
        GL = getConfigData(cfg, f"glst{i}")
        tbobj = getTBobj_genFile(bsobj, i, None, [])
        for gaccount in GL:
            val = getHeadText(tbobj, gaccount)
            data_head.append(val)     
    return data_head

# 由table object及GL account取得值
def getItemVal(tbobj, GLAccount):
    try:
        val = tbobj.find("td", text = GLAccount).find_parent("tr").find_all("td")[2].text.strip().replace(",", "").replace("(", "-").replace(")", "")
    except:
        val = 0
    return val

# 取得該季的第一天
def getQuarterFirstDate(tbobj):
    show_date = tbobj.find_all("th")[3].find("span", class_ = "en").text.split("/")
    # 因為上面的月只會show 3, 6, 9, 12所以不用擔心跨年的問題
    return datetime.date(int(show_date[0]), int(show_date[1]) - 2, 1)

# 取得Income前三季的值加總(只有年/半年報的就只取第二季)
def getFirst3PeriodImcome(StockID_List):
    ID_Y_Q1st_cfg = [StockID_List[0], StockID_List[1], "1", StockID_List[3]]
    itemlist = []
    
    # 只有第4季才需把前三季的加總
    if StockID_List[2] == "4":
        # 先處理第一季
        BsObj_1st = getBSobj_genFile(ID_Y_Q1st_cfg, None)
        
        # 若沒有第一季季報,就抓半年報
        if BsObj_1st == None:
            # Q換Q2
            ID_Y_Q1st_cfg[2] = "2"
            BsObj_1st = getBSobj_genFile(ID_Y_Q1st_cfg, None)

        # 取得Income的會科清單
        GL_Imcome = getConfigData(StockID_List[3], "glst1")
        # 從BSObject取得Income的Table
        tbObj_Imcome_1st =  getTBobj_genFile(BsObj_1st, 1, None, ID_Y_Q1st_cfg)
        try:
            for gl in GL_Imcome:
                val = getItemVal(tbObj_Imcome_1st, gl)
                if gl == "9750":
                    itemlist.append(float(val))
                else:
                    itemlist.append(int(val))
            itemdict = dict(zip(GL_Imcome, itemlist))
        except:
            return 0

        # 表示這個公司有季報
        if ID_Y_Q1st_cfg[2] == "1":
        # 累加第二,三季
            for q in range(2,4):
                ID_Y_Q_cfg = [StockID_List[0], StockID_List[1], str(q), StockID_List[3]]
                BsObj = getBSobj_genFile(ID_Y_Q_cfg, None)
                tbObj_Imcome =  getTBobj_genFile(BsObj, 1, None, ID_Y_Q_cfg)
                for gl in GL_Imcome:
                    val = getItemVal(tbObj_Imcome, gl)
                    if gl == "9750":
                        itemdict[gl] += float(val)
                    else:    
                        itemdict[gl] += int(val)

        return itemdict
    else:
        return 0

# 取得現金流量表前一季的值(只有年/半年報的在Q4取Q2資料)
def getPeriodCashFlow(StockID_List):
    itemlist = []   
    if StockID_List[2] != "1":
        ID_Y_PQ_cfg = [StockID_List[0], StockID_List[1], str(int(StockID_List[2]) - 1), StockID_List[3]]
        BsObj = getBSobj_genFile(ID_Y_PQ_cfg, None)
        # 有些公司只有半年報及年報
        if BsObj == None and StockID_List[2] == "2":
            return 0            
        if BsObj == None and StockID_List[2] == "4":    
            ID_Y_PQ_cfg[2] = str(int(StockID_List[2]) - 2)
            BsObj = getBSobj_genFile(ID_Y_PQ_cfg, None)

        GL_CashFlow = getConfigData(StockID_List[3], "glst2")
        tbObj_CashFlow_PQ =  getTBobj_genFile(BsObj, 2, None, ID_Y_PQ_cfg)

        try:
            for gl in GL_CashFlow:
                val = getItemVal(tbObj_CashFlow_PQ, gl)
                itemlist.append(int(val))
            itemdict = dict(zip(GL_CashFlow, itemlist))
            return itemdict
        except:
            return 0    
    else:
        return 0         

# 寫資料到Excel
def writeExcel(cfgfile, DataH, DataI, yq):
    genxls = getConfigData(cfgfile, "update_xls")
    file_path = getConfigData(cfgfile, "filepath")
    fname = f"Financial_{yq[0]}_Q{yq[1]}.xlsx"

    if genxls == None:
        return print(f"Config Without Create Excel File!!")
    
    # 建立目錄,不存在才建...
    if os.path.exists(file_path) == False:
        os.makedirs(file_path)

    # 轉換成DataFrame
    df_data = pd.DataFrame(DataI, columns = DataH)
    try:
        df_data.to_excel(f"{file_path}/{fname}", index = False)
        return print(f"Create {fname} Success!!")
    except:
        return print(f"Create {fname} Fail!!")

# 寫資料到資料庫
def updateFinancial_mssql(cfgfile, DataI, YQDate):
    upDB = getConfigData(cfgfile, "update_db")
    pwd_enc = "211_211_212_72_168_196_229_85_94_217_153_"

    if upDB == None:
        return print("Can't Update DB(BIDC.dbo.mopsFinancialByCompany) By config!")
    if DataI == []:
        return print("Item No Data For DB(BIDC.dbo.mopsFinancialByCompany)")    
    
    # 連結資料庫
    with pymssql.connect( server = "RAOICD01", user = "owner_sap", password = dectry(pwd_enc), database = "BIDC" ) as conn:
        with conn.cursor() as cursor:
            # 先刪資料
            try:      
                cursor.execute(f"DELETE FROM BIDC.dbo.mopsFinancialByCompany WHERE YQ_Date ='{YQDate}'")
                conn.commit()
            except:
                return print(f"Delete mopsFinancialByCompany {YQDate} Fail!!")
            # 寫入資料
            ary_data = np.array(DataI)
            item_tuple = list(map(tuple, ary_data))
            try:
                # 公司, 日期, PSMC平均匯率, 8"數量, 12"數量, 總資產, 總負債, 流通在外張數, 營業收入, 營業毛利, 營業費用, 營業費用(其他), 營業利益, 營業外收支, 稅後純益(損), 所得稅費用, 稅後淨利, EPS, RD費用, 稅前淨利, 利息費用, 折舊費用, 攤銷費用
                cursor.executemany("INSERT INTO BIDC.dbo.mopsFinancialByCompany (StockID, YQ_Date, PSMC_ExRate, WaferQty_8, WaferQty_12, Assets, Liabilities, OrdinaryShare, Oper_Revenue, GP_Oper, Oper_Expenses, NetOtherIncome, NetOperIncome, nonOperIncome, PF_AttrOwners, Tax_Expense, Profit, EPS, RD_Expense, PF_BeforeTax,  Inter_Expense, DP_Expense, Amor_Expense) VALUES (%s, %s, %f, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %f, %d, %d, %d, %d, %d)", item_tuple)
                conn.commit()
            except:
                return print(f"Update BIDC.dbo.mopsFinancialByCompany {YQDate} Fail!!")

def updateWaferQtyRevenuebyPortfolio_mssql(cfg, yqdate):    
    up_db = getConfigData(cfg, "update_db")
    
    if up_db == None:
        return print("Can't Update DB(SAP.dbo.sapRevenueQtyByPortfolio) By config!")
    pwd_enc = "215_203_225_72_88_148_169_83_98_"
    with pymssql.connect( server = "8AEISS01", user = "sap_user", password = dectry(pwd_enc) ) as conn:
        with conn.cursor() as cursor:
            try:
                cursor.execute(f"""SELECT   convert(varchar, DATEADD(qq, DATEDIFF(qq, 0, FKDAT), 0), 23) as YQ_Date,
                                            PC as Portfolio,
                                            round(SUM(IIF(FKART IN ('F2', 'L2'), LNETW, LNETW * -1)), -3) as Revenue,
                                            round(SUM(IIF(FKART IN ('F2', 'L2'), FKIMG, FKIMG * -1)), -3) as Qty,
                                            '8' as WaferSize,
                                            'L' as BU
                                        FROM BIDC.dbo.sapVwRevenue
                                        WHERE convert(varchar, DATEADD(qq, DATEDIFF(qq, 0, FKDAT), 0), 23) = convert(varchar, CONVERT(datetime,  '{yqdate}'), 23)
                                        GROUP BY  DATEADD(qq, DATEDIFF(qq, 0, FKDAT), 0), PC
                                    UNION
                                    SELECT  convert(varchar, DATEADD(qq, DATEDIFF(qq, 0, FKDAT), 0), 23) as YQ_Date,
                                            PC as Portfolio,
                                            round(SUM(IIF(FKART IN ('F2', 'L2'), LNETW, LNETW * -1)), -3) as Revenue,
                                            round(SUM(IIF(FKART IN ('F2', 'L2'), FKIMG, FKIMG * -1)), -3) as Qty,
                                            '12' as WaferSize,
                                            'L' as BU
                                        FROM F12BIDC.dbo.sapVwRevenue
                                        WHERE convert(varchar, DATEADD(qq, DATEDIFF(qq, 0, FKDAT), 0), 23) = convert(varchar, CONVERT(datetime,  '{yqdate}'), 23)
                                        GROUP BY  DATEADD(qq, DATEDIFF(qq, 0, FKDAT), 0), PC""")
                                    # 12M的部份手動給
                                    # UNION
                                    # SELECT  convert(varchar, DATEADD(qq, DATEDIFF(qq, 0, FKDAT), 0), 23) as YQ_Date,
                                    #         '' as Portfolio,
                                    #         round(SUM(IIF(FKART IN ('F2', 'ZL2', 'Z001'), LNETW, LNETW * -1)), -3) as Revenue,
                                    #         round(SUM(IIF(FKART IN ('F2', 'ZL2', 'Z001'), WQTY, WQTY * -1)), -3) as Qty,
                                    #         '12' as WaferSize,
                                    #         'M' as BU
                                    #     FROM M12SAP.dbo.sapRevenue
                                    #     WHERE convert(varchar, DATEADD(qq, DATEDIFF(qq, 0, FKDAT), 0), 23) = convert(varchar, CONVERT(datetime,  '{yqdate}'), 23)
                                    #     GROUP BY  DATEADD(qq, DATEDIFF(qq, 0, FKDAT), 0)""")
                itemdata = cursor.fetchall()
                headerline =  [item[0] for item in cursor.description]
                df_list = pd.DataFrame(itemdata, columns = headerline)
            except:
                return print("Get revenue & Qty From Table is Fail!!")
    if df_list.empty:
        return print("DataFrame is Empty!!")

    pwd_enc = "211_211_212_72_168_196_229_85_94_217_153_"
    data_tuple = list(df_list.itertuples(index = False))
    with pymssql.connect( server = "RAOICD01", user = "owner_sap", password = dectry(pwd_enc), database = "SAP" ) as conn:
        with conn.cursor() as cursor:
            # 先刪資料
            try:      
                cursor.execute(f"DELETE FROM SAP.dbo.sapRevenueQtyByPortfolio WHERE YQ_Date = '{yqdate}' AND BU = 'L'")
                conn.commit()
            except:
                return print(f"Delete sapRevenueQtyByPortfolio {yqdate} Fail!!")

            # 寫入資料
            try:
                cursor.executemany("INSERT INTO SAP.dbo.sapRevenueQtyByPortfolio (YQ_Date, Portfolio, Revenue, Qty, WaferSize, BU) VALUES (%s, %s, %d, %d, %s, %s)", data_tuple) 
                conn.commit()
                return print(f"sapRevenueQtyByPortfolio Insert Complete ({yqdate})")
            except:
                return print(f"Insert sapRevenueQtyByPortfolio {yqdate} Fail!!")
# %%    

cfg_fname = r"./config/config.json"

year, quarter = getPerviousQuarter(cfg_fname)

StockList = getConfigData(cfg_fname, "stocklist")

genFileFlag = getConfigData(cfg_fname, "gen_html")

# 需要抓會計的List
GL0 = getConfigData(cfg_fname, "glst0")
GL1 = getConfigData(cfg_fname, "glst1")
GL2 = getConfigData(cfg_fname, "glst2")

record = 0
# HeaderText 
HeaderLine = []
ItemData = []
# 年/季的第一天
YQFirstDate = ""
# 取得平均ExchangeRate
AvgRate = getQuarterAVGRate_mssql(year, quarter)

for StockID in StockList:
    itemlist = []
    # 把Stock ID / 年 / 季放到一個List中
    ID_Y_Q_cfg = [StockID, year, quarter, cfg_fname]
    # 取得BS所產生的Data
    bsObj = getBSobj_genFile(ID_Y_Q_cfg, genFileFlag)
    if bsObj == None:
        print (f"{StockID} 沒有 {year} Q{quarter} 的資料!!")
        continue
    # 取得Data的Header
    if HeaderLine == []:
        HeaderLine = getHeaderLine(bsObj, cfg_fname)

    # 取第一個table(BalanceSheet)
    tbObj_Balance = getTBobj_genFile(bsObj, 0, genFileFlag, ID_Y_Q_cfg)
    # 取第二個table(Statement of Comprehensive Income)
    tbObj_Income = getTBobj_genFile(bsObj, 1, genFileFlag, ID_Y_Q_cfg)
    # 取第三個table(Cash Flows)
    tbObj_CashFlows = getTBobj_genFile(bsObj, 2, genFileFlag, ID_Y_Q_cfg)

    # 取得item的固定值--季的第一天
    if YQFirstDate == "":
        YQFirstDate = getQuarterFirstDate(tbObj_Balance)
    # 在當季的Wafer Qty
    WQTY_8  = getWaferQty_mssql(StockID, YQFirstDate, 8)
    WQTY_12 = getWaferQty_mssql(StockID, YQFirstDate, 12)

    for val in (StockID, str(YQFirstDate), float(AvgRate), WQTY_8, WQTY_12):
        itemlist.append(val)

    # 總資產(1XXX) / 總負債(2XXX) / 普通股股本(3110)
    for gl in GL0:        
        ## 抓第三個column,當季的值
        val = getItemVal(tbObj_Balance, gl)   
        itemlist.append(int(val) * 1000)

    # 營業收入(4000) / 營業毛利(5950) / 營業費用(6000) / 其他收益(6500) / 營業利益(6900) / 營業外收支(7000) / 母公司業主(8610) / 所得稅費用(7950)
    # 稅後淨利(8200) / 稀釋每股盈餘(9850) / 研究發展費用(6300)
    # 取得前三季的Income
    dict_income = getFirst3PeriodImcome(ID_Y_Q_cfg)
    for gl in GL1:
        # 判斷是否有該GL Account(有才抓值,沒有就給0)
        val = getItemVal(tbObj_Income, gl)
        if dict_income != 0:
            last_cnt_val = dict_income[gl]
        else:
            last_cnt_val = 0

        if gl == "9750":
            itemlist.append(float(val) - last_cnt_val)
        else:        
            itemlist.append((int(val) - last_cnt_val) * 1000)

    # 稅前淨利(A10000) / 利息費用(A20900) / 折舊費用(A20100) / 攤銷費用(A20200)
    # 取得前季的CashFlow(第一季排除)
    dict_cashflow = getPeriodCashFlow(ID_Y_Q_cfg)
    for gl in GL2:
        # 判斷是否有該GL Account(有才抓值,沒有就給0)
        val = getItemVal(tbObj_CashFlows, gl)
        if dict_cashflow != 0:
            last_cnt_val = dict_cashflow[gl]
        else:
            last_cnt_val = 0

        itemlist.append((int(val) - last_cnt_val) * 1000)
    ItemData.append(itemlist)

    record += 1
    # 連續抓會被擋,所以抓了幾家要停一下
    if  (record % 4 == 0 and quarter != 4) or (record % 2 == 0 and quarter == 4):
        time.sleep(20)

YearQuarter = [year, quarter]
writeExcel(cfg_fname, HeaderLine, ItemData, YearQuarter)
updateFinancial_mssql(cfg_fname, ItemData, YQFirstDate)
# 處理Qty Revenue 寫到table中
updateWaferQtyRevenuebyPortfolio_mssql(cfg_fname, YQFirstDate)
