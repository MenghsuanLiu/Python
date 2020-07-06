import urllib.request as req
import bs4
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
    data = respon.read().decode("big5")

with open ("web.html", mode = "w", encoding = "UTF-8") as web_html:
    web_html.write(data)
   
root =  bs4.BeautifulSoup(data, "html.parser")
#取所有table
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




# for tr_flg in table_BalanceSheet.find_all("tr"):
#     for td_flg in tr_flg.find_all("td"):
#         for span_flg in td_flg.find_all("span", { "class" : "zh"}):
#             # print(span_flg.getText())
#             a.append(span_flg.getText().replace(u'\u3000',u' '))
#         if td_flg.find("span", { "class" : "zh"}):
#             continue
#         a.append(td_flg.getText())

# print(a)
# df_BalanceSheet = pd.DataFrame(a, columns = ["a", "b", "c", "d", "e"])
# df_BalanceSheet = pd.DataFrame(a)
# print(df_BalanceSheet)

# with open ("table.txt", mode = "w", encoding = "UTF-8") as table_html:
#     table_html.write(str(a))

# table_rows = root.find_all("tr")
# print(type(table))

# with open ("table_BalanceSheet.html", mode = "w", encoding = "UTF-8") as table_html:
#     table_html.write(str(table_BalanceSheet))
# with open ("table_Income.html", mode = "w", encoding = "UTF-8") as table_html:
#     table_html.write(str(table_Income))



# with open ("table.html", mode = "w", encoding = "UTF-8") as table_html:
#     table_html.write(str(table))
# print(table.tr)
