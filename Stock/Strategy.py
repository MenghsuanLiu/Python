# %%
from datetime import datetime, date, time

from numpy import TooHardError
from util import file, stg, tool, db, indicator as ind

import matplotlib.pyplot as plt

import pandas as pd
from plotly.offline import iplot, init_notebook_mode
import plotly.graph_objs as go

import talib

sql = "SELECT StockID, TradeDate, Open, High, Low, Close, Volume FROM dailyholc WHERE StockID in ('2330', '2303')"
stkdailyDF = db().selectDatatoDF(sql_statment = sql)
stkdailyDF = ind(stkdailyDF).addMFIvalueToDF()
# %%


stkdailyDF = ind(stkdailyDF).getSignalByIndicator(inds = ["MACD"])


stkdailyDF = ind(stkdailyDF).addMAvalueToDF()
stkdailyDF = ind(stkdailyDF).addSARvalueToDF(acc = 0.02, max = 0.2)   # Default acc = 0.02, max = 0.2
stkdailyDF = ind(stkdailyDF).addSARvalueToDF(acc = 0.03, max = 0.3)   # Default acc = 0.02, max = 0.2
stkdailyDF = ind(stkdailyDF).addBBANDvalueToDF()
stkdailyDF = ind(stkdailyDF).addMAXMINvalueToDF()
stkdailyDF = ind(stkdailyDF).getSignalByIndicator(inds = ["SMA", "SAR", "MAXMIN", "BBands"])

# %%
# init_notebook_mode()
# trace = go.Candlestick(x = stkdailyDF["TradeDate"],
#                        open = stkdailyDF.Open,
#                        high = stkdailyDF.High,
#                        low = stkdailyDF.Low,
#                        close = stkdailyDF.Close)
# data = [trace]
# iplot(data, filename='simple_candlestick')



stkdailyDF = ind(stkdailyDF).addKDvalueToDF(fk_perd = 5, s_perd = 3)

stkdailyDF = ind(stkdailyDF).addRSIvalueToDF(30)
stkdailyDF = ind(stkdailyDF).addMACDvalueToDF()
stkdailyDF = ind(stkdailyDF).addMAvalueToDF("SMA", [5, 20, 60])
stkdailyDF = ind(stkdailyDF).addRSIvalueToDF(5)
stkdailyDF = ind(stkdailyDF).addRSIvalueToDF(10)
# %%


day = date.today().strftime("%Y%m%d")

stkDF = file().getLastFocusStockDF()
stkDF = stg(stkDF).SMA_SAR_Volume_MAXMIN()
stkLst = tuple(tool.DFcolumnToList(stkDF, "StockID"))

sql = f"SELECT StockID, TIMESTAMP(TradeDate, TradeTime) as TradeTS, Open, High, Low, Close, Volume FROM dailyminsholc WHERE TradeDate = {day} AND StockID in {stkLst}"
# " AND TradeTime <= '09:10:00'"
minsDF = db().selectDatatoDF(sql_statment = sql) 

minsDF = minsDF.set_index("TradeTS").groupby("StockID").resample("5T", label = "right", closed = "right").agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()


# %%



for id, gpDF in minsDF.groupby("StockID"):
    print(id)
    gpDF["Time"] = pd.to_datetime(gpDF.TradeTS).dt.time
    # gpDF = gpDF.set_index("TradeTS").filter(items = ["Open", "High", "Low", "Close", "Volume"])
    gpDF = gpDF.set_index("Time").filter(items = ["Open", "High", "Low", "Close", "Volume"])
    fig = plt.figure(figsize=(24, 8))
    ax = fig.add_subplot(1, 1, 1)
    ax.set_xticks(range(0, len(gpDF.index), 5))
    ax.set_xticklabels(gpDF.index[::5])
    # mpf.candlestick2_ochl(ax, gpDF['Open'], gpDF['Close'], gpDF['High'], gpDF['Low'], width=0.6, colorup='r', colordown='g', alpha=0.75)
    
# %%
import pandas as pd

df = pd.read_excel(r"D:\GitHub\Python\Stock\data\ActuralTrade\tradeupdate_20211025.xlsx").drop_duplicates(subset = ["StockID", "Status"], keep = "first").reset_index(drop = True)
# %%
