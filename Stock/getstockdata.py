# %%
import pandas as pd
import requests as req
import talib
import os
import time
from datetime import date, timedelta, datetime
from bs4 import BeautifulSoup as bs
from util import connect as con
from util import config as cfg


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
def getStockData(api, stocks):
    # api.Contracts.Stocks資料結構
    ## [exchange(市場), code(代碼), symbol(市場+代碼), name(公司名), category(產業分類), unit(1張1000股), limit_up(前一交易日漲停價), limit_down(前一交易日跌停價), reference(前一交易日收盤價), update_date(更新日)]
    df = []
    for s in stocks:
        df_market =[]
        i = 0
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
        # df_market = df_market[( df_market["limit_up"] + df_market["limit_down"] ) / 2 >= 20]
        df_market = df_market[df_market["reference"] >= 20]


        while True:
            date_check = (date.today() - timedelta(days = i)).strftime("%Y/%m/%d")
            df_check = df_market[df_market["update_date"] == date_check]
            i += 1
            if not df_check.empty:
                df_market = df_check
                break
    
        if s == stocks[0]:
            df = df_market
        else:
            df = df.append(df_market)
    
    df = df.filter(items = ["code", "name", "exchange", "category", "update_date"]).rename(columns = {"code": "StockID", "name": "StockName", "exchange": "上市/上櫃"}).replace({"TSE": "上市", "OTC": "上櫃", "OES": "興櫃"})
    return df.reset_index(drop = True)

def getStockDailyData(StkDF, cfgname, days):
    stk_lst = StkDF["StockID"].to_list()
    fpath = cfg.getConfigValue(cfgname, "filepath")
    fpath = f"{fpath}/" + cfg.getConfigValue(cfgname, "hisname") + ".csv"
    # 讀取資料
    df_history = pd.read_csv(fpath, low_memory = False)
    # StockID由int轉str
    df_history["StockID"] = df_history["StockID"].apply(str)
    # 只留下這次要的Stock List
    df_history = df_history[df_history.StockID.isin(stk_lst)]
    # 轉換日期格式
    df_history["ts_date"] = pd.to_datetime(df_history["ts_date"], format = "%Y-%m-%d").dt.date

    # 只留下每個股票後250筆,要用後...後面算數SMA類的資料才會對
    first = True
    for stockid, gp_df in df_history.groupby("StockID"):
        # stk_up_date = StkDF[StkDF["StockID"] == stockid].update_date.values[0]
        gp_df = gp_df.sort_values(by = "ts_date", ascending = True)
        # 今天沒有交易資料就不要留這支
        # if gp_df["ts_date"].tail(1).values[0].strftime("%Y/%m/%d") != stk_up_date:
        #     continue
        gp_df = gp_df.tail(days)
        if first == True:
            df = gp_df
            first = False
        else:
            df = df.append(gp_df)

    return df.reset_index(drop = True)

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

def getStockMACD(dframe, day_list):
    first = True
    for stockid, gp_df in dframe.groupby("StockID"):
        for d in day_list:
            # 调用talib计算指数移动平均线的值
            gp_df[f"EMA{d}"] = talib.EMA(gp_df.Close, timeperiod = d)

        # 调用talib计算MACD指标
        gp_df["MACD"], gp_df["MACDsignal"], gp_df["MACDhist"] = talib.MACD(gp_df.Close, fastperiod = day_list[0], slowperiod = day_list[1], signalperiod = day_list[2])
        
        if first == True:
            df = gp_df
            first = False
        else:
            df = df.append(gp_df)     
    return df



def writeRawData(api, StkDF, cfgname):  
    Stk_list = StkDF["StockID"].to_list()
    file_exist = ""
    fpath = cfg.getConfigValue(cfgname, "filepath")
    bkpath = cfg.getConfigValue(cfgname, "bkpath")
    dypath = cfg.getConfigValue(cfgname, "dailypath")
    hisfile = f"{fpath}/" + cfg.getConfigValue(cfgname, "hisname") + ".csv"
    first = True
    # # 建立目錄,不存在才建...(./data)
    if os.path.exists(fpath) == False:
        os.makedirs(fpath)
    if os.path.exists(dypath) == False:
        os.makedirs(dypath)    
    #檔案存在就把它抓出來變成dataframe        
    if os.path.isfile(hisfile) == True:
        file_exist = "X"
        df_history = pd.read_csv(hisfile, low_memory = False)
        df_history["StockID"] = df_history["StockID"].apply(str)
        # 存一個DF是這次沒有要抓資料的
        df_notinlist = df_history[~df_history.StockID.isin(Stk_list)]
        # 這個DF是這次有用到的History Data
        df_history = df_history[df_history.StockID.isin(Stk_list)] 
        # 抓出History中的最後一個日期               
        df_tmp = df_history.sort_values(by = "ts_date", ascending = False)
        dfbk_date = (datetime.strptime(df_tmp["ts_date"].head(1).values[0], "%Y-%m-%d")).strftime("%Y%m%d")
    
    for id in Stk_list:        
        for i in range(0, 10):
            # 算出最近有資料的那一天
            data_date = date.today() - timedelta(days = i)
            stk_today = pd.DataFrame({**api.kbars(api.Contracts.Stocks[id], start = data_date.strftime("%Y-%m-%d"))})
            if not stk_today.empty:
                tmp_df = stk_today
                stk_today["ts_date"] = pd.to_datetime(stk_today.ts).dt.date
                stk_today["ts_time"] = pd.to_datetime(stk_today.ts).dt.time
                stk_today.insert(0, "StockID", str(id))
                stk_today = stk_today.sort_values(by = "ts")
                break
        # 資料日期的最後一天 = 備份資料的最後一天,就離開程式不用更新    
        if data_date.strftime("%Y%m%d") == dfbk_date:
            return
        
        # 約抓一年份的資料
        # d_range = [datetime.strptime(f"{date.today().year - 1}-01-01", "%Y-%m-%d"), date.today()]
        d_range = [data_date - timedelta(days = 400), data_date]

        if file_exist == "X":
            his_df = df_history.loc[df_history["StockID"] == str(id)].sort_values(by = "ts_date")
            if not his_df.empty:
                # 把Range的開始換成資料庫日期的最後一天 + 1
                d_range[0] = datetime.strptime(his_df["ts_date"].tail(1).values[0], "%Y-%m-%d") + timedelta(days = 1)
        
        # 資料庫最後日期 > 最近有資料日期=>表示資料有更新"最近有資料的那一天",就換下一個股票
        if d_range[0].strftime("%Y-%m-%d") > d_range[1].strftime("%Y-%m-%d"):
            continue
            
        # 資料庫最後日期 < 最近有資料日期 => 把今天抓的放進stk_df,其他的再補抓    
        if d_range[0].strftime("%Y-%m-%d") < d_range[1].strftime("%Y-%m-%d"):
            # 不要用d_range[1]..後面可能會有"同一天"的問題產生
            to_date = data_date - timedelta(days = 1)
            # 收集其他天的資料(遇到週一,stk_df會是空的) 
            stk_df = pd.DataFrame({**api.kbars(api.Contracts.Stocks[id], start = d_range[0].strftime("%Y-%m-%d"), end = to_date.strftime("%Y-%m-%d"))})
            # 把前面己經抓今天的資料放進來
            # df_tmp = stk_today.drop(columns = ["StockID", "ts_datetime"])
            if stk_df.empty:
                stk_df = tmp_df
            else:    
                stk_df = stk_df.append(tmp_df)

        # 資料庫最後日期 = 最近有資料日期 => 把抓到的今天資料放進來
        if d_range[0].strftime("%Y-%m-%d") == d_range[1].strftime("%Y-%m-%d"):
            stk_df = tmp_df
        # 轉換日期格式(Grouping使用)
        stk_df["ts_date"] = pd.to_datetime(stk_df.ts).dt.date
        stk_df = stk_df.sort_values(by = "ts")
        stk_df = stk_df.groupby("ts_date", sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
        stk_df.insert(0, "StockID", str(id))
        if first == True:
            df_new = stk_df
            df_today = stk_today
            first = False
        else:
            df_new = df_new.append(stk_df)
            df_today = df_today.append(stk_today)

    # 把歷史資料放進DF中
    if file_exist == "X":
        hisbkfile = f"{bkpath}/" + cfg.getConfigValue(cfgname, "hisname") + f"_to_{dfbk_date}.csv"
        df_history["ts_date"] = pd.to_datetime(df_history["ts_date"], format = "%Y-%m-%d").dt.date
        # 把沒有在StockList中的再寫回今天的DF
        if not df_notinlist.empty:
            df_notinlist["ts_date"] = pd.to_datetime(df_notinlist["ts_date"], format = "%Y-%m-%d").dt.date
            df_new = df_new.append(df_notinlist)    
        df_new = df_new.append(df_history)
        if os.path.exists(bkpath) == False:
            os.makedirs(bkpath)
        # 把原本的資料備存(太早備存有Bug就要一直搬回來)
        try:
            os.rename(hisfile, hisbkfile)
        except FileExistsError:
            os.remove(hisbkfile) 
            os.rename(hisfile, hisbkfile)
    
    # 累積的歷史資料
    df_new = df_new.sort_values(by = ["StockID", "ts_date"], ascending = True).reset_index(drop = True)
    df_new.to_csv(hisfile, index = False, encoding = "utf_8_sig")
    # 當天每分鐘的OHLC的資料
    data_date = data_date.strftime("%Y%m%d")
    df_today = df_today[["StockID", "ts_date", "ts_time", "Open", "High", "Low", "Close", "Volume", "ts"]]
    df_today = df_today.sort_values(by = ["StockID", "ts_date", "ts_time"]).reset_index(drop = True)
    df_today.to_csv(f"{dypath}/" + cfg.getConfigValue(cfgname, "kbarname") + f"_{data_date}.csv", index = False, encoding = "utf_8_sig")
    return

def mergeVolumeData(dframe, cfgname):
    # 找出這次資料的最後一筆日期
    df = dframe.sort_values(by = "ts_date", ascending = False)
    df_ymd = df["ts_date"].head(1).values[0].strftime("%Y%m%d")
    # 取出檔案清單,同時檢查需要的檔案是否存在
    dlypath = cfg.getConfigValue(cfgname, "dailypath")
    volfilename = cfg.getConfigValue(cfgname, "volname") + f"_{df_ymd}.csv"
    volfullpath = dlypath + "/" + volfilename
    file_list = sorted([s for s in os.listdir(dlypath) if cfg.getConfigValue(cfgname, "volname") in s], reverse = True)
    try:
        file_list.index(volfilename)
    except:
        writeLegalPersonDailyStockVolume(cfgname)
    vol_df = pd.read_csv(volfullpath, low_memory = False).filter(items = ["證券代號", "投信買賣超股數"]).rename(columns = {"證券代號": "StockID"})
    vol_df.insert(0, "ts_date", df["ts_date"].head(1).values[0])
    return dframe.merge(vol_df, on = ["StockID", "ts_date"], how = "left")

def writeResultData(dframe, cfgname):
    # 找出這次資料的最後一筆日期
    df = dframe.sort_values(by = "ts_date", ascending = False)
    df_ymd = df["ts_date"].head(1).values[0].strftime("%Y%m%d")
    resultfile = cfg.getConfigValue(cfgname, "filepath") + "/" + cfg.getConfigValue(cfgname, "resultname") + f"_{df_ymd}.xlsx"
    
    files = os.listdir(cfg.getConfigValue(cfgname, "filepath"))
    matching = [s for s in files if cfg.getConfigValue(cfgname, "resultname") in s]

    for file in matching:
        fmname = cfg.getConfigValue(cfgname, "filepath") + f"/{file}"
        toname = cfg.getConfigValue(cfgname, "bkpath") + f"/{file}"
        os.replace(fmname, toname)

    first = True
    for stockid, gp_df in dframe.groupby("StockID"):
        gp_df = gp_df.sort_values(by = "ts_date", ascending = False)
        gp_df = gp_df.iloc[[0]].filter(items = (["StockID", "StockName", "上市/上櫃", "ts_date", "Close", "Volume", "投信買賣超股數", ] + [x for x in gp_df.columns[gp_df.columns.str.contains("sgl")]]))

        if first == True:
            df = gp_df
            first = False
        else:
            df = df.append(gp_df)
    df.to_excel(resultfile, index = False)    
    return df


def getBSobj(YYYYMMDD, market, cfgname):
    head_info = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
    
    # 上市
    if market == "TSE":
        # 網頁取得自 https://www.twse.com.tw/zh/page/trading/fund/T86.html (列印 / HTML)
        # url = f"https://www.twse.com.tw/fund/T86?response=html&date={YYYYMMDD}&selectType=ALL"
        url = f"https://www.twse.com.tw/fund/T86?response=html&date={YYYYMMDD}&selectType=ALLBUT0999"
    # 上櫃
    if market == "OTC":
        # 網頁取得自 https://www.tpex.org.tw/web/stock/3insti/daily_trade/3itrade_hedge.php?l=zh-tw (列印/匯出HTML)
        ymd = f"{str(int(YYYYMMDD[0:4]) - 1911)}/{YYYYMMDD[4:6]}/{YYYYMMDD[6:8]}"
        url = f"https://www.tpex.org.tw/web/stock/3insti/daily_trade/3itrade_hedge_result.php?l=zh-tw&o=htm&se=EW&t=D&d={ymd}&s=0,asc"
    # 處理網址
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "utf-8"
    # 抓config檔決定是否要產生File
    genfile = cfg.getConfigValue(cfgname, "genhtml")

    # 判斷是否要產生File,不產生就直接把BS Obj傳出去
    if genfile != "":
        ## 寫網頁原始碼到檔案中cfg是config檔的路徑及檔名
        wpath = cfg.getConfigValue(cfgname, "webpath")
        # 產生出的檔案存下來
        ## 建立目錄,不存在才建...
        if os.path.exists(wpath) == False:
            os.makedirs(wpath)
        rootlxml = bs(urlwithhead.text, "lxml")
        with open(f"{wpath}/{market}_三大法人買賣超日報_{YYYYMMDD}.html", mode="w", encoding="UTF-8") as web_html:
            web_html.write(rootlxml.prettify())

    #傳出BeautifulSoup物件     
    return bs(urlwithhead.text, "lxml")

def getTBobj(bsobj, tbID, market, cfgname):
    tb = bsobj.find_all("table")[tbID]
    # 抓config檔決定是否要產生File
    genfile = cfg.getConfigValue(cfgname, "genhtml")
    # 判斷是否要產生File,不產生就直接把BS Obj傳出去
    if genfile != "":
        ## 寫網頁原始碼到檔案中cfg是config檔的路徑及檔名
        wpath = cfg.getConfigValue(cfgname, "webpath")
        # 產生出的檔案存下來
        ## 建立目錄,不存在才建...
        if os.path.exists(wpath) == False:
            os.makedirs(wpath)
        with open(f"{wpath}/{market}_table.html", mode="w", encoding="UTF-8") as web_html:
            web_html.write(tb.prettify())
    return tb

def getHeaderLine(tbObj):
    headtext = []
    for head in tbObj.select("table > thead > tr:nth-child(2) > td"):
        headtext.append(head.text)
    return headtext

def writeLegalPersonDailyStockVolume(marketlist, cfgname):
    fpath = cfg.getConfigValue(cfgname, "dailypath")
    if os.path.exists(fpath) == False:
        os.makedirs(fpath)

    day_check = False
    for mkt in marketlist:
        # 找出離今天最近日期有值的日期
        for i in range(0,10):
            ymd = (date.today() - timedelta(days = i)).strftime("%Y%m%d")
            try:
                TB_Obj = getTBobj(getBSobj(ymd, mkt, cfg), 0, mkt, cfg)
                break
            except:
                continue
        # 表示這次的loop還沒有檢查日期
        if day_check == False:
            # 找出現存的檔案最近的日期[File: DailyVolume_<YYYYMMDD>.csv]
            file_list = sorted([s for s in os.listdir(fpath) if cfg.getConfigValue(cfgname, "volname") in s], reverse = True)
            file_last_date = ((file_list[0].split("_"))[1].split("."))[0]
            if file_last_date == ymd:        
                return print(f"最近一個交易的檔案己存在!!({file_list[0]})")
            # 準備檔案名
            volfile = f"{fpath}/" + cfg.getConfigValue(cfgname, "volname") + f"_{ymd}.csv"
            day_check = True
        # 取得表頭(只用上市的表頭就好)
        if mkt == "TSE":
            ItemData = []
            Header = getHeaderLine(TB_Obj)
        # 取得Item
        for rows in TB_Obj.select("table > tbody > tr")[0:]:
            itemlist = []
            colnum = 0
            for col in rows.select("td"):
                colnum += 1
                if colnum in (1, 2):
                    val = col.string.strip()
                else:                
                    val = int(col.text.replace(",", "").strip())
                if mkt == "OTC" and colnum in [9, 10, 11, 21, 22]:
                    continue
                itemlist.append(val)
            if  mkt == "OTC":
                neworder = list(range(0,11)) + [17] + list(range(11,17)) + [18]
                itemlist = [itemlist[i] for i in neworder]   
            ItemData.append(itemlist)
    # 產生DataFrame
    df_vol = pd.DataFrame(ItemData, columns = Header).sort_values(by =  ["投信買賣超股數"], ascending = False)  
    df_vol.to_csv(volfile, index = False, encoding = "utf_8_sig")
    return




# 取得歷史tick資料


# def getStockticks(api, StockID, date_signal):
#     stock = api.Contracts.Stocks[StockID]
#     df_tick = pd.DataFrame({**api.ticks(stock, date_signal)})
#     df_tick.ts = pd.to_datetime(df_tick.ts)
#     return df_tick
    

# @sj.on_quote
# def quote_callback(topic, quote_msg):
#     print(topic, quote_msg)


# @sj.on_event
# def event_callback(resp_code, event_code, event):
#     print("Respone Code: {} | Event Code: {} | Event: {}".format(
#         resp_code, event_code, event))



markets = ["TSE", "OTC"]
keyindex = ["SMA", "BBands", "SAR_002", "SAR_003", "maxmin_120", "maxmin_240"]
# stocks = ["OTC"]
cfg_fname = "./config/config.json"

stk_api = con.connectToServer(cfg.getConfigValue(cfg_fname, "login"))
stk_info = getStockData(stk_api, markets)

writeRawData(stk_api, stk_info, cfg_fname)
writeLegalPersonDailyStockVolume(markets, cfg_fname)

# 取得每天的成交資料(後面數字是往回抓幾天)
stk_df = getStockDailyData(stk_info, cfg_fname, 250)

# 取得投信每日買賣超資料
stk_df = mergeVolumeData(stk_df, cfg_fname)
# 取得股票資訊
stk_df = stk_df.merge(stk_info, on = ["StockID"], how = "left")

# stk_df = getStockMACD(stk_df, [12, 26, 9])

stk_df = getStockSMA(stk_df, [5, 10, 20, 60])
stk_df = getStockBBands(stk_df, 10, 2) 
stk_df = getStockSAR(stk_df, 0.02, 0.2)
stk_df = getStockSAR(stk_df, 0.03, 0.3)
stk_df = getStockMaxMin(stk_df, [120, 240], ["max", "min"])

for k in keyindex:
    stk_df = getSignal(stk_df, k)

stk_df  = writeResultData(stk_df, cfg_fname)

if stk_df.StockID.count() != stk_info.StockID.count():
    print(f"觀察清單{stk_info.StockID.count()}和最後結果清單{stk_df.StockID.count()}筆數不一致!!!")




# %%

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
# stk_api = connectToServer()
# df = getStockticks(stk_api, "2330", "2021-08-06")
# df = df.filter(items = ["ts", "close"]).rename(columns = {"ts": "time", "close": "price"})
# # 設定資料以成交時間欄位為序列索引
# df = df.set_index("time")
# # 以 1 分鐘為單位，進行開高低收重新取樣
# df_1mink = df["price"].resample('1MIN').ohlc()
# df_5mink = df["price"].resample('5MIN').ohlc()
# df_1minkma = df["price"].rolling('1MIN').mean()
# df_5minkma = df["price"].rolling('5MIN').mean()

# %%
from datetime import date
date.today().strftime("%Y-%m-%d")
# %%
