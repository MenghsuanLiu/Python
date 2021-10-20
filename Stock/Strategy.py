# %%
from datetime import datetime, date, time
from util import con, file, stg, tool, db
import matplotlib.pyplot as plt
import mpl_finance as mpf
import pandas as pd

day = date.today().strftime("%Y%m%d")

stkDF = file().getLastFocusStockDF()
stkDF = stg(stkDF).SMA_SAR002_Volume_MAXMIN120()
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
    mpf.candlestick2_ochl(ax, gpDF['Open'], gpDF['Close'], gpDF['High'], gpDF['Low'], width=0.6, colorup='r', colordown='g', alpha=0.75)
    
# %%
