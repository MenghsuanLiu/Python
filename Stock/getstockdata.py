# %%
import shioaji as sj
import pandas as pd
import requests as req
import talib
import os
import json
import time
from datetime import date, timedelta, datetime
from bs4 import BeautifulSoup as bs

# import numpy as np
# import mplfinance as mpf


def getConfigData(file_path, datatype):
    try:
        with open(file_path, encoding="UTF-8") as f:
            jfile = json.load(f)
        val = jfile[datatype]    
        # val =  ({True: "", False: jfile[datatype]}[jfile[datatype] == "" | jfile[datatype] == "None"])
    except:
        val = ""
    return val

def getSignal(dataframe, tatype):
    colnam = f"sgl_{tatype}"
    dataframe[colnam] = 0
    if tatype.lower() == "sma":
        dataframe.loc[(dataframe.Close > dataframe.MA_10) & (dataframe.Close > dataframe.MA_60), colnam] = 1
        dataframe.loc[(dataframe.Close < dataframe.MA_10) & (dataframe.Close < dataframe.MA_60), colnam] = -1
    if tatype.lower() == "bbands":
        dataframe.loc[dataframe.Close > dataframe.upperband, colnam] = -1
        dataframe.loc[dataframe.Close < dataframe.lowerband, colnam] = 1
    if tatype[0:3].lower() == "sar":
        high_9 = dataframe.High.rolling(9).max()
        low_9 = dataframe.Low.rolling(9).min()
        dataframe["tenkan_sen_line"] = (high_9 + low_9) / 2
        high_26 = dataframe.High.rolling(26).max()
        low_26 = dataframe.Low.rolling(26).min()
        dataframe["kijun_sen_line"] = (high_26 + low_26) / 2
        dataframe["senkou_spna_A"] = ((dataframe.tenkan_sen_line + dataframe.kijun_sen_line) / 2).shift(26)
        high_52 = dataframe.High.rolling(52).max()
        low_52 = dataframe.High.rolling(52).min()
        dataframe["senkou_spna_B"] = ((high_52 + low_52) / 2).shift(26)
        dataframe["chikou_span"] = dataframe.Close.shift(-26)
        if tatype[-3:] == "002":
            dataframe.loc[(dataframe.Close > dataframe.senkou_spna_A) & (dataframe.Close > dataframe.senkou_spna_B) & (dataframe.Close > dataframe.SAR_002), colnam] = 1
            dataframe.loc[(dataframe.Close < dataframe.senkou_spna_A) & (dataframe.Close < dataframe.senkou_spna_B) & (dataframe.Close < dataframe.SAR_002), colnam] = -1
        if tatype[-3:] == "003":
            dataframe.loc[(dataframe.Close > dataframe.senkou_spna_A) & (dataframe.Close > dataframe.senkou_spna_B) & (dataframe.Close > dataframe.SAR_003), colnam] = 1
            dataframe.loc[(dataframe.Close < dataframe.senkou_spna_A) & (dataframe.Close < dataframe.senkou_spna_B) & (dataframe.Close < dataframe.SAR_003), colnam] = -1
        dataframe = dataframe.drop(columns = ["tenkan_sen_line", "kijun_sen_line", "senkou_spna_A", "senkou_spna_B", "chikou_span"])
    if tatype[0:6].lower() == "maxmin":
        dataframe.loc[(dataframe["Close"] >= dataframe[f"max_{tatype[-3:]}"]), colnam] = 1
        dataframe.loc[(dataframe["Close"] <= dataframe[f"min_{tatype[-3:]}"]), colnam] = -1
    return dataframe

# 只要上市/上櫃,不要金融, KY股, 股價>=20
def getStockData(api, stocks, datatype):
    df = []
    for s in stocks:
        df_market =[]
        # 上市(筆數太多要等一下)
        if s == "TSE":
            market = api.Contracts.Stocks.TSE
            time.sleep(5)
        # 上櫃    
        if s == "OTC":
            market = api.Contracts.Stocks.OTC
        # 興櫃
        if s == "OES":  
            market = api.Contracts.Stocks.OES
        
        for id in market:
            df_market.append({**id})
        df_market = pd.DataFrame(df_market)
        # https://members.sitca.org.tw/OPF/K0000/files/F/01/%E8%AD%89%E5%88%B8%E4%BB%A3%E7%A2%BC%E7%B7%A8%E7%A2%BC%E5%8E%9F%E5%89%87.do分類對照表(17金融)
        # 不要權證/金融股 / 小於20元
        df_market = df_market[~df_market["category"].isin(["00", "", "17"]) & ~df_market["name"].str.contains("KY")]
        df_market = df_market[( df_market["limit_up"] + df_market["limit_down"] ) / 2 >= 20]

        if s == stocks[0]:
            df = df_market
        else:
            df = df.append(df_market)
    
    if datatype.lower() == "list":
        return df["code"].to_list()
    if datatype.lower() == "dataframe":
        df = df.filter(items = ["code", "name", "exchange", "category"]).rename(columns = {"code": "StockID", "name": "StockName", "exchange": "上市/上櫃"}).replace({"TSE": "上市", "OTC": "上櫃", "OES": "興櫃"}) 
        return df.reset_index()

def getStockDailyData(Stklist, cfg, days):
    fpath = getConfigData(cfg, "filepath")
    fpath = f"{fpath}/" + getConfigData(cfg, "hisname") + ".csv"
    # 讀取資料
    df_history = pd.read_csv(fpath, low_memory = False)
    # StockID由int轉str
    df_history["StockID"] = df_history["StockID"].apply(str)
    # 只留下這次要的Stock List
    df_history = df_history[df_history.StockID.isin(Stklist)]
    # 轉換日期格式
    df_history["ts_date"] = pd.to_datetime(df_history["ts_date"], format = "%Y-%m-%d").dt.date

    # 只留下每個股票後250筆,要用後...後面算數SMA類的資料才會對
    first = True
    for stockid, gp_df in df_history.groupby("StockID"):
        gp_df = gp_df.sort_values(by = "ts_date", ascending = True)
        gp_df = gp_df.tail(days)
        if first == True:
            df = gp_df
            first = False
        else:
            df = df.append(gp_df)

    return df.reset_index()

def getStockSMA(dframe, day_list):
    first = True
    for stockid, gp_df in dframe.groupby("StockID"):
        if type(day_list) is int:
            gp_df[f"MA_{day_list}"] = talib.SMA(gp_df.Close, timeperiod = day_list)
        else:
            for madays in day_list:
                gp_df[f"MA_{madays}"] = talib.SMA(gp_df.Close, timeperiod = madays)
        if first == True:
            df = gp_df
            first = False
        else:
            df = df.append(gp_df)  
    return df

def getStockBBands(dframe, period, stdNbr):
    first = True
    for stockid, gp_df in dframe.groupby("StockID"):
        gp_df["upperband"], gp_df["middleband"], gp_df["lowerband"] = talib.BBANDS( gp_df["Close"], timeperiod = period, nbdevup = stdNbr, nbdevdn = stdNbr, matype = 0)

        if first == True:
            df = gp_df
            first = False
        else:
            df = df.append(gp_df)  
    return df

def getStockSAR(dframe, acc, max):
    first = True
    title = str(acc).replace(".", "")
    for stockid, gp_df in dframe.groupby("StockID"):
        gp_df[f"SAR_{title}"] = talib.SAR(gp_df["High"], gp_df["Low"], acceleration = acc, maximum = max)

        if first == True:
            df = gp_df
            first = False
        else:
            df = df.append(gp_df)  
    return df

def getStockMaxMin(dframe, day_list, type_list):
    first = True
    for stockid, gp_df in dframe.groupby("StockID"):
        for fn in type_list:
            for days in day_list:
                if fn.lower() == "max":
                    gp_df[f"{fn}_{days}"] = gp_df["Close"].rolling(days).max()
                if fn.lower() == "min":
                    gp_df[f"{fn}_{days}"] = gp_df["Close"].rolling(days).min()
        if first == True:
            df = gp_df
            first = False
        else:
            df = df.append(gp_df)
    return df

def writeRawData(api, Stk_list, cfg):    
    file_exist = ""

    ymd = date.today().strftime("%Y%m%d")
    fpath = getConfigData(cfg, "filepath")
    bkpath = getConfigData(cfg, "bkpath")
    hisfile = f"{fpath}/" + getConfigData(cfg, "hisname") + ".csv"
    hisbkfile = f"{bkpath}/" + getConfigData(cfg, "hisname") + f"_{ymd}.csv"
    
    # # 建立目錄,不存在才建...(./data)
    if os.path.exists(fpath) == False:
        os.makedirs(fpath)
    #檔案存在就把它抓出來變成dataframe        
    if os.path.isfile(hisfile) == True:
        file_exist = "X"
        df_history = pd.read_csv(hisfile, low_memory = False)
        df_history["StockID"] = df_history["StockID"].apply(str)
        df_notinlist = df_history[~df_history.StockID.isin(Stk_list)]
        df_history = df_history[df_history.StockID.isin(Stk_list)]
        if os.path.exists(bkpath) == False:
            os.makedirs(bkpath)
        try:
            os.rename(hisfile, hisbkfile)
        except FileExistsError:
            os.remove(hisbkfile) 
            os.rename(hisfile, hisbkfile)
                

    for id in Stk_list:
        # 約抓一年份的資料
        # d_range = [datetime.strptime(f"{date.today().year - 1}-01-01", "%Y-%m-%d"), date.today()]
        d_range = [date.today() - timedelta(days = 400), date.today()]

        if file_exist == "X":
            his_df = df_history.loc[df_history["StockID"] == str(id)].sort_values(by = "ts_date")
            if not his_df.empty:
                d_range = [datetime.strptime(his_df["ts_date"].tail(1).values[0], "%Y-%m-%d") + timedelta(days = 1), date.today()]
            
        stock = api.Contracts.Stocks[id]
        stk_df = pd.DataFrame({**api.kbars(stock, start = d_range[0].strftime("%Y-%m-%d"), end = d_range[1].strftime("%Y-%m-%d"))})
        stk_df["ts_date"] = pd.to_datetime(stk_df.ts).dt.date
        stk_df = stk_df.sort_values(by = "ts")
        stk_df = stk_df.groupby("ts_date", sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
        stk_df.insert(0, "StockID", str(id))
        if Stk_list[0] == id:
            df_today = stk_df
        else:
            df_today = df_today.append(stk_df)

    if file_exist == "X":
        # 在前面轉換會造成取值有問題    
        df_history["ts_date"] = pd.to_datetime(df_history["ts_date"], format = "%Y-%m-%d").dt.date
        # 把沒有在StockList中的再寫回今天的DF
        if not df_notinlist.empty:
            df_notinlist["ts_date"] = pd.to_datetime(df_notinlist["ts_date"], format = "%Y-%m-%d").dt.date
            df_today = df_today.append(df_notinlist)    
        df_today = df_today.append(df_history)

    df = df_today.sort_values(by = ["StockID", "ts_date"], ascending = True)
    df.to_csv(hisfile, index = False)     
    return

def mergeDataFrame(dframe, stk_dframe, cfg):
    ymd = date.today().strftime("%Y%m%d")
    volfile = getConfigData(cfg, "filepath") + "/" + getConfigData(cfg, "volname") + f"_{ymd}.csv"
    
    vol_df = pd.read_csv(volfile, low_memory = False).filter(items = ["證券代號", "投信買賣超股數"]).rename(columns = {"證券代號": "StockID"})
    df = dframe.merge(stk_dframe, on = ["StockID"], how = "left")
    df = df.merge(vol_df, on = ["StockID"], how = "left")
    return df

def writeFinalData(dframe, cfg):
    ymd = date.today().strftime("%Y%m%d")
    resultfile = getConfigData(cfg, "filepath") + "/" + getConfigData(cfg, "resultname") + f"_{ymd}.xlsx"
    
    files = os.listdir(getConfigData(cfg, "filepath"))
    matching = [s for s in files if getConfigData(cfg, "resultname") in s]

    for file in matching:
        fmname = getConfigData(cfg, "filepath") + f"/{file}"
        toname = getConfigData(cfg, "bkpath") + f"/{file}"
        os.replace(fmname, toname)

    first = True
    for stockid, gp_df in dframe.groupby("StockID"):
        gp_df = gp_df.sort_values(by = "ts_date", ascending = False)
        gp_df = gp_df.iloc[[0]].filter(items = (["StockID", "StockName", "上市/上櫃", "ts_date", "Close", "投信買賣超股數", ] + [x for x in gp_df.columns[gp_df.columns.str.contains('sgl')]]))
        if first == True:
            df = gp_df
            first = False
        else:
            df = df.append(gp_df)
    df.to_excel(resultfile, index = False)    
    return df


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

def writeLegalPersonDailyStockVolume(cfg):
    ymd = date.today().strftime("%Y%m%d")
    fpath = getConfigData(cfg, "filepath")
    volfile = f"{fpath}/" + getConfigData(cfg, "volname") + f"_{ymd}.csv"

    TB_Obj = getTBobj(getBSobj(ymd, cfg), 0, cfg)
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

    df_vol = pd.DataFrame(ItemData, columns = Header)
    
    
    files = os.listdir(fpath)

    matching = [s for s in files if getConfigData(cfg, "volname") in s]

    for file in matching:
        filename = file.split(sep = ".")[0]
        fmname = getConfigData(cfg, "filepath") + f"/{file}"
        toname = getConfigData(cfg, "bkpath") + f"/{filename}_bk.csv"
        os.replace(fmname, toname)

    if os.path.exists(fpath) == False:
        os.makedirs(fpath)
    df_vol.to_csv(volfile, index = False)

    return




# 取得歷史tick資料


def getStockticks(api, StockID, date_signal):
    stock = api.Contracts.Stocks[StockID]
    df_tick = pd.DataFrame({**api.ticks(stock, date_signal)})
    df_tick.ts = pd.to_datetime(df_tick.ts)
    return df_tick
    

@sj.on_quote
def quote_callback(topic, quote_msg):
    print(topic, quote_msg)


@sj.on_event
def event_callback(resp_code, event_code, event):
    print("Respone Code: {} | Event Code: {} | Event: {}".format(
        resp_code, event_code, event))


# 登入帳號
stk_api = sj.Shioaji(backend = "http", simulation=False)
with open("D:\GitHub\Python\Stock\config\login.json", "r") as f:
    login_cfg = json.loads(f.read())
stk_api.login(**login_cfg)


# %%
stocks = ["TSE", "OTC"]
keyindex = ["SMA", "BBands", "SAR_002", "SAR_003", "maxmin_120", "maxmin_240"]
# stocks = ["OTC"]
cfg_fname = r"./config/config.json"

stk_data = getStockData(stk_api, stocks, "dataframe")
stk_list = getStockData(stk_api, stocks, "List")
writeRawData(stk_api, stk_list, cfg_fname)
writeLegalPersonDailyStockVolume(cfg_fname)
stk_df   = getStockDailyData(stk_list, cfg_fname, 250)

stk_df   = mergeDataFrame(stk_df, stk_data, cfg_fname)
# %%
stk_df = getStockSMA(stk_df, [5, 10, 20, 60])
stk_df = getStockBBands(stk_df, 10, 2) 
stk_df = getStockSAR(stk_df, 0.02, 0.2)
stk_df = getStockSAR(stk_df, 0.03, 0.3)
stk_df = getStockMaxMin(stk_df, [120, 240], ["max", "min"])
for k in keyindex:
    stk_df = getSignal(stk_df, k)

stk_df  = writeFinalData(stk_df, cfg_fname)









# stk_api.quote.set_callback(quote_callback)
# stk_api.quote.set_event_callback(event_callback)

# df
# a[["code", "name", "category"]]
# df = getStockticks(stk_api, "2330", "2021-07-15")

# subscribe tick data
# contract = stk_api.Contracts.Stocks["2330"]
# stk_api.quote.unsubscribe(contract, quote_type = sj.constant.QuoteType.Tick)

# stk_api.kbars?
# stk_api.ticks?





# mpf.plot(a, type = "candle")

# # %%
# # 匯入憑證
# # shiao_api.activate_ca(
# #     ca_path="/c/your/ca/path/Sinopac.pfx",
# #     ca_passwd="YOUR_CA_PASSWORD",
# #     person_id="Person of this Ca",
# # )

# %%

# %%

# %%