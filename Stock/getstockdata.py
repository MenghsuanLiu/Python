# %%
import shioaji as sj
import pandas as pd
import talib
import os
import json
from datetime import date, timedelta, datetime

import numpy as np

import mplfinance as mpf


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
        
    return dataframe

def getStockData(api, stocks, datatype):
    df = []
    for s in stocks:
        df_market =[]
        if s == "TSE":
            market = api.Contracts.Stocks.TSE
        if s == "OTC":
            market = api.Contracts.Stocks.OTC
        if s == "OES":
            market = api.Contracts.Stocks.OES

        for id in market:
            df_market.append({**id})
        df_market = pd.DataFrame(df_market).filter(items = ["exchange", "code", "name", "category"])
        df_market["category"] = df_market["category"].str.strip()
        # df_market = df_market.loc[(df_market["category"] != "00") & (df_market["category"] != "")]
        df_market = df_market[~df_market["category"].isin(["00", ""])]

        if s == stocks[0]:
            df = df_market
        else:
            df = df.append(df_market)

    if datatype.lower() == "list":
        return df["code"].to_list()
    if datatype.lower() == "dataframe":    
        return df.reset_index()

def getStockDailyData(conn_api, Stklist):
    file = "./data/StockHistory.csv"
    writeRawData(conn_api, Stklist, file)
    df_history = pd.read_csv(file, low_memory = False)
    # for stockid in Stk_list:
    #     stock = api.Contracts.Stocks[stockid]
    #     stk_df = pd.DataFrame({**api.kbars(stock, start = d_range[0].strftime("%Y-%m-%d"), end = d_range[1].strftime("%Y-%m-%d"))})
    #     stk_df["ts_date"] = pd.to_datetime(stk_df.ts).dt.date
    #     stk_df = stk_df.groupby("ts_date", sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
    #     stk_df.insert(0, "StockID", stockid)
    #     if Stk_list[0] == stockid:
    #         df = stk_df
    #     else:
    #         df = df.append(stk_df)
    return df_history.reset_index()

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

def writeRawData(api, Stk_list, filepath):    
    file_exist = ""
    # # 建立目錄,不存在才建...
    # if os.path.exists(path) == False:
    #     os.makedirs(path)
    #檔案存在就把它抓出來變成dataframe        
    if os.path.isfile(filepath) == True:
        df_history = pd.read_csv(filepath, low_memory = False)
        df_history["StockID"] = df_history["StockID"].apply(str)
        file_exist = "X"        

    for id in Stk_list:
        d_range = [datetime.strptime(f"{date.today().year}-01-01", "%Y-%m-%d"), date.today() - timedelta(days = 10)]

        if file_exist == "X":
            his_df = df_history.loc[df_history["StockID"] == str(id)].sort_values(by = "ts_date")
            if not his_df.empty:
                d_range = [datetime.strptime(his_df["ts_date"].tail(1).values[0], "%Y-%m-%d") + timedelta(days = 1), date.today()]

        stock = api.Contracts.Stocks[id]
        stk_df = pd.DataFrame({**api.kbars(stock, start = d_range[0].strftime("%Y-%m-%d"), end = d_range[1].strftime("%Y-%m-%d"))})
        stk_df["ts_date"] = pd.to_datetime(stk_df.ts).dt.date
        stk_df = stk_df.groupby("ts_date", sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
        stk_df.insert(0, "StockID", str(id))
        if Stk_list[0] == id:
            df = stk_df
        else:
            df = df.append(stk_df)

    if file_exist == "X":
        df = df.append(df_history) 
    df["ts_date"] = pd.to_datetime(df["ts_date"], format = "%Y-%m-%d")
    df = df.sort_values(by = ["StockID", "ts_date"], ascending = True)
    df.to_csv(filepath, index = False)     
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
stocks = ["TSE", "OTC", "OES"]
# stocks = ["TSE"]
stk_list = getStockData(stk_api, stocks, "LIST")
stk_df = getStockDailyData(stk_api, stk_list)
# %%
stk_df = getStockSMA(stk_df, [5, 10, 20, 60])
stk_df = getStockBBands(stk_df, 10, 2) 
stk_df = getStockSAR(stk_df, 0.02, 0.2)
stk_df = getStockSAR(stk_df, 0.03, 0.3)
keyindex = ["SMA", "BBands", "SAR_002", "SAR_003"]
for k in keyindex:
    stk_df = getSignal(stk_df, k)


# %%
first = True
for stockid, gp_df in stk_df.groupby("StockID"):
    gp_df = gp_df.sort_values(by = "ts_date", ascending = False)
    gp_df =  gp_df.iloc[[0]].filter(items = (["StockID", "ts_date", "Close"] + [x for x in df.columns[df.columns.str.contains('sgl')]]))
    if first == True:
        df = gp_df
        first = False
    else:
        df = df.append(gp_df)
# df = df.reset_index()
df = df.loc[(df["sgl_SMA"] > 0) | (df["sgl_BBands"] > 0) | (df["sgl_SAR_002"] > 0) | (df["sgl_SAR_003"] > 0)]
df = df.sort_values(by = "StockID")




# stk_api.quote.unsubscribe(contract, quote_type=sj.constant.QuoteType.Tick)
# %%
# stk_api.quote.set_callback(quote_callback)
# stk_api.quote.set_event_callback(event_callback)
# %%
# df
# a[["code", "name", "category"]]
# df = getStockticks(stk_api, "2330", "2021-07-15")

# subscribe tick data
# contract = stk_api.Contracts.Stocks["2330"]
# stk_api.quote.unsubscribe(contract, quote_type = sj.constant.QuoteType.Tick)


# %%
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
