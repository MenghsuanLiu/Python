# %%
import pandas as pd
import os
import time
# import shioaji as sj
from datetime import date, timedelta, datetime
from util import con, cfg, file

success = []
successDF = pd.DataFrame()
def getAttentionStockDF(cfg_file):
    FileLst = os.listdir(cfg.getConfigValue(cfg_file, "dailypath"))
    matching = []
    i = 0
    while True:
        # 算出最近有資料的那一天
        TradeDate = (date.today() - timedelta(days = i)).strftime("%Y%m%d")
        Fname = cfg.getConfigValue(cfg_file, "resultname") + f"_{TradeDate}.xlsx"
        Fmatch = [s for s in FileLst if Fname in s]
        i += 1
        if Fmatch !=[]:
            Ffullpath = cfg.getConfigValue(cfg_file, "dailypath") + "/" + cfg.getConfigValue(cfg_file, "resultname") + f"_{TradeDate}.xlsx"
            break

    stkDF = pd.read_excel(Ffullpath)
    # 邏輯: 前一交易日成交價 > 60MA & 10MA,且成交量 >= 5000張 
    stkDF = stkDF.loc[(stkDF.sgl_SMA > 0) & (stkDF.Volume >= 5000)]
    stkDF.StockID = stkDF.StockID.astype(str)
    return stkDF

def getListContractForAPI(api, StkDF):
    stkLst = StkDF.StockID.astype(str).tolist()
    Clst = []
    # StkLimit = []
    for Sid in stkLst:
        Clst.append(api.Contracts.Stocks[Sid])
        # 下面這段是可以抓出個股的漲跌停
        # StkLimit.append([Sid, api.Contracts.Stocks[Sid].limit_up, api.Contracts.Stocks[Sid].limit_down])
    # if StkLimit != []:
    #     StkLimitDF = pd.DataFrame(StkLimit, columns = ["StockID", "LimitUP", "LimitDown"])
    #     StkDF = StkDF.merge(StkLimitDF, on = ["StockID"], how = "left")
    return Clst

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
    BuyDF = pd.DataFrame()
    HoldDF = pd.DataFrame()
    MergeDF = FocusDF.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).merge(SanpShotDF.filter(items = ["StockID", "5minClose"]), on = ["StockID"], how = "left")

    MergeDF["BuyFlag"] = ""
    MergeDF.loc[(MergeDF["5minClose"] < MergeDF["Close"] * 1.05), "BuyFlag"] = "X"
    BuyDF = MergeDF.loc[MergeDF.BuyFlag == "X"]
    HoldDF = MergeDF.loc[MergeDF.BuyFlag == ""]
    return BuyDF, HoldDF

def normalStockBuy(api, stockid, buyprice, qty):
    # Order參數說明  action{Buy, Sell}, price_type{LMT(限價), MKT(市價), MKP(範圍市價)} p.s MKT/MKP只能搭IOC, price = 0
    #               order_type{ROD, IOC, FOK}, order_cond{Cash(現股), MarginTrading(融資), ShortSelling(融券)}
    #               order_lot{Common(整股), Fixing(定盤), Odd(盤後零股), IntradayOdd(盤中零股)}
    Ctract = api.Contracts.Stocks[stockid]
    # 漲停
    myotype = "ROD"
    myptype = "LMT"
    myprice = buyprice
    if buyprice == "up":
        myprice = Ctract.limit_up
    # 跌停
    if buyprice == "down":
        myprice = Ctract.limit_down        
    # 現價
    if buyprice == "now":
        myprice = 0
        myotype = "IOC"
        myptype = "MKT"   
    order = api.Order(
                    price = myprice, 
                    quantity = qty, 
                    action = "Buy", 
                    price_type = myptype, 
                    order_type = myotype,
                    order_cond = "Cash",
                    order_lot = "Common",                     
                    account = api.stock_account
                )
    api.place_order(Ctract, order)
    return

def placeOrderCallBack(stat, msg):
    success.append([stat])
    successDF.append(pd.DataFrame({**stat}))
    # print(stat, msg)





cfg_fname = "./config/config.json"

# 1.連接Server,指定帳號,同時active憑證
# api = con.connectToServer(cfg.getConfigValue(cfg_fname, "login"))
api = con.connectToSimServer()
# con.SetDefaultAccount(api, "S", "chris")
# con.InsertCAbyConfig(api,cfg.getConfigValue(cfg_fname, "ca"))

stkDF = getAttentionStockDF(cfg_fname)
# 組合需要抓價量的Stocks,同時抓出各股的漲跌停
# %%
contracts = getListContractForAPI(api, stkDF)
# 取得開盤後5min的OHLC的值(測試時需要建一個時間)
exetime = (datetime.now() + timedelta(minutes = 1)).strftime("%H:%M:%S")
# exetime = "09:05:00"
DF_SnapShot_5 = get5minSnapshotOLHC(api, contracts, exetime)


# 取得買及不買的資料
BuyDF, noBuyDF = getBuyStockDF(stkDF, DF_SnapShot_5)
# %%
# 如果買的資料不是空值,就做成List用漲停價買進
a = 0
if not BuyDF.empty:
    BuyLst = BuyDF.StockID.astype(str).tolist()
    for id in BuyLst:
        normalStockBuy(api, id, "up", 1)
        a += 1
        if a == 10:
            break
api.set_order_callback(placeOrderCallBack)
# %%
# 盤中9:00~13:30 => 270 mins
# for i in range(0, 531):
for i in range(0, 300):
    # 更新狀態
    api.update_status()
    

    time.sleep(30)
if success != []:
    df = pd.DataFrame(success)
    file.genFiles(cfg_fname, df, "./data/success_tmp.csv", "csv")

if not successDF.empty:
    file.genFiles(cfg_fname, successDF, "./data/successDF_tmp.csv", "csv")   
# # %%
# i = 0
# df_order = pd.DataFrame()
# # for i in range(0,2):
# while True:
# #    df_order = df_order.append(pd.DataFrame({**api.list_trades()[i].order}))
# #    df_contract = df_contract.append(pd.DataFrame({**api.list_trades()[i].contract}))
#     i += 1

#     try:
#         df_order = df_order.append(pd.DataFrame({**api.list_trades()[i].status}))
#     except:
#         break



        
# # %%
# # for id in ["2330", "2303"]:
# #     contract = api.Contracts.Stocks[id]
# # # contract = api.Contracts.Stocks["2330"]
# #     order = api.Order(
# #                 price = contract.limit_up,
# #                 quantity = 1,
# #                 # {Buy, Sell}
# #                 action = "Buy",
# #                 # {LMT, MKT, MKP} (限價、市價、範圍市價)
# #                 price_type = "LMT",
# #                 # {ROD, IOC, FOK}
# #                 order_type = "ROD",
# #                 # {Cash, MarginTrading, ShortSelling} (現股、融資、融券)
# #                 order_cond = "Cash",
# #                 # {Common, Fixing, Odd, IntradayOdd} (整股、定盤、盤後零股、盤中零股)
# #                 order_lot = "Common",
# #                 # {true, false}
# #                 first_sell = "true",

# #                 account = api.stock_account
# #     )
# #     api.place_order(contract, order)
# # %%
# api.update_status()
# api.list_trades()
# # %%
# # shioaji.order.Trade(
# #     contract: shioaji.contracts.Contract,
# #     order: shioaji.order.BaseOrder,
# #     status: shioaji.order.OrderStatus,
# # )
# df_order = pd.DataFrame()
# df_contract = pd.DataFrame()
# df_status = pd.DataFrame()
# for i in range(0,2):
# #    df_order = df_order.append(pd.DataFrame({**api.list_trades()[i].order}))
# #    df_contract = df_contract.append(pd.DataFrame({**api.list_trades()[i].contract}))
#    df_status = df_status.append(pd.DataFrame({**api.list_trades()[i].status}))

# # %%
# # %%

# api.list_trades()[0].status.order_datetime.strftime("%Y/%m/%d %H:%M:%S")
# api.list_trades()[0].status.status_code
# api.list_trades()[0].status.status.value
# # PendingSubmit: 傳送中
# # PreSubmitted: 預約單
# # Submitted: 傳送成功
# # Failed: 失敗
# # Cancelled: 已刪除
# # Filled: 完全成交
# # Filling: 部分成交

# api.list_trades()[0].contract.code


# # 庫存資料轉DF
# pd.DataFrame(api.list_positions(api.stock_account))