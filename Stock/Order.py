# %%
import pandas as pd
import random
from shioaji import constant
from datetime import datetime, date, time
from util import connect as con, file, strategy as stg, tool, db


odr = []
deal = []
def placeOrderCallBack(order_state: constant.OrderState, order: dict):
    itemorder = []
    itemdeal = []
    if order_state == constant.OrderState.TFTOrder: 
        itemorder.append(order["contract"]["code"])
        itemorder.append(order["order"]["action"])
        itemorder.append(order["order"]["price"])
        itemorder.append(order["order"]["quantity"])
        itemorder.append(order["order"]["order_type"])
        itemorder.append(order["order"]["price_type"])
        itemorder.append(order["status"]["cancel_quantity"])
        t_date = datetime.fromtimestamp(int(order["status"]["exchange_ts"])).date().strftime("%Y%m%d")
        t_time = datetime.fromtimestamp(int(order["status"]["exchange_ts"])).time().strftime("%H:%M:%S")
        itemorder.append(t_date)
        itemorder.append(t_time)
        odr.append(itemorder)

    if order_state == constant.OrderState.TFTDeal:
        itemdeal.append(order["code"])
        itemdeal.append(order["action"]["value"])
        itemdeal.append(order["price"])
        itemdeal.append(order["quantity"])        
        t_date = datetime.fromtimestamp(int(order["status"]["exchange_ts"])).date().strftime("%Y%m%d")
        t_time = datetime.fromtimestamp(int(order["status"]["exchange_ts"])).time().strftime("%H:%M:%S")
        itemdeal.append(t_date)
        itemdeal.append(t_time)
        deal.append(itemdeal)


check_secs = 30
# 1.連接Server,指定帳號,同時active憑證[不給參數就使用模擬環境]
# api = con().LoginToServerForStock()
api = con().LoginToServerForStock(simulate = False, ca_acct = "chris")
# 註:更換另一個帳號
# con(api).ChangeTreadAccount(ca_acct = "lydia")

# 2.設定成交即時回報
api.set_order_callback(placeOrderCallBack)

# 3.依策略決定下單清單
stkDF_new = file().getLastFocusStockDF()
stkDF = pd.DataFrame()
stkDF = stg(stkDF_new).getFromFocusOnByStrategy()

# %%
# 4.組合需要抓價量的Stocks
contracts = con(api).getContractForAPI(stkDF)

# 5.取得開盤後5min的OHLC的值(測試時會自動立即run)
minSnapDF = con(api).getAfterOpenTimesSnapshotData(contract = contracts, nmin_run = 5)
# minSnapDF = con(api).getMinsSnapshotData(contract = contracts, start = 10)
try:
    db().updateDFtoDB(minSnapDF, tb_name = "tmpsnapshotdata")
except:
    pass

# 6.依買的策略產生Buy List
stgBuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_01(minSnapDF)
# stgBuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_03(minSnapDF)
BuyList = tool.DFcolumnToList(stgBuyDF, "StockID")

# 7.下單(測試時抓n個出來買就好)
# BuyList = random.choices(BuyList, k = random.choice(range(1,len(BuyList))))

for id in BuyList:
    con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Buy")
# %%
tool.WaitingTimeDecide(check_secs)

# 8.固定時間觀察訂單狀況,決定策略datetime.now()大約會在09:05
tims_bfcls = tool.calcuateFrequencyBetweenTwoTime(stime = datetime.now().strftime("%H:%M:%S"), etime = "13:25:00", feq = check_secs)
canceltime = random.choice(range(180, 250))
t = 0
trade_list = []
while True:
    t += 1
   
    if t == canceltime:
        con(api).StockCancelOrder()

    # 收盤前5mins要清倉
    if t == tims_bfcls:
        break    


    api.update_status(api.stock_account)
    for i in range(0, len(api.list_trades())):
        l = []
        l.append(api.list_trades()[i].contract.code)
        l.append(api.list_trades()[i].order.action.value)
        l.append(api.list_trades()[i].order.price)
        l.append(api.list_trades()[i].order.quantity)
        l.append(api.list_trades()[i].status.status_code)
        l.append(api.list_trades()[i].status.status.value)
        l.append(api.list_trades()[i].status.order_datetime.strftime("%Y/%m/%d"))
        l.append(api.list_trades()[i].status.order_datetime.strftime("%H:%M:%S"))
        l.append(datetime.today().strftime("%Y/%m/%d %H:%M:%S"))
        trade_list.append(l)
       
    # 休息時間
    tool.WaitingTimeDecide(check_secs)



ymd = datetime.now().strftime("%Y%m%d")
if trade_list != []:
    col = ["StockID", "Action", "OrderPrice", "OrderQty", "StatusCode", "Status", "TradeDate", "TradeTime", "DateTime"]
    tradesDF = pd.DataFrame(trade_list, columns = col).drop_duplicates(subset = ["StockID", "Status"], keep = "first").reset_index(drop = True)
    file.GeneratorFromDF(tradesDF, f"./data/ActuralTrade/tradeupdate_{ymd}.xlsx")

if odr != []:
    col = ["StockID", "Action", "Price", "Qty", "OrderType", "PriceType", "Cancel",  "TradeDate", "TradeTime"]
    orderDF = pd.DataFrame(odr, columns = col)
    file.GeneratorFromDF(orderDF, f"./data/ActuralTrade/order_{ymd}.xlsx")
    # orderDF["TradeDate"] = pd.to_datetime(orderDF.ts).apply(lambda x: x.strftime("%Y%m%d"))
    # orderDF["TradeTime"] = pd.to_datetime(orderDF.ts).dt.time
    # file.genFiles(cfg_fname, orderDF, f"./data/ActuralTrade/order_{ymd}.xlsx", "xlsx")

if deal != []:
    col = ["StockID", "Action", "Price", "Qty", "TradeDate", "TradeTime"]
    dealDF = pd.DataFrame(deal, columns = col)
    file.GeneratorFromDF(orderDF, f"./data/ActuralTrade/deal_{ymd}.xlsx")
    # dealDF["TradeDate"] = pd.to_datetime(dealDF.ts).apply(lambda x: x.strftime("%Y%m%d"))
    # dealDF["TradeTime"] = pd.to_datetime(dealDF.ts).dt.time
    # file.genFiles(cfg_fname, dealDF, f"./data/ActuralTrade/deal_{ymd}.xlsx", "xlsx")





# def getAttentionStockDF(cfg_file):
#     FileLst = os.listdir(cfg.getConfigValue(cfg_file, "dailypath"))
#     matching = []
#     i = 0
#     while True:
#         # 算出最近有資料的那一天
#         TradeDate = (date.today() - timedelta(days = i)).strftime("%Y%m%d")
#         Fname = cfg.getConfigValue(cfg_file, "resultname") + f"_{TradeDate}.xlsx"
#         Fmatch = [s for s in FileLst if Fname in s]
#         i += 1
#         if Fmatch !=[]:
#             Ffullpath = cfg.getConfigValue(cfg_file, "dailypath") + "/" + cfg.getConfigValue(cfg_file, "resultname") + f"_{TradeDate}.xlsx"
#             break
# 
#     stkDF = pd.read_excel(Ffullpath)
#     # 邏輯: 前一交易日成交價 > 60MA & 10MA,且成交量 >= 5000張 
#     stkDF = stkDF.loc[(stkDF.sgl_SMA > 0) & (stkDF.Volume >= 5000) & (stkDF.sgl_SAR_002 > 0)]
#     stkDF.StockID = stkDF.StockID.astype(str)
#     return stkDF
# 
# def getListContractForAPI(api, StkDF):
#     stkLst = StkDF.StockID.astype(str).tolist()
#     Clst = []
#     # StkLimit = []
#     for Sid in stkLst:
#         Clst.append(api.Contracts.Stocks[Sid])
#         # 下面這段是可以抓出個股的漲跌停
#         # StkLimit.append([Sid, api.Contracts.Stocks[Sid].limit_up, api.Contracts.Stocks[Sid].limit_down])
#     # if StkLimit != []:
#     #     StkLimitDF = pd.DataFrame(StkLimit, columns = ["StockID", "LimitUP", "LimitDown"])
#     #     StkDF = StkDF.merge(StkLimitDF, on = ["StockID"], how = "left")
#     return Clst
# 
# def get5minSnapshotOLHC(api, Contract, settime):
#     while True:
#         if datetime.now().strftime("%H:%M:%S") == settime:
#             min5DF = pd.DataFrame(api.snapshots(Contract)).filter(items = ["code", "ts", "open", "high", "low", "close", "volume" ]).rename(columns = {"code": "StockID", "ts": "DateTime", "open": "Open", "high": "High", "low": "Low", "close": "5minClose", "volume": "Volume"})
#             min5DF.DateTime = pd.to_datetime(min5DF.DateTime)
#             min5DF["TradeDate"] = pd.to_datetime(min5DF.DateTime).dt.strftime("%Y%m%d")
#             min5DF["TradeTime"] = pd.to_datetime(min5DF.DateTime).dt.time
#             min5DF["SnapShotTime"] = datetime.now().strftime("%H:%M:%S")
#             min5DF.StockID = min5DF.StockID.astype(str)
#             return min5DF
# 
# def getBuyStockDF(FocusDF, SanpShotDF):
#     BuyDF = pd.DataFrame()
#     HoldDF = pd.DataFrame()
#     MergeDF = FocusDF.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).merge(SanpShotDF.filter(items = ["StockID", "5minClose"]), on = ["StockID"], how = "left")
# 
#     MergeDF["BuyFlag"] = ""
#     MergeDF.loc[(MergeDF["5minClose"] < MergeDF["Close"] * 1.05), "BuyFlag"] = "X"
#     BuyDF = MergeDF.loc[MergeDF.BuyFlag == "X"]
#     HoldDF = MergeDF.loc[MergeDF.BuyFlag == ""]
#     return BuyDF, HoldDF
# 
# def normalStockBuy(api, stockid, buyprice, qty):
#     # Order參數說明  action{Buy, Sell}, price_type{LMT(限價), MKT(市價), MKP(範圍市價)} p.s MKT/MKP只能搭IOC, price = 0
#     #               order_type{ROD, IOC, FOK}, order_cond{Cash(現股), MarginTrading(融資), ShortSelling(融券)}
#     #               order_lot{Common(整股), Fixing(定盤), Odd(盤後零股), IntradayOdd(盤中零股)}
#     Ctract = api.Contracts.Stocks[stockid]
#     # 漲停
#     myotype = "ROD"
#     myptype = "LMT"
#     myprice = buyprice
#     if buyprice == "up":
#         myprice = Ctract.limit_up
#     # 跌停
#     if buyprice == "down":
#         myprice = Ctract.limit_down        
#     # 現價
#     if buyprice == "now":
#         myprice = 0
#         myotype = "IOC"
#         myptype = "MKT"   
#     order = api.Order(
#                     price = myprice, 
#                     quantity = qty, 
#                     action = "Buy", 
#                     price_type = myptype, 
#                     order_type = myotype,
#                     order_cond = "Cash",
#                     order_lot = "Common",                     
#                     account = api.stock_account
#                 )
#     api.place_order(Ctract, order)
#     return


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
# api.list_trades()[0].order.price
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


# %%
