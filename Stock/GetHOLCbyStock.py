# %%
import pandas as pd
# from datetime import date, timedelta, datetime
from util import con, cfg, db

cfg_fname = "./config/config.json"

api = con.connectToServer(cfg.getConfigValue(cfg_fname, "login"))
mins_tb = cfg.getConfigValue(cfg_fname, "tb_mins")
stock_tb = cfg.getConfigValue(cfg_fname, "tb_basic")


stocks = db.readDataFromDBtoDF(stock_tb, "")
stocks = stocks["StockID"].astype(str).to_list()
# %%
DFtoDBmin = pd.DataFrame()
for id in stocks:
    stkDF = pd.DataFrame({**api.kbars(api.Contracts.Stocks[id], start = "2021-01-01", end = "2021-08-19")})    
    stkDF["TradeDate"] = pd.to_datetime(stkDF.ts).apply(lambda x: x.strftime("%Y%m%d"))
    stkDF["TradeTime"] = pd.to_datetime(stkDF.ts).dt.time
    stkDF.insert(0, "StockID", str(id))
    # 依時間排序
    stkDF = stkDF.sort_values(by = "ts")
    stkDF = stkDF.filter(items = ["StockID",  "TradeDate", "TradeTime", "Open", "High", "Low", "Close", "Volume"])
    # DFtoDBmin = DFtoDBmin.append(stkDF)
    db.updateDataToDB(mins_tb, stkDF)
# %%    
db.updateDataToDB(mins_tb, DFtoDBmin)
# %%
