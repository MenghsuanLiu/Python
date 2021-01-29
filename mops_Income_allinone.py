  
import os
from types import coroutine
import requests as req
import re
from bs4 import BeautifulSoup as bs
import pandas as pd
import numpy as np
import datetime
import pyodbc as odbc

# 取BeautifulSoup物件
def get_BSobj(Industry, YM, genfile):
    head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
    url_model = "https://mops.twse.com.tw/nas/t21/{}/t21sc03_{}_0.html"
    # 處理網址
    url = url_model.format(Industry, YM)
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "big5"
    # 寫網頁原始碼到檔案中(有值就要產生File)
    if genfile != "":
        rootlxml = bs(urlwithhead.text, "lxml")
        with open (web_path + "/imcome_" + catg + ".html", mode = "w", encoding = "UTF-8") as web_html:
            web_html.write(rootlxml.prettify())
    #傳出BeautifulSoup物件
    return bs(urlwithhead.text, "lxml")

# 取得公司產業類別名稱
def get_CompIndustry(TBobj):
    return TBobj.find("tr").find("th").text.split("：")[1]

# 取得Header Data
def get_Header(TBobj):
    headtext = []
    for head_line1 in TBobj.select("table > tr:nth-child(1) > th:nth-child(4)"):
        headtext.append("資料年月")
        for head_line2 in tb.select("table > tr:nth-child(2) > th"):
            # print(re.sub('<br\s*?>', ' ', head_line2.text))
            headtext.append(re.sub('<br\s*?>', ' ', head_line2.text))
        # print(head_line1.text)
        for head_list in [ head_line1.text, "上市/上櫃" ]:
            headtext.append(head_list)
    return headtext

def get_SQLdata(SQLconn, sqlselect):
    df_comp = pd.read_sql(sqlselect, SQLconn)
    return df_comp

# 年月(用今天去抓前一個月)
premonth = (datetime.date(datetime.date.today().year, datetime.date.today().month, 1) - datetime.timedelta(days = 1))
## ym要用list包起來 
ym = [str( premonth.year - 1911 ) + "_" + str(premonth.month if premonth.month > 9 else str(premonth.month)[1:])]
# ym = ["109_1", "109_2", "109_3", "109_4", "109_5", "109_6", "109_7", "109_8", "109_9", "109_10"]
# yyyymm = datetime.date(premonth.year, premonth.month, 1)

# 股票類別(sii = 上市(listed company at stock exchange market), otc = 上櫃(listed company at over-the-counter market), rotc = 興櫃)
stockcatg = ["sii", "otc", "rotc", "pub"]
industy = ["半導體", "電子工業"]

# 存成檔案時的目錄
file_path = "download_file"
web_path = "html_file"
# 建立目錄,不存在才建...
if os.path.exists(file_path) == False:
    os.makedirs(file_path)
if os.path.exists(web_path) == False:
    os.makedirs(web_path)

# 連結MS SQL資訊
conn_sql = odbc.connect(Driver = '{SQL Server Native Client 11.0}', Server = "RAOICD01", database = "BIDC", user = "owner_sap", password = "oic#sap21o4")
cursor = conn_sql.cursor()   

# 取得資料庫中的客戶清單
SQL_Select = ("SELECT StockID, StockName, EnShowName FROM BIDC.dbo.mopsStockCompanyInfo")
df_Complist = get_SQLdata(conn_sql, SQL_Select)


data_head = []
data_item = []
data_company = []

for catg in stockcatg:
    for period in ym:
# 取得存入資料庫/檔案的資料年月
        yyyymm = period.split("_")
        yyyymm = str(int(yyyymm[0]) + 1911) + "-" + str(yyyymm[1]) + "-1"

# 取得BeautifulSoup Data
        root = get_BSobj(catg, period, "X") 

# 取市場資訊            
        market = root.find("b")
        market = market.text.split("公司")[0]
# 取table
        for ind in industy:
            try:
                tb = root.find("th", text = re.compile(".*" + ind)).find_parent("table")
            except:
                continue
            with open (web_path + "/tb_" + ind + "_" + catg + ".html", mode = "w", encoding = "UTF-8") as web_html:
                web_html.write(tb.prettify())

# 取表頭資料
            if data_head == []:
                data_head = get_Header(tb)

# 取公司類別
            cmpindusty = get_CompIndustry(tb)

# Get Item =>從第3個Row開始loop起(Row 3 以後是資料)
            for rows in tb.select("table > tr")[2:]:
                StockID = StockName = Remark = []
                CurrRevenue = LastRevenue = YoYRevenue = LastPercent = YoYPercent = CurrCount = LastCount = DiffPercent = 0
                for col1 in rows.select("td:nth-child(1)"):
                    StockID = col1.string.strip()
                for col2 in rows.select("td:nth-child(2)"):
                    StockName = col2.string.strip()
                for col3 in rows.select("td:nth-child(3)"):
                    CurrRevenue = col3.text.replace(",", "")
                for col4 in rows.select("td:nth-child(4)"):
                    LastRevenue = col4.text.replace(",", "")
                for col5 in rows.select("td:nth-child(5)"):
                    YoYRevenue = col5.text.replace(",", "")
                for col6 in rows.select("td:nth-child(6)"):
                    LastPercent = col6.text.replace(",", "").strip()    
                    if LastPercent == "":
                        LastPercent = 0
                for col7 in rows.select("td:nth-child(7)"):
                    YoYPercent = col7.text.replace(",", "").strip()
                    if YoYPercent == "":
                        YoYPercent = 0
                for col8 in rows.select("td:nth-child(8)"):
                    CurrCount = col8.text.replace(",", "")
                for col9 in rows.select("td:nth-child(9)"):
                    LastCount = col9.text.replace(",", "")
                for col10 in rows.select("td:nth-child(10)"):
                    DiffPercent = col10.text.replace(",", "").strip()
                    if DiffPercent == "":
                        DiffPercent = 0
                for col11 in rows.select("td:nth-child(11)"):
                    Remark = col11.string.strip().replace("-", "")
                if StockID != []: 
                    collect = [yyyymm, StockID, StockName, int(CurrRevenue), int(LastRevenue), int(YoYRevenue), float(LastPercent), float(YoYPercent), int(CurrCount), int(LastCount), float(DiffPercent), Remark, market]
                    data_item.append(collect)
                    
                    collect = [StockID, StockName, market, cmpindusty]
                    if collect not in data_company:
                        # 判斷公司是否已經存在
                        if any(df_Complist.StockID == collect[0]) == False or any(df_Complist.StockName == collect[1]) == False:
                            data_company.append(collect)

# 先刪資料
if data_item != []:
    SQL_Delete = ("DELETE FROM BIDC.dbo.mopsRevenueByCompany WHERE YearMonth = '" + yyyymm + "'")

    cursor.execute(SQL_Delete)
    conn_sql.commit()
    # 寫資料到MS SQL(Revenue)
    SQL_Insert = ("INSERT INTO BIDC.dbo.mopsRevenueByCompany (YearMonth, StockID, Revenue, Remark) VALUES (?, ?, ?, ?);")
    # Insart資料
    for list in data_item:
        value = [ list[0], list[1], list[3]*1000, list[11] ]
        cursor.execute(SQL_Insert, value)
        conn_sql.commit()
    # print(yyyymm + "(" + catg +")" + "Update Complete!!")
    print("Revenue Data Update Complete!!")

# 寫資料到MS SQL(Company)
if data_company !=[]:
    SQL_Delete = ("DELETE FROM BIDC.dbo.mopsStockCompanyInfo WHERE StockID = ?")
    for id in data_company:
        value = [id[0]]
        cursor.execute(SQL_Delete, value)
        conn_sql.commit()

    SQL_Insert = ("INSERT INTO BIDC.dbo.mopsStockCompanyInfo (StockID, StockName, Market, Industry, EnShowName) VALUES (?, ?, ?, ?, ?)")
    for list in data_company:
        value = [ list[0], list[1], list[2], list[3], "" ]
        cursor.execute(SQL_Insert, value)
        conn_sql.commit()
    print("Company Data Update Complete!!")
    conn_sql.close()


# 寫資料到File
if data_item != [] and data_head !=[]:
    df_imcome = pd.DataFrame(data_item, columns = data_head)
    # print(df_imcome)
    ## 寫到csv
    # file_name = "{}_{}_{}".format(ind, catg, period)
    # for en in ["UTF-8", "BIG5"]:
    #     # df_imcome.to_csv(file_path + "/" + file_name + "_" + en.replace("-", "") + ".csv", encoding = en, index = False )
    #     df_imcome.to_csv(file_path + "/revenue_" + en.replace("-", "") + ".csv", encoding = en, index = False )
    ## 寫到Excel
    df_imcome.to_excel(file_path + "/revenue.xlsx", index = False)
