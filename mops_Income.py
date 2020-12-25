from os import replace
import requests as req
import re
from bs4 import BeautifulSoup as bs
import pandas as pd

# 年月
# ym = ["109_9", "109_10", "109_11"]
ym = "109_11"
# 股票類別(sii = 上市, otc = 上櫃)
stockcatg = ["sii", "otc"]

head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}


# url_tmp = "https://mops.twse.com.tw/nas/t21/{}/t21sc03_{}_0.html"
url_tmp = "https://mops.twse.com.tw/nas/t21/{}/t21sc03_" + str(ym) + "_0.html"
for catg in stockcatg:
    data_head = [] 
    data_item = []
    yyyymm = ym.split("_")
    yyyymm = str(int(yyyymm[0]) + 1911) + "/" + str(yyyymm[1]) + "/1"

    url = url_tmp.format(catg)
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "big5"
    
    #寫網頁原始碼到檔案中
    root =  bs(urlwithhead.text, "lxml")
    with open ("html_data/imcome_" + catg + ".html", mode = "w", encoding = "UTF-8") as web_html:
        web_html.write(root.prettify())
    #取半導體的table
    tb = root.find("th", text = re.compile(".*半導體")).find_parent("table")
    with open ("html_data/tb_semi_" + catg + ".html", mode = "w", encoding = "UTF-8") as web_html:
        web_html.write(tb.prettify())

    for head_line1 in tb.select("table > tr:nth-child(1) > th:nth-child(4)"):
        data_head.append("資料年月")
        for head_line2 in tb.select("table > tr:nth-child(2) > th"):
            # print(re.sub('<br\s*?>', ' ', head_line2.text))
            data_head.append(re.sub('<br\s*?>', ' ', head_line2.text))
        # print(head_line1.text)
        data_head.append(head_line1.text)
    # print(data_head)

    # 從第3個Row開始loop起(Row 3 以後是資料)
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
            LastPercent = col6.text.replace(",", "")
        for col7 in rows.select("td:nth-child(7)"):
            YoYPercent = col7.text.replace(",", "")
        for col8 in rows.select("td:nth-child(8)"):
            CurrCount = col8.text.replace(",", "")
        for col9 in rows.select("td:nth-child(9)"):
            LastCount = col9.text.replace(",", "")
        for col10 in rows.select("td:nth-child(10)"):
            DiffPercent = col10.text.replace(",", "")
        for col11 in rows.select("td:nth-child(11)"):
            Remark = col11.string.strip()            
        if StockID != []: 
            collect = [yyyymm, StockID, StockName, int(CurrRevenue), int(LastRevenue), int(YoYRevenue), float(LastPercent), float(YoYPercent), int(CurrCount), int(LastCount), float(DiffPercent), Remark]
            data_item.append(collect)

    df_imcome = pd.DataFrame(data_item, columns = data_head)
    # print(df_imcome)

    file_name = "{}_{}.csv".format(catg, ym)
    df_imcome.to_csv("download_data/" + file_name + "_UTF8", encoding = "UTF-8", index = False )
    df_imcome.to_csv("download_data/" + file_name + "_BIG5", encoding = "BIG5", index = False )
