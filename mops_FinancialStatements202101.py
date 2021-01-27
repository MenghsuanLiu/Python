import os
import requests as req
from bs4 import BeautifulSoup as bs
import pandas as pd
import datetime
from datequarter import DateQuarter
import pyodbc as odbc

# 取得網址相關資訊
# url = "https://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID=3702&SYEAR=2019&SSEASON=3&REPORT_ID=C"
url_templete = "https://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID={}&SYEAR={}&SSEASON={}&REPORT_ID=C"
head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}

# 存成檔案時的目錄
file_path = "download_file"
web_path = "html_file"
# 建立目錄,不存在才建...
if os.path.exists(file_path) == False:
    os.makedirs(file_path)
if os.path.exists(web_path) == False:
    os.makedirs(web_path)

StockList = ["2330", "2303", "5347", "2408", "2344", "2337", "6770"]
# StockList = ["5347"]
# 以今天算出前一個季度
PreviousQuarter = DateQuarter.from_date(datetime.date.today()) - 1
year = str(PreviousQuarter._year)
quarter = str(PreviousQuarter._quarter)
year = "2019"
quarter = "4"

# 連結MS SQL資訊
conn_sql = odbc.connect(Driver = '{SQL Server Native Client 11.0}', Server = "RAOICD01", database = "BIDC", user = "owner_sap", password = "oic#sap21o4")
cursor = conn_sql.cursor() 


def get_BSobj(StockID, Fyear, Fquarter, genfile):
    # 處理網址
    url = url_templete.format(StockID, Fyear, Fquarter)
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "big5"
    # 寫網頁原始碼到檔案中(有值就要產生File)
    if genfile != "":
        rootlxml = bs(urlwithhead.text, "lxml")
        with open (web_path + "/FinancialWeb_" + StockID + "_" + Fyear + "Q" + Fquarter + ".html", mode = "w", encoding = "UTF-8") as web_html:
            web_html.write(rootlxml.prettify())
    #傳出BeautifulSoup物件
    return bs(urlwithhead.text, "lxml")

def get_TBobj(bsobj, tbID, StockID, Fyear, Fquarter, genfile):
    if genfile != "":
        if tbID == 0:
            fname = "tb_BalanceSheet"
        if tbID == 1:
            fname = "tb_ComprehensiveIncome"
        if tbID == 2:
            fname = "tb_CashFlow"

        tb = bsobj.find_all("table")[tbID]   
        with open (web_path + "/" + fname + "_" + StockID + "_" + Fyear + "Q" + Fquarter + ".html", mode = "w", encoding = "UTF-8") as web_html:
            web_html.write(tb.prettify())

    return  bsobj.find_all("table")[tbID]

def get_itemval(tbobj, GL_Account):
    try:
        val = tbobj.find("td", text = GL_Account).find_parent("tr").find_all("td")[2].text.strip().replace(",", "").replace("(", "-").replace(")", "")
    except:
        val = 0
    return val

def get_headtext(tbobj, GL_Account):
    try:
        text = tbobj.find("td", text = GL_Account).find_parent("tr").find("span", class_ ="zh").text.strip().replace("（","(").replace("）",")")
    except:
        text = GL_Account
    return text


# a = get_BSobj("2330", "2020", "3", "X")
# tb1 = get_TBobj(a, 0, "2330", "2020", "3")
# tb1 = get_TBobj(a, 1, "2330", "2020", "3", "")
# tb1 = get_TBobj(a, 2, "2330", "2020", "3")
# aa = get_currval(tb1, "4000")
# print(aa)
# quit()

record = 0
data_head = []
data_item = []
YQ_FirstDate = []
data_exist = ""
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
        for fixval in ("公司", "日期"):
            data_head.append(fixval)
        # 取出第一個表中的第一個日期,要減二個月才是季初            
        head_date = tb_BalanceSheet.find_all("th")[3].find("span", class_ = "en").text.split("/")
        YQ_FirstDate = datetime.date(int(head_date[0]), int(head_date[1]) - 2, 1)
    # 給固定值-Item
    for fixval in (CompanyID, str(YQ_FirstDate)):
        item_list.append(fixval)
# 綜合損益第四季要扣前三季的值 
    if quarter == "4":        
        for q_bef in ("1", "2", "3"):
            item_val_1q = []
            root = get_BSobj(CompanyID, year, q_bef, "")
            tb_ComprehensiveIncome_last = get_TBobj( root, 1, CompanyID, year, q_bef, "")
            gl_recod = 0
            for GL in ("4000", "5950", "6000", "6500", "6900", "7000", "8610", "7950", "8200", "9750", "6300"):
                val = get_itemval(tb_ComprehensiveIncome_last, GL)
                if q_bef == "1":
                    if GL == "9750":
                        item_val_1q.append(float(val))
                    else:        
                        item_val_1q.append(int(val))
                else:
                    if GL == "9750":
                        item_imcome[gl_recod] += float(val)
                    else:
                        item_imcome[gl_recod] += int(val) 
                gl_recod += 1

            if item_val_1q != []:
                item_imcome = item_val_1q

# 現金流量表要扣前一季的值
    if quarter != "1":
        root = get_BSobj(CompanyID, year, str(int(quarter) - 1), "")
        tb_CashFlow_last = get_TBobj( root, 2, CompanyID, year, str(int(quarter) - 1), "")
        for GL in ("A10000", "A20900", "A20100", "A20200"):
            item_val_1q = get_itemval(tb_CashFlow_last, GL) 
            item_cash.append(int(item_val_1q))

    # 總資產(1XXX) / 總負債(2XXX) / 普通股股本(3110)
    for GL in ("1XXX", "2XXX", "3110"):        
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
    for GL in ("4000", "5950", "6000", "6500", "6900", "7000", "8610", "7950", "8200", "9750", "6300"):
        ## 抓第三個column,當季的值
        # 判斷是否有該GL Account(有才抓值,沒有就給0)
        item_val = get_itemval(tb_ComprehensiveIncome, GL)

        if GL == "9750":
            item_list.append(float(item_val) - item_imcome[gl_recod])
        else:        
            item_list.append((int(item_val) - item_imcome[gl_recod]) * 1000)
        ## 抓第二個column,中文當成Header(只在第一個loop抓)
        if record == 0:
            head_val = get_headtext(tb_ComprehensiveIncome, GL)
            data_head.append(head_val)
        gl_recod += 1

    # 稅前淨利(A10000) / 利息費用(A20900) / 折舊費用(A20100) / 攤銷費用(A20200)
    gl_recod = 0    #取前一季的資料用item_cash
    for GL in ("A10000", "A20900", "A20100", "A20200"):        
        # 抓第三個column,當季的值
        item_val = get_itemval(tb_CashFlow, GL)                   
        item_list.append((int(item_val) - item_cash[gl_recod]) * 1000)
        # 抓第二個column,中文當成Header(只在第一個loop抓)
        if record == 0:
            head_val = get_headtext(tb_CashFlow, GL)
            data_head.append(head_val)
        gl_recod += 1       
    record += 1
    data_item.append(item_list)
    print(data_item)
    quit()
    

if data_exist == "X":
    ## 產生Excel的部份
    # df_Financial = pd.DataFrame(data_item, columns = data_head)                                                       
    # df_Financial.to_excel(file_path + "/Financial.xlsx", index=False)
    # print(df_Financial)                                   

    ## 處理資料庫的部份
    # 先刪資料
    SQL_Delete = ("DELETE FROM BIDC.dbo.mopsFinancialByCompany WHERE YQ_Date = '" + str(YQ_FirstDate) + "'")

    cursor.execute(SQL_Delete)
    conn_sql.commit()
    # 寫資料到MS SQL(Revenue)
    SQL_Insert = ("INSERT INTO BIDC.dbo.mopsFinancialByCompany (YQ_Date, StockID, Assets, Liabilities, Oper_Revenue, GP_Oper, Oper_Expenses, NetOtherIncome, NetOperIncome, nonOperIncome, PF_BeforeTax, Profit, PF_AttrOwners, Inter_Expense, Tax_Expense, DP_Expense, Amor_Expense, EPS, RD_Expense, OrdinaryShare) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
    # Insart資料
    for list in data_item:
        # list[1]=日期, [0]=公司, [2]=總資產, [3]=總負債, [5]=營業收入, [6]=營業毛利, [7]=營業費用, [8]營業費用(其他), [9]營業利益, [10]營業外收支, [16]稅前淨利, [13]稅後淨利, [11]稅後純益(損), [17]利息費用, [12]所得稅費用, [18]折舊費用, [19]攤銷費用, [14]EPS, [15]RD, [4]流通在外張數
        value = [ list[1], list[0], list[2], list[3], list[5], list[6], list[7], list[8], list[9], list[10], list[16], list[13], list[11], list[17], list[12], list[18], list[19], list[14], list[15], list[4] ]
        cursor.execute(SQL_Insert, value)
        conn_sql.commit()

    conn_sql.close()
    print("Financial Data Update Complete!!")

