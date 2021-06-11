# %%
import os
import requests as req
from bs4 import BeautifulSoup as bs
import pandas as pd
import datetime
from datequarter import DateQuarter
import pymssql
# import pyodbc as odbc
import time
import json
from util.EncryptionDecrypt import dectry

# 取得config檔中的資料
def getConfigData(file_path, datatype):
    with open(file_path, encoding = "UTF-8") as f:
        jfile = json.load(f)
    list_val = jfile[datatype]
    return list_val

# 取得前一個年季, Base on Today
def getPerviousQuarter():
    PreviousQuarter = DateQuarter.from_date(datetime.date.today()) - 1
    y = str(PreviousQuarter._year)
    q = str(PreviousQuarter._quarter)
    return y, q

# 取得季的平均Rate
def getQuarterAVGRate_mssql(Fyear, Fquarter):
    pwd_enc = "215_203_225_72_88_148_169_83_98_"
    pwd = dectry(pwd_enc)
    # 季轉月區間
    max_mon = int(Fquarter) * 3
    min_mon = max_mon - 2
    try:
        with pymssql.connect( server = "8AEISS01", user = "sap_user", password = pwd, database = "BIDC" ) as conn:
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
            pwd = dectry(pwd_enc)
            with pymssql.connect( server = "8AEISS01", user = "sap_user", password = pwd ) as conn:
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
    wpath = "html_file"
    # 處理網址
    # url = url_model.format(Category, YM)
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "big5"

    chk_nodata = bs(urlwithhead.text, "lxml").find("body").text
    if chk_nodata[0:5] == "檔案不存在":
        return None

    ## 寫網頁原始碼到檔案中(有值就要產生File)
    if genfile != "":
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
    if genfile != "":
        wpath = "html_file"
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
        tbobj = getTBobj_genFile(bsobj, i, "", [])
        for gaccount in GL:
            val = getHeadText(tbobj, gaccount)
            data_head.append(val)     
    return data_head

def getItemVal(tbobj, GLAccount):
    try:
        val = tbobj.find("td", text = GLAccount).find_parent("tr").find_all("td")[2].text.strip().replace(",", "").replace("(", "-").replace(")", "")
    except:
        val = 0
    return val

def getQuarterFirstDate(tbobj):
    show_date = tbobj.find_all("th")[3].find("span", class_ = "en").text.split("/")
    # 因為上面的月只會show 3, 6, 9, 12所以不用擔心跨年的問題
    return datetime.date(int(show_date[0]), int(show_date[1]) - 2, 1)

# 取得Income前三季的值加總
def getFirst3PeriodImcome(StockID_List, file_path):
    ID_Y_Q1 = [StockID_List[0], StockID_List[1], 1]
    itemlist = []
    # 只有第4季才需把前三季的加總
    if StockID_List[2] == 4:
        # 先處理第一季(Q1沒有值就不再計算了)
        BsObj_Q1 = getBSobj_genFile(ID_Y_Q1, "")
        GL_Imcome = getConfigData(file_path, "glst1")

        tbObj_Imcome_Q1 =  getTBobj_genFile(BsObj_Q1, 1, "", ID_Y_Q1)
        try:
            for gl in GL_Imcome:
                val = getItemVal(tbObj_Imcome_Q1, gl)
                if gl == "9750":
                    itemlist.append(float(val))
                else:
                    itemlist.append(int(val))
            itemdict = dict(zip(GL_Imcome, itemlist))
            # return itemdict
        except:
            return 0
        # 累加第二,三季
        for q in range(2,4):
            ID_Y_Q = [StockID_List[0], StockID_List[1], q]
            BsObj = getBSobj_genFile(ID_Y_Q, "")
            tbObj_Imcome =  getTBobj_genFile(BsObj, 1, "", ID_Y_Q)
            for gl in GL_Imcome:
                val = getItemVal(tbObj_Imcome, gl)
                if gl == "9750":
                    itemdict[gl] += float(val)
                else:    
                    itemdict[gl] += int(val)
        return itemdict
    else:
        return 0

# 取得現金流量表前一季的值
def getPeriodCashFlow(StockID_List, file_path):
    itemlist = []   
    if StockID_List[2] != "1":
        ID_Y_PQ = [StockID_List[0], StockID_List[1], StockID_List[2] - 1]
        BsObj = getBSobj_genFile(ID_Y_PQ, "")
        GL_CashFlow = getConfigData(file_path, "glst2")
        tbObj_CashFlow_PQ =  getTBobj_genFile(BsObj, 2, "", ID_Y_PQ)
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

def writeExcel(cfgfile, DataH, DataI, yq):
    genxls = getConfigData(cfgfile, "update_xls")
    file_path = getConfigData(cfgfile, "filepath")
    fname = f"Financial_{yq[0]}_Q{yq[1]}"

    if genxls != "":
        # 建立目錄,不存在才建...
        if os.path.exists(file_path) == False:
            os.makedirs(file_path)
        
        # 轉換成DataFrame
        df_data = pd.DataFrame(DataI, columns = DataH)
        try:
            df_data.to_excel(f"{file_path}/{fname}.xlsx", index = False)
            return print(f"Create {fname}.xlsx Success!!")
        except:
            return print(f"Create {fname}.xlsx Fail!!")
    else:
        return print(f"Config Without Create Excel File!!")

# %%
cfg_fname = "./config/config.json"

year, quarter = getPerviousQuarter()

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
# %%
for StockID in StockList:
    itemlist = []
    # 把Stock ID / 年 / 季放到一個List中
    ID_Y_Q = [StockID, year, quarter]
    # 取得BS所產生的Data
    bsObj = getBSobj_genFile(ID_Y_Q, genFileFlag)
    if bsObj == None:
        print (f"{StockID} 沒有 {year} Q{quarter} 的資料!!")
        continue
    # 取得Data的Header
    if HeaderLine == []:
        HeaderLine = getHeaderLine(bsObj, cfg_fname)

    # 取第一個table(BalanceSheet)
    tbObj_Balance = getTBobj_genFile(bsObj, 0, genFileFlag, ID_Y_Q)
    # 取第二個table(Statement of Comprehensive Income)
    tbObj_Income = getTBobj_genFile(bsObj, 1, genFileFlag, ID_Y_Q)
    # 取第三個table(Cash Flows)
    tbObj_CashFlows = getTBobj_genFile(bsObj, 2, genFileFlag, ID_Y_Q)

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
    dict_income = getFirst3PeriodImcome(ID_Y_Q, cfg_fname)
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
    dict_cashflow = getPeriodCashFlow(ID_Y_Q, cfg_fname)
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


# %%
import datetime
datetime.date.today()
# %%

# 取得網址相關資訊
# url = "https://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID=3702&SYEAR=2019&SSEASON=3&REPORT_ID=C"
url_templete = "https://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID={}&SYEAR={}&SSEASON={}&REPORT_ID=C"
head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}



# 存成檔案時的目錄
cfg_fname = "./config/config.json"
file_path = "download_file"
web_path = "html_file"
# 建立目錄,不存在才建...
if os.path.exists(file_path) == False:
    os.makedirs(file_path)
if os.path.exists(web_path) == False:
    os.makedirs(web_path)

StockList = ["2330", "2303", "2408", "2344", "2337", "5347", "6770"]
## 會科清單
# 資產負債表
gl01_list = ["1XXX", "2XXX", "3110"]
# 綜合損益表
gl02_list = ["4000", "5950", "6000", "6500", "6900", "7000", "8610", "7950", "8200", "9750", "6300"]
# 現金流量表
gl03_list = ["A10000", "A20900", "A20100", "A20200"]


# 以今天算出前一個季度
PreviousQuarter = DateQuarter.from_date(datetime.date.today()) - 1
year = str(PreviousQuarter._year)
quarter = str(PreviousQuarter._quarter)
# year = "2020"
# quarter = "2"

# 連結MS SQL資訊
conn_sql = odbc.connect(Driver = '{SQL Server Native Client 11.0}', Server = "RAOICD01", database = "BIDC", user = "owner_sap", password = "oic#sap21o4")
conn_8aeiss01 = odbc.connect(Driver = '{SQL Server Native Client 11.0}', Server = "8AEISS01", database = "BIDC", user = "sap_user", password = "sap##1405")
cursor = conn_sql.cursor()
cursor_8aeiss01 = conn_8aeiss01.cursor()




record = 0
data_head = []
data_item = []
YQ_FirstDate = []
data_exist = ""
exchange_rate = get_Q_Rate(cursor_8aeiss01, year, quarter)

for CompanyID in StockList:
    item_list = []
    item_imcome = []
    item_cash = []
    # 取得網頁內容
    
    root = get_BSobj(CompanyID, year, quarter, "X")
    # 判斷是否有資料
    no_data = root.find("body").text
    if no_data[0:5] == "檔案不存在":
        print(CompanyID, ":", no_data)
        continue
    else:
        data_exist = "X"    #一個loop有值就表示後面需要寫資料庫或Excel    

    # 取第一個table(BalanceSheet)
    tb_BalanceSheet = get_TBobj( root, 0, CompanyID, year, quarter, "X" )
    # 取第二個table(Statement of Comprehensive Income)
    tb_ComprehensiveIncome = get_TBobj( root, 1, CompanyID, year, quarter, "X")
    # 取第三個table(Cash Flows)
    tb_CashFlow = get_TBobj( root, 2, CompanyID, year, quarter, "X" )

    # 給固定值-Head(只要取一次就好)
    if record == 0:
        for fixval in ("公司", "日期", "PSMC平均匯率"):
            data_head.append(fixval)
        # 取出第一個表中的第一個日期,要減二個月才是季初            
        head_date = tb_BalanceSheet.find_all("th")[3].find("span", class_ = "en").text.split("/")
        YQ_FirstDate = datetime.date(int(head_date[0]), int(head_date[1]) - 2, 1)
    # 給固定值-Item
    for fixval in (CompanyID, str(YQ_FirstDate), float(exchange_rate)):
        item_list.append(fixval)
    # 取得8" /12" Wafer的值(PSMC Only)
    w8_qty = get_waferqty(cursor, cursor_8aeiss01, item_list, 8)
    w12_qty = get_waferqty(cursor, cursor_8aeiss01, item_list, 12)
    # 綜合損益第四季要扣前三季的值 
    if quarter == "4":
        item_val_1q = []        
        root = get_BSobj(CompanyID, year, "1", "")
        try:
            tb_ComprehensiveIncome_last = get_TBobj( root, 1, CompanyID, year, "1", "")
            for GL in gl02_list:
                val = get_itemval(tb_ComprehensiveIncome_last, GL)
                if GL == "9750":
                    item_val_1q.append(float(val))
                else:        
                    item_val_1q.append(int(val))
            item_imcome = item_val_1q            
        except:
            item_imcome = []
         
        if item_imcome != []:
            for q_bef in ("2", "3"):
                item_val_1q = []
                root = get_BSobj(CompanyID, year, q_bef, "")
                tb_ComprehensiveIncome_last = get_TBobj( root, 1, CompanyID, year, q_bef, "")
                gl_recod = 0
                for GL in gl02_list:
                    val = get_itemval(tb_ComprehensiveIncome_last, GL)                
                    if GL == "9750":
                        item_imcome[gl_recod] += float(val)
                    else:
                        item_imcome[gl_recod] += int(val)

                    gl_recod += 1
    # 現金流量表要扣前一季的值
    if quarter != "1":
        root = get_BSobj(CompanyID, year, str(int(quarter) - 1), "")
        try:
            tb_CashFlow_last = get_TBobj( root, 2, CompanyID, year, str(int(quarter) - 1), "")
            for GL in gl03_list:
                item_val_1q = get_itemval(tb_CashFlow_last, GL) 
                item_cash.append(int(item_val_1q))
        except:
            item_cash = []            

    # 總資產(1XXX) / 總負債(2XXX) / 普通股股本(3110)
    for GL in gl01_list:        
        ## 抓第三個column,當季的值
        item_val = get_itemval(tb_BalanceSheet, GL)   
        item_list.append(int(item_val) * 1000)       
        ## 抓第二個column,中文當成Header(只在第一個loop抓)
        if record == 0:            
            head_val = get_headtext(tb_BalanceSheet, GL)
            data_head.append(head_val)    

    # 營業收入(4000) / 營業毛利(5950) / 營業費用(6000) / 其他收益(6500) / 營業利益(6900) / 營業外收支(7000) / 母公司業主(8610) / 所得稅費用(7950)
    # 稅後淨利(8200) / 稀釋每股盈餘(9850) / 研究發展費用(6300)
    gl_recod = 0
    for GL in gl02_list:
        ## 抓第三個column,當季的值
        # 判斷是否有該GL Account(有才抓值,沒有就給0)
        item_val = get_itemval(tb_ComprehensiveIncome, GL)
        try:
            pass_val = item_imcome[gl_recod]
        except:
            pass_val = 0
        
        gl_recod += 1

        if GL == "9750":
            item_list.append(float(item_val) - pass_val)
        else:        
            item_list.append((int(item_val) - pass_val) * 1000)
        ## 抓第二個column,中文當成Header(只在第一個loop抓)
        if record == 0:
            head_val = get_headtext(tb_ComprehensiveIncome, GL)
            data_head.append(head_val)
        

    # 稅前淨利(A10000) / 利息費用(A20900) / 折舊費用(A20100) / 攤銷費用(A20200)
    gl_recod = 0    #取前一季的資料用item_cash
    for GL in gl03_list:        
        # 抓第三個column,當季的值
        item_val = get_itemval(tb_CashFlow, GL)
        try:
            pass_val =  item_cash[gl_recod]
        except:
            pass_val = 0
        
        gl_recod += 1

        item_list.append((int(item_val) - pass_val) * 1000)
        # 抓第二個column,中文當成Header(只在第一個loop抓)
        if record == 0:
            head_val = get_headtext(tb_CashFlow, GL)
            data_head.append(head_val)
    # 取得8" 12"的出貨片數          
    item_list.append(w12_qty)
    item_list.append(w8_qty)
    if record == 0:
        data_head.append("WaferQty_12")
        data_head.append("WaferQty_8")

    record += 1
    data_item.append(item_list)
    # 連續抓會被擋,所以抓了幾家要停一下
    if record % 4 == 0:
        time.sleep(20)

# 放在寫資料之前再關,不要在def中關,可能會有問題    
cursor_8aeiss01.close()
if data_exist == "X":
    ## 產生Excel的部份
    df_Financial = pd.DataFrame(data_item, columns = data_head)                                                       
    df_Financial.to_excel(file_path + "/Financial.xlsx", index=False)
    # print(df_Financial)                                   
    
    ## 處理資料庫的部份
    # 先刪資料
    SQL_Delete = ("DELETE FROM BIDC.dbo.mopsFinancialByCompany WHERE YQ_Date = '" + str(YQ_FirstDate) + "'")

    cursor.execute(SQL_Delete)
    conn_sql.commit()
    # 寫資料到MS SQL(Revenue)
    SQL_Insert = ("INSERT INTO BIDC.dbo.mopsFinancialByCompany (YQ_Date, StockID, Assets, Liabilities, Oper_Revenue, GP_Oper, Oper_Expenses, NetOtherIncome, NetOperIncome, nonOperIncome, PF_BeforeTax, Profit, PF_AttrOwners, Inter_Expense, Tax_Expense, DP_Expense, Amor_Expense, EPS, RD_Expense, OrdinaryShare, PSMC_ExRate, WaferQty_12, WaferQty_8) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
    # Insart資料
    for list in data_item:
        # list[1]日期, [0]公司, [3]總資產, [4]總負債, [6]營業收入, [7]營業毛利, [8]營業費用, [9]營業費用(其他), [10]營業利益, [11]營業外收支, [17]稅前淨利, [14]稅後淨利, [12]稅後純益(損), [18]利息費用, [13]所得稅費用, [19]折舊費用, [20]攤銷費用, [15]EPS, [16]RD, [5]流通在外張數, [2]PSMC平均匯率
        value = [ list[1], list[0], list[3], list[4], list[6], list[7], list[8], list[9], list[10], list[11], list[17], list[14], list[12], list[18], list[13], list[19], list[20], list[15], list[16], list[5], list[2], list[21], list[22] ]
        cursor.execute(SQL_Insert, value)
        conn_sql.commit()
    conn_sql.close()
    print("Financial Data Update Complete!!")
