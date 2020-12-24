import requests as req
import re as rex
from bs4 import BeautifulSoup as bs

# 年月
# ym = ["109_9", "109_10", "109_11"]
ym = "109_11"
# 股票類別(sii = 上市, otc = 上櫃)
stockcatg = ["sii", "otc"]

head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}


# url_tmp = "https://mops.twse.com.tw/nas/t21/{}/t21sc03_{}_0.html"
url_tmp = "https://mops.twse.com.tw/nas/t21/{}/t21sc03_" + str(ym) + "_0.html"
for catg in stockcatg:
    url = url_tmp.format(catg)
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "big5"
    
    #寫網頁原始碼到檔案中
    root =  bs(urlwithhead.text, "lxml")
    with open ("imcome_" + catg + ".html", mode = "w", encoding = "UTF-8") as web_html:
        web_html.write(root.prettify())
    #取半導體的table
    tb = root.find("th", text = rex.compile(".*半導體")).find_parent("table")
    with open ("tb_semi_" + catg + ".html", mode = "w", encoding = "UTF-8") as web_html:
        web_html.write(tb.prettify())
