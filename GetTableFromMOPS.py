import urllib.request as req
import bs4
url = "https://mops.twse.com.tw/server-java/t164sb01?step=1&CO_ID=3702&SYEAR=2019&SSEASON=3&REPORT_ID=C"
head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
urlwithhead = req.Request(url, headers = head_info)

with req.urlopen(urlwithhead) as respon:
    data = respon.read().decode("big5")

with open ("web.html", mode = "w", encoding = "UTF-8") as web_html:
    web_html.write(data)

# print(data)         
root =  bs4.BeautifulSoup(data, "html.parser")
table = root.find_all("table")
# print(type(table))

with open ("table.txt", mode = "w", encoding = "UTF-8") as table_html:
    table_html.write(str(table))
