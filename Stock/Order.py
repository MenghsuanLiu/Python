# %%
import pandas as pd
import os
import shioaji as sj
from datetime import date, timedelta, datetime
from util import con, cfg, file


def getAttentionStockDF(cfg_file):
    FileLst = os.listdir(cfg.getConfigValue(cfg_file, "bkpath"))
    matching = []
    i = 0
    while True:
        # 算出最近有資料的那一天
        TradeDate = (date.today() - timedelta(days = i)).strftime("%Y%m%d")
        Fname = cfg.getConfigValue(cfg_file, "resultname") + f"_{TradeDate}.xlsx"
        Fmatch = [s for s in FileLst if Fname in s]
        i += 1
        if Fmatch !=[]:
            Ffullpath = cfg.getConfigValue(cfg_file, "bkpath") + "/" + cfg.getConfigValue(cfg_file, "resultname") + f"_{TradeDate}.xlsx"
            break

    stkDF = pd.read_excel(Ffullpath)
    # 邏輯: 前一交易日成交價 > 60MA & 10MA,且成交量 >= 5000張 
    stkDF = stkDF.loc[(stkDF.sgl_SMA > 0) & (stkDF.Volume >= 5000)]
    stkDF.StockID = stkDF.StockID.astype(str)
    return stkDF

def getListContractForAPIandLimitValue(api, StkDF):
    stkLst = StkDF.StockID.astype(str).tolist()
    Clst = []
    StkLimit = []
    for Sid in stkLst:
        Clst.append(api.Contracts.Stocks[Sid])
        StkLimit.append([Sid, api.Contracts.Stocks[Sid].limit_up, api.Contracts.Stocks[Sid].limit_down])
    if StkLimit != []:
        StkLimitDF = pd.DataFrame(StkLimit, columns = ["StockID", "LimitUP", "LimitDown"])
        StkDF = StkDF.merge(StkLimitDF, on = ["StockID"], how = "left")
    return Clst, StkDF

def get5minSnapshotOLHC(api, Contract, settime):
    while True:
        if datetime.now().strftime("%H:%M:%S") == settime:
            min5DF = pd.DataFrame(api.snapshots(Contract)).filter(items = ["code", "ts", "open", "high", "low", "close", "volume" ]).rename(columns = {"code": "StockID", "ts": "DateTime", "open": "Open", "high": "High", "low": "Low", "close": "5minClose", "volume": "Volume"})
            min5DF.DateTime = pd.to_datetime(min5DF.DateTime)
            min5DF["TradeDate"] = pd.to_datetime(min5DF.DateTime).dt.strftime("%Y%m%d")
            min5DF["TradeTime"] = pd.to_datetime(min5DF.DateTime).dt.time
            min5DF["SnapShotTime"] = datetime.now().strftime("%H:%M:%S")
            min5DF.StockID = min5DF.StockID.astype(str)
            return min5DF

def getBuyStockDF(FocusDF, SanpShotDF):
    MergeDF = FocusDF.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).merge(SanpShotDF.filter(items = ["StockID", "5minClose"]), on = ["StockID"], how = "left")

    # MergeDF["LimitUp"] = 
    

    # BuyDF = MergeDF.loc[]


    # CareStk["Buy"] = 0
    # CareStk["BuyTime"] = ""
    
    # CareStk.loc[(CareStk["5minClose"] < CareStk["lastClose"] * 1.05), "Buy"] = CareStk["5minClose"]
    # CareStk.loc[(CareStk["5minClose"] < CareStk["lastClose"] * 1.05), "BuyTime"] = datetime.now().strftime("%H:%M:%S")
    return




cfg_fname = "./config/config.json"

# 1.連接Server,指定帳號,同時active憑證
# api = con.connectToServer(cfg.getConfigValue(cfg_fname, "login"))
api = con.connectToSimServer()
# con.SetDefaultAccount(api, "S", "chris")
# con.InsertCAbyConfig(api,cfg.getConfigValue(cfg_fname, "ca"))
# %%
stkDF = getAttentionStockDF(cfg_fname)
# 組合需要每分鐘抓價量的Stocks,同時抓出各股的漲跌停
contracts, stkDF = getListContractForAPIandLimitValue(api, stkDF)
# 取得開盤後5min的OHLC的值(測試時需要建一個時間)
exetime = (datetime.now() + timedelta(minutes = 3)).strftime("%H:%M:%S")
# exetime = "09:05:00"
DF_SnapShot_5 = get5minSnapshotOLHC(api, contracts, exetime)
print("Get DF")
# %%


# %%
for id in ["2330", "2303"]:
    contract = api.Contracts.Stocks[id]
# contract = api.Contracts.Stocks["2330"]
    order = api.Order(
                price = contract.limit_up,
                quantity = 1,
                # {Buy, Sell}
                action = "Buy",
                # {LMT, MKT, MKP} (限價、市價、範圍市價)
                price_type = "LMT",
                # {ROD, IOC, FOK}
                order_type = "ROD",
                # {Cash, MarginTrading, ShortSelling} (現股、融資、融券)
                order_cond = "Cash",
                # {Common, Fixing, Odd, IntradayOdd} (整股、定盤、盤後零股、盤中零股)
                order_lot = "Common",
                # {true, false}
                first_sell = "true",

                account = api.stock_account
    )
    api.place_order(contract, order)
# %%
api.update_status()
api.list_trades()
# %%
# shioaji.order.Trade(
#     contract: shioaji.contracts.Contract,
#     order: shioaji.order.BaseOrder,
#     status: shioaji.order.OrderStatus,
# )
df_order = pd.DataFrame()
df_contract = pd.DataFrame()
df_status = pd.DataFrame()
for i in range(0,2):
#    df_order = df_order.append(pd.DataFrame({**api.list_trades()[i].order}))
#    df_contract = df_contract.append(pd.DataFrame({**api.list_trades()[i].contract}))
   df_status = df_status.append(pd.DataFrame({**api.list_trades()[i].status}))

# %%
# %%

api.list_trades()[0].status.order_datetime.strftime("%Y/%m/%d %H:%M:%S")
api.list_trades()[0].status.status_code
api.list_trades()[0].status.status.value
# PendingSubmit: 傳送中
# PreSubmitted: 預約單
# Submitted: 傳送成功
# Failed: 失敗
# Cancelled: 已刪除
# Filled: 完全成交
# Filling: 部分成交

api.list_trades()[0].contract.code




# %%
acct = []
i = 0
while True:    
    try:
        acct.append([api.list_accounts()[i].account_type.value, api.list_accounts()[i].person_id, api.list_accounts()[i].account_id, api.list_accounts()[i].username])
        i += 1
    except:
        break
acct = pd.DataFrame(acct, columns = ["Type", "ID", "AccountID", "Name"])
# %%
acct.loc[(acct.Type == "S") & (acct.ID == "J223372828")]
# %%
