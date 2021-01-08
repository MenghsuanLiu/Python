import os
import urllib.request as req
from bs4 import BeautifulSoup as bs
import pandas as pd
import numpy as np
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

StockList = ["2330", "2303"]
year = "2020"
quarter = "3"
yqdate = "2020-9-1"
    
record = 0
data_head = []
data_item = []
for CompanyID in StockList:
    item_list = []
    # 處理網址
    url = url_templete.format(CompanyID, year, quarter)
    urlwithhead = req.Request(url, headers = head_info)

    # 取得網頁內容
    with req.urlopen(urlwithhead) as respon:
        webdata = respon.read().decode("big5")
    # 寫網頁原始碼到檔案中
    root =  bs(webdata, "lxml")
    with open (web_path + "/FinancialWeb_" + CompanyID + "_" + year + "Q" + quarter + ".html", mode = "w", encoding = "UTF-8") as web_html:
        web_html.write(root.prettify())

    # 取第一個table(BalanceSheet)
    tb_BalanceSheet = root.find_all("table")[0]
    with open (web_path + "/tb_BalanceSheet_" + CompanyID + "_" + year + "Q" + quarter + ".html", mode = "w", encoding = "UTF-8") as web_html:
        web_html.write(tb_BalanceSheet.prettify())
    # 取第二個table(Statement of Comprehensive Income)
    tb_ComprehensiveIncome = root.find_all("table")[1]
    with open (web_path + "/tb_ComprehensiveIncome_" + CompanyID + "_" + year + "Q" + quarter + ".html", mode = "w", encoding = "UTF-8") as web_html:
        web_html.write(tb_BalanceSheet.prettify())
    # 取第三個table(Cash Flows)
    tb_CashFlow = root.find_all("table")[2]
    with open (web_path + "/tb_CashFlow_" + CompanyID + "_" + year + "Q" + quarter + ".html", mode = "w", encoding = "UTF-8") as web_html:
        web_html.write(tb_CashFlow.prettify())
    # 取第四個table(Change in Equity)
    tb_ChangeInEquity = root.find_all("table")[3]
    with open (web_path + "/tb_ChangeInEquity_" + CompanyID + "_" + year + "Q" + quarter + ".html", mode = "w", encoding = "UTF-8") as web_html:
        web_html.write(tb_ChangeInEquity.prettify())
    
    # 給固定值
    if record == 0:
        for fixval in ("公司", "日期"):
            data_head.append(fixval)

    for fixval in (CompanyID, yqdate):    
        item_list.append(fixval)
    # 總資產(1XXX) / 總負債(2XXX)
    for GL in ("1XXX", "2XXX"):        
        # 抓第三個column,當季的值
        item_val = tb_BalanceSheet.find("td", text = GL).find_parent("tr").find_all("td")[2].text.strip().replace(",", "").replace("(", "-").replace(")", "")        
        item_list.append(int(item_val) * 1000)
        if record == 0:
            # 抓第二個column,中文當成Header
            head_val = tb_BalanceSheet.find("td", text = GL).find_parent("tr").find("span", class_ ="zh").text.strip()
            data_head.append(head_val)
    # 營業收入(4000) / 營業毛利(5950) / 營業費用(6000) / 其他收益(6500) / 營業利益(6900) / 營業外收入及支出(7000) / 母公司業主(8610) / 所得稅費用(7950)
    # 稅後淨利(8200) / 稀釋每股盈餘(9850) / 研究發展費用(6300)
    for GL in ("4000", "5950", "6000", "6500", "6900", "7000", "8610", "7950", "8200", "9850", "6300"):
        # 抓第三個column,當季的值
        item_val = tb_ComprehensiveIncome.find("td", text = GL).find_parent("tr").find_all("td")[2].text.strip().replace(",", "").replace("(", "-").replace(")", "")
        if GL == "9850":
            item_list.append(float(item_val))
        else:        
            item_list.append(int(item_val) * 1000)

        if record == 0:    
            # 抓第二個column,中文當成Header
            head_val = tb_ComprehensiveIncome.find("td", text = GL).find_parent("tr").find("span", class_ ="zh").text.strip()
            data_head.append(head_val)
    # 稅前淨利(A10000) / 利息費用(A20900) / 折舊費用(A20100) / 攤銷費用(A20200)
    for GL in ("A10000", "A20900", "A20100", "A20200"):
        # 抓第三個column,當季的值
        item_val = tb_CashFlow.find("td", text = GL).find_parent("tr").find_all("td")[2].text.strip().replace(",", "").replace("(", "-").replace(")", "")        
        item_list.append(int(item_val) * 1000)
        if record == 0:
            # 抓第二個column,中文當成Header
            head_val = tb_CashFlow.find("td", text = GL).find_parent("tr").find("span", class_ ="zh").text.strip()
            data_head.append(head_val)
    # 普通股股本(3110)    
    item_val = tb_ChangeInEquity.find("td", text = "Z1").find_parent("tr").find_all("td")[2].text.strip().replace(",", "").replace("(", "-").replace(")", "")
    item_list.append(int(item_val) * 1000)
    if record == 0:
        data_head.append("普通股股本")
    record += 1
    data_item.append(item_list)
print(data_head)
print(data_item)
quit()






ymd = GL = GL_Desc =  data_list =[]
GL_Level = amtvalue = 0

# 從第二個Row開始loop起(Row 1 = 資產負債表)
for rows in tb_BalanceSheet.select("tr")[1:]:
    # 抓出年月日(表頭,抓第三欄為指定季的最後一天)
    for th_col3 in rows.select("th:nth-child(3) > .en"):
        ym_list = th_col3.string.replace("/", "-")
        if ym_list is not None:
            ymd = ym_list
            break
        # ym_list = th_col3.string.split("/", 2)       
        # if ym_list is not None: 
        #     if int(ym_list[1]) < 10:
        #         ym_list[1] = "0" + ym_list[1]
        #     ymd = "".join(ym_list)
        #     break
    # 抓資料的Column 1[會科]
    for col1 in rows.select("td:nth-child(1)"):
        GL = col1.string
    # 抓資料的Column 2[會科說明]    
    for col2 in rows.select("td:nth-child(2) > .zh"):        
        GL_Desc = col2.string.strip()
        # 由全型空白(ascii = 12288)判斷階層
        GL_Level = col2.string.count("　")
        # GL_Level = 0
        # for i in col2.string:
        #     if ord(i) == 12288:
        #         GL_Level += 1
    # 抓資料的Column 3[指定季的金額]   
    for col3 in rows.select("td:nth-child(3)"):
        tag_pre = col3.find("pre")
        if tag_pre != None:
            if tag_pre.text[0].isnumeric():
                amtvalue = tag_pre.text.replace(",", "")
            else:
                amtvalue = tag_pre.text.replace(",", "").replace("(", "-").replace(")", "")
        else:
            amtvalue = 0
    if GL != [] and GL != None:
        # print(company, "\t", ymd, "\t", GL if GL != None else " " , "\t", GL_Level, GL_Desc, "\t", float(amtvalue))        
        list = [str(company), ymd, GL if GL != None else " ", GL_Desc, GL_Level, float(amtvalue)]
        data_list.append(list)
# df_BalanceSheet = pd.DataFrame(data_list)
# print(df_BalanceSheet)

# 從第三個Row開始loop起(Row 1 = 綜合損益表)
for rows in tb_ComprehensiveIncome.select("tr")[2:]:
    # 抓資料的Column 1[會科]
    for col1 in rows.select("td:nth-child(1)"):
        GL = col1.string
    # 抓資料的Column 2[會科說明]    
    for col2 in rows.select("td:nth-child(2) > .zh"):        
        GL_Desc = col2.string.strip()
        # 由全型空白(ascii = 12288)判斷階層
        GL_Level = col2.string.count("　")
        # GL_Level = 0
        # for i in col2.string:
        #     if ord(i) == 12288:
        #         GL_Level += 1
    # 抓資料的Column 3[指定季的金額]   
    for col3 in rows.select("td:nth-child(3)"):
        tag_pre = col3.find("pre")
        if tag_pre != None:
            if tag_pre.text[0].isnumeric():
                amtvalue = tag_pre.text.replace(",", "")
            else:
                amtvalue = tag_pre.text.replace(",", "").replace("(", "-").replace(")", "")
        else:
            amtvalue = 0
    if GL != [] and GL != None:
        # print(company, "\t", ymd, "\t", GL if GL != None else " " , "\t", GL_Level, GL_Desc, "\t", float(amtvalue))        
        list = [str(company), ymd, GL if GL != None else " ", GL_Desc, GL_Level, float(amtvalue)]
        data_list.append(list)

conn_sql = odbc.connect(Driver = '{SQL Server Native Client 11.0}', Server = "RAOICD01", database = "BIDC", user = "owner_sap", password = "sap@@20166")
cursor = conn_sql.cursor()
SQL_Insert = ("INSERT INTO BIDC.dbo.mopsGLAccountDataByCompany (StockID, ReportDate, GLAccount, GLAccountDesc, Hierarchy, Amount) VALUES (?, ?, ?, ?, ?, ? );")
SQL_Delete = ("DELETE FROM BIDC.dbo.mopsGLAccountDataByCompany WHERE ReportDate = '" + ymd + "' AND StockID = '" + str(company) +"'")


# 先刪資料
cursor.execute(SQL_Delete)
conn_sql.commit()
# Insart資料
for list in data_list:    
    value = [ list[0], list[1], list[2], list[3], list[4], list[5] ]
    cursor.execute(SQL_Insert, value)
    conn_sql.commit()
conn_sql.close()




""" #取所有table
table = root.find_all("table")
#取第一個table
table_BalanceSheet = table[0]
#取第二個table
table_Income = table[1]
detail = []
head = []
tb_tr = table_BalanceSheet.find_all("tr")
i = 0
for tr_flg in tb_tr:
    tb_td = tr_flg.find_all("td")
    rows_data = [tr_flg.text.replace(u'\u3000',u' ') for tr_flg in tb_td]
    detail.append(rows_data)
    # print(rows_data)
for th_flg in tb_tr:
    for span_flg in th_flg.find_all("th"):
        i += 1
        if i == 1:
            continue
        for tb_th in span_flg.find_all("span", {"class":"zh"}):
            head.append(tb_th.getText())
# print(head)
df_BalanceSheet = pd.DataFrame(detail, columns = head)
# df_BalanceSheet = pd.DataFrame(detail, columns=["代號", "會計項目", "2020/3/31", "2019/12/31", "2019/3/31"])
# df_BalanceSheet.to_csv("balance.csv", index=False)
print(df_BalanceSheet)
for tr_flg in table_BalanceSheet.find_all("tr"):
    for td_flg in tr_flg.find_all("td"):
        for span_flg in td_flg.find_all("span", { "class" : "zh"}):
            # print(span_flg.getText())
            a.append(span_flg.getText().replace(u'\u3000',u' '))
        if td_flg.find("span", { "class" : "zh"}):
            continue
        a.append(td_flg.getText())
print(a)
df_BalanceSheet = pd.DataFrame(a, columns = ["a", "b", "c", "d", "e"])
df_BalanceSheet = pd.DataFrame(a)
print(df_BalanceSheet)
with open ("table.txt", mode = "w", encoding = "UTF-8") as table_html:
    table_html.write(str(a))
table_rows = root.find_all("tr")
print(type(table))
with open ("table_BalanceSheet.html", mode = "w", encoding = "UTF-8") as table_html:
    table_html.write(str(table_BalanceSheet))
with open ("table_Income.html", mode = "w", encoding = "UTF-8") as table_html:
    table_html.write(str(table_Income))
# with open ("table.html", mode = "w", encoding = "UTF-8") as table_html:
#     table_html.write(str(table))
# print(table.tr) """
