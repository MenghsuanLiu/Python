# %%
import os
import requests as req
import json
import pandas as pd

from bs4 import BeautifulSoup as bs

def getConfigData(file_path, datatype):
    try:
        with open(file_path, encoding="UTF-8") as f:
            jfile = json.load(f)
        val = jfile[datatype]    
        # val =  ({True: "", False: jfile[datatype]}[jfile[datatype] == "" | jfile[datatype] == "None"])
    except:
        val = ""
    return val


def getBSobj(YYYYMMDD, cfg):
    head_info = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
    url = f"https://www.twse.com.tw/fund/T86?response=html&date={YYYYMMDD}&selectType=ALL"
    # 處理網址
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "utf-8"
    # 抓config檔決定是否要產生File
    genfile = getConfigData(cfg, "genhtml")

    # 判斷是否要產生File,不產生就直接把BS Obj傳出去
    if genfile != "":
        ## 寫網頁原始碼到檔案中cfg是config檔的路徑及檔名
        wpath = getConfigData(cfg, "webpath")
        # 產生出的檔案存下來
        ## 建立目錄,不存在才建...
        if os.path.exists(wpath) == False:
            os.makedirs(wpath)
        rootlxml = bs(urlwithhead.text, "lxml")
        with open(f"{wpath}/三大法人買賣超日報_{YYYYMMDD}.html", mode="w", encoding="UTF-8") as web_html:
            web_html.write(rootlxml.prettify())

    #傳出BeautifulSoup物件     
    return bs(urlwithhead.text, "lxml")

def getTBobj(bsobj, tbID, cfg):
    tb = bsobj.find_all("table")[tbID]
    # 抓config檔決定是否要產生File
    genfile = getConfigData(cfg, "genhtml")
    # 判斷是否要產生File,不產生就直接把BS Obj傳出去
    if genfile != "":
        ## 寫網頁原始碼到檔案中cfg是config檔的路徑及檔名
        wpath = getConfigData(cfg, "webpath")
        # 產生出的檔案存下來
        ## 建立目錄,不存在才建...
        if os.path.exists(wpath) == False:
            os.makedirs(wpath)
        with open(f"{wpath}/table.html", mode="w", encoding="UTF-8") as web_html:
            web_html.write(tb.prettify())
    return tb

def getHeaderLine(tbObj):
    headtext = []
    for head in tbObj.select("table > thead > tr:nth-child(2) > td"):
        headtext.append(head.text)
    return headtext


# %%
cfg_fname = r"./config/config.json"

TB_Obj = getTBobj(getBSobj("20210730", cfg_fname), 0, cfg_fname)
Header = getHeaderLine(TB_Obj)
ItemData = []
for rows in TB_Obj.select("table > tbody > tr")[1:]:
    itemlist = []
    colnum = 0
    for col in rows.select("td"):
        colnum += 1
        if colnum in (1, 2):
            val = col.string.strip()
        else:
            val = int(col.text.replace(",", "").strip())
        itemlist.append(val)
    ItemData.append(itemlist)  
# %%
df_vol = pd.DataFrame(ItemData, columns = Header)
fpath = getConfigData(cfg_fname, "filepath")
if os.path.exists(fpath) == False:
    os.makedirs(fpath)
df_vol.to_csv(f"{fpath}/vloumn.csv", index = False)
# %%
