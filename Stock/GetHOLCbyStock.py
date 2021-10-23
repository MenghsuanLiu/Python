# %%
from datetime import date, timedelta
import pandas as pd
# from datetime import date, timedelta, datetime
from util import con, cfg, db, tool

# day = date.today().strftime("%Y%m%d")
# minDF = db().selectDatatoDF(sql_statment = f"SELECT * FROM dailyminsholc WHERE TradeDate = {day}")




day = date.today().strftime("%Y-%m-%d")
# day = "2021-10-15"
api = con().LoginToServerForStock(simulate = False)
tb = cfg().getValueByConfigFile(key = "tb_mins")
# %%

stock_lst = tool.DFcolumnToList(db().selectDatatoDF(cfg().getValueByConfigFile(key = "tb_basic")), colname = "StockID")

DFtoDBmin = pd.DataFrame()
for id in stock_lst:
    stkDF = con(api).getKarData(stkid = id, sdate = day, edate = day)
    stkDF = stkDF.filter(items = ["StockID",  "TradeDate", "TradeTime", "Open", "High", "Low", "Close", "Volume"])
    print(id)
    
    db().updateDFtoDB(stkDF, tb_name = tb)


# %%
