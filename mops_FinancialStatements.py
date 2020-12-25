import urllib.request as req
from bs4 import BeautifulSoup as bs
import pandas as pd
import numpy as np
import pyodbc as odbc



# 輸入條件
# company = input("股票代碼: ")
# year = input("年度(西元): ")
# quarter = input("季度: ")
company = 3702
year = 2020
quarter = 1

# 取得網址相關資訊
# url = "https://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID=3702&SYEAR=2019&SSEASON=3&REPORT_ID=C"
url = "https://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID=" + str(company) + "&SYEAR=" + str(year) + "&SSEASON=" + str(quarter) + "&REPORT_ID=C"
head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
urlwithhead = req.Request(url, headers = head_info)

# 取得網頁內容
with req.urlopen(urlwithhead) as respon:
    webdata = respon.read().decode("big5")
#寫網頁原始碼到檔案中
root =  bs(webdata, "lxml")
# with open ("web_source.html", mode = "w", encoding = "UTF-8") as web_html:
#     web_html.write(root.prettify())

#取所有table
tb = root.find_all("table")

#取第一個table(BalanceSheet)
tb_BalanceSheet = tb[0]
# with open ("web_tb1.html", mode = "w", encoding = "UTF-8") as web_html:
#     web_html.write(tb_BalanceSheet.prettify())

#取第二個table(Statement of Comprehensive Income)
tb_ComprehensiveIncome = tb[1]
# with open ("web_tb2.html", mode = "w", encoding = "UTF-8") as web_html:
#     web_html.write(tb_ComprehensiveIncome.prettify())
    
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
