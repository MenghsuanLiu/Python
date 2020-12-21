import urllib.request as req
from bs4 import BeautifulSoup as bs
import pandas as pd
import numpy as np



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
with open ("web_source.html", mode = "w", encoding = "UTF-8") as web_html:
    web_html.write(root.prettify())

#取所有table
tb = root.find_all("table")
#取第一個table
tb_BalanceSheet = tb[0]
with open ("web_tb1.html", mode = "w", encoding = "UTF-8") as web_html:
    web_html.write(tb_BalanceSheet.prettify())

ymd = []
GL = []
GL_Desc = []
amtvalue = 0

# 從第二個Row開始loop起(Row 1 = 資產負債表)
for rows in tb_BalanceSheet.select("tr")[1:]:
    # 抓出年月日(表頭,抓第三欄為指定季的最後一天)
    for th_col3 in rows.select("th:nth-child(3) > .en"):
        ym_list = th_col3.string.split("/", 2)       
        if ym_list is not None: 
            if int(ym_list[1]) < 10:
                ym_list[1] = "0" + ym_list[1]
            ymd = "".join(ym_list)
            break
    # 抓資料的Column 1[會科]
    for col1 in rows.select("td:nth-child(1)"):
        GL = col1.string
    # 抓資料的Column 2[會科說明]    
    for col2 in rows.select("td:nth-child(2) > .zh"):
        GL_Desc = col2.string.strip()
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
    if GL != []:
        print(company, "\t", ymd, "\t", GL if GL != None else " " , "\t", GL_Desc, "\t", int(amtvalue))


