# %%
import pandas as pd
# from datetime import date, timedelta, datetime
from util import con, cfg, db

cfg_fname = "./config/config.json"

api = con.connectToServer(cfg.getConfigValue(cfg_fname, "login"))
mins_tb = cfg.getConfigValue(cfg_fname, "tb_mins")
day_tb = cfg.getConfigValue(cfg_fname, "tb_daily")
stock_tb = cfg.getConfigValue(cfg_fname, "tb_basic")


stocks = db.readDataFromDBtoDF(stock_tb, "")
stocks = stocks["StockID"].astype(str).to_list()
# %%
DFtoDBmin = pd.DataFrame()
for id in stocks:
    stkDF = pd.DataFrame({**api.kbars(api.Contracts.Stocks[id], start = "2020-01-01", end = "2020-06-30")})    
    stkDF["TradeDate"] = pd.to_datetime(stkDF.ts).dt.date
    stkDF = stkDF.sort_values(by = "ts")
    stkDF = stkDF.groupby("TradeDate", sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
    # stkDF["TradeDate"] = pd.to_datetime(stkDF.ts).apply(lambda x: x.strftime("%Y%m%d"))
    # stkDF["TradeTime"] = pd.to_datetime(stkDF.ts).dt.time
    stkDF.insert(0, "StockID", str(id))
    # 依時間排序
    # stkDF = stkDF.sort_values(by = "ts")
    stkDF = stkDF.sort_values(by = "TradeDate")
    # stkDF = stkDF.filter(items = ["StockID",  "TradeDate", "TradeTime", "Open", "High", "Low", "Close", "Volume"])
    stkDF = stkDF.filter(items = ["StockID",  "TradeDate", "Open", "High", "Low", "Close", "Volume"])
    # DFtoDBmin = DFtoDBmin.append(stkDF)
    # db.updateDataToDB(mins_tb, stkDF)
    db.updateDataToDB(day_tb, stkDF)

# %%
