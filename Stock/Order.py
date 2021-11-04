# %%
# 2021/11/05 測Order的資料接收
import pandas as pd
import random
import sys
from shioaji import constant
from datetime import datetime
from util import connect as con, file, strategy as stg, tool

orderDF = pd.DataFrame()
dealDF = pd.DataFrame()

def placeOrderCallBack(order_state: constant.OrderState, order: dict):
    # 用global才可以告訴function要修改的是全域變數
    global orderDF, dealDF
    itemorder = []
    itemdeal = []
    if order_state == constant.OrderState.TFTOrder: 
        col = ["StockID", "Action", "Price", "Qty", "OrderType", "PriceType", "Cancel",  "TradeDate", "TradeTime"]
        itemorder.append(order["contract"]["code"])
        itemorder.append(order["order"]["action"])
        itemorder.append(order["order"]["price"])
        itemorder.append(order["order"]["quantity"])
        itemorder.append(order["order"]["order_type"])
        itemorder.append(order["order"]["price_type"])
        itemorder.append(order["status"]["cancel_quantity"])
        itemorder.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%Y%m%d"))
        itemorder.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%H:%M:%S"))
        orderDF = orderDF.append([itemorder], columns = col)

    if order_state == constant.OrderState.TFTDeal:
        col = ["StockID", "Action", "Price", "Qty", "TradeDate", "TradeTime"]
        itemdeal.append(order["code"])
        itemdeal.append(order["action"]["value"])
        itemdeal.append(order["price"])
        itemdeal.append(order["quantity"])
        itemdeal.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%Y%m%d"))
        itemdeal.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%H:%M:%S"))
        dealDF = dealDF.append([itemdeal], columns = col)

def getNewBuyDFforGetDealOrder(api_in, buylist:list):
    outBuyDF = pd.DataFrame()
    outbuylist = []
    if dealDF.empty:
        con(api_in).StockCancelOrder()
        sys.exit()
    for idx, row in dealDF.iterrows():        
        if row.Action == "Buy":
            l = []
            outbuylist.append(row.StockID)
            l.append(row.StockID)
            l.append(row.Price)
            l.append(round(int(row.Price) * 1.01, 1))
            l.append(round(int(row.Price) * (1 - 0.02), 1))
            outBuyDF = outBuyDF.append([l], columns = ["StockID", "Buy", "UP", "DOWN"])
    diff = list(set(buylist).difference(outbuylist))
    if diff != []:
        for stkID in diff:
            con(api_in).StockCancelOrder(stkID)
    return outBuyDF

def checkSoldStatusForBuyDF(buyDF: pd.DataFrame, cbDF: pd.DataFrame)->pd.DataFrame:
    outBuyDF = pd.DataFrame()
    for idx, row in buyDF.iterrows():
        # 檢查沒有sell時就要留下這筆
        if not ((cbDF.StockID == row.StockID) & (cbDF.Action == "Sell")).any():
            outBuyDF = outBuyDF.append(row)
    return outBuyDF 
        

check_secs = 30
# 1.連接Server,指定帳號,同時active憑證[不給參數就使用模擬環境]
# api = con().LoginToServerForStock()
api = con().LoginToServerForStock(simulate = False, ca_acct = "chris")
# 註:更換另一個帳號
# con(api).ChangeTreadAccount(ca_acct = "lydia")

# 2.設定成交即時回報
api.set_order_callback(placeOrderCallBack)

# 3.依策略決定下單清單
stkDF = file().getLastFocusStockDF()
stkDF = stg(stkDF).getFromFocusOnByStrategy()

# 4.組合需要抓價量的Stocks
contracts = con(api).getContractForAPI(stkDF)

# 5.取得開盤後5min的OHLC的值(測試時會自動立即run)
minSnapDF = con(api).getAfterOpenTimesSnapshotData(contract = contracts, nmin_run = 5)

# 6.依買的策略產生Buy List
stgBuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_01(minSnapDF)
# stgBuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_03(minSnapDF)
BuyList = tool.DFcolumnToList(stgBuyDF, "StockID")

# 7.下單--超過30就停止
# if len(BuyList) > 30:
#     sys.exit()
# random.sample不會抓重覆 random.choices會抓重覆
# BuyList = random.choices(BuyList, k = random.choice(range(1,len(BuyList))))
# if len(BuyList) > 10:
#     BuyList = random.sample(BuyList, k = 1)

for id in BuyList:
    con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Buy")

tool.WaitingTimeDecide(check_secs)
# 8.檢查一下成交的狀況(沒有成交資訊...就先全部Cancel,離開程式)有成交就算出成交後賣的上下限價
# BuyDF = getNewBuyDFforGetDealOrder(api, BuyList)

while True:
    # 取得現行報價
    SnapShot = con(api).getMinSnapshotData(contracts)

    if datetime.now().strftime("%H:%M") == "09:25":
        con(api).StockCancelOrder()
        continue

    # # 檢查回傳的資訊是否己經有賣出的(有賣出就不會再出現在BuyDF)
    # BuyDF = checkSoldStatusForBuyDF(BuyDF, dealDF)
    # # 若是空值,表示賣完了,就可以離開了
    # if BuyDF.empty:
    #     break

    # # 盤中遇到價格>=買價的1% or 價格<=買價的2%(就做賣單: Sell + 跌停價)
    # for idx, row in BuyDF.iterrows():
    #     nowprice = SnapShot[SnapShot.StockID == row.StockID].Close.values[0]
    #     if nowprice >= row.UP or nowprice <= row.DOWN:
    #         con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Sell")
    #         continue

    # # 收盤前5mins要清倉(Sell + 跌停價)
    if datetime.now().strftime("%H:%M") == "13:25":
    #     for id in tool.DFcolumnToList(BuyDF, "StockID"):
    #         con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Sell")
        break  
    
    tool.WaitingTimeDecide(check_secs)


ymd = datetime.now().strftime("%Y%m")
path = f"./data/ActuralTrade/{ymd}"
tool.checkPathExist(path)
ymd = datetime.now().strftime("%Y%m%d")

if not orderDF.empty:
    fpath = f"{path}/order_{ymd}.xlsx"
    file.GeneratorFromDF(orderDF, fpath)
if not dealDF.empty:
    fpath = f"{path}/deal_{ymd}.xlsx"
    file.GeneratorFromDF(dealDF, fpath)







# # 8.固定時間觀察訂單狀況,決定策略datetime.now()大約會在09:05
# tims_bfcls = tool.calcuateFrequencyBetweenTwoTime(stime = datetime.now().strftime("%H:%M:%S"), etime = "13:25:00", feq = check_secs)
# canceltime = random.choice(range(180, 250))
# t = 0
# trade_list = []
# while True:
#     t += 1
   
#     if t == canceltime:
#         con(api).StockCancelOrder()

#     # 收盤前5mins要清倉
#     if datetime.now().strftime("%H:%M") == "13:25":
        
#         break    


#     api.update_status(api.stock_account)
#     for i in range(0, len(api.list_trades())):
#         l = []
#         l.append(api.list_trades()[i].contract.code)
#         l.append(api.list_trades()[i].order.action.value)
#         l.append(api.list_trades()[i].order.price)
#         l.append(api.list_trades()[i].order.quantity)
#         l.append(api.list_trades()[i].status.status_code)
#         l.append(api.list_trades()[i].status.status.value)
#         l.append(api.list_trades()[i].status.order_datetime.strftime("%Y/%m/%d"))
#         l.append(api.list_trades()[i].status.order_datetime.strftime("%H:%M:%S"))
#         l.append(datetime.today().strftime("%Y/%m/%d %H:%M:%S"))
#         trade_list.append(l)
       
#     # 休息時間
#     tool.WaitingTimeDecide(check_secs)



# ymd = datetime.now().strftime("%Y%m%d")
# if trade_list != []:
#     col = ["StockID", "Action", "OrderPrice", "OrderQty", "StatusCode", "Status", "TradeDate", "TradeTime", "DateTime"]
#     tradesDF = pd.DataFrame(trade_list, columns = col).drop_duplicates(subset = ["StockID", "Status"], keep = "first").reset_index(drop = True)
#     file.GeneratorFromDF(tradesDF, f"./data/ActuralTrade/tradeupdate_{ymd}.xlsx")

# if odr != []:
#     col = ["StockID", "Action", "Price", "Qty", "OrderType", "PriceType", "Cancel",  "TradeDate", "TradeTime"]
#     orderDF = pd.DataFrame(odr, columns = col)
#     file.GeneratorFromDF(orderDF, f"./data/ActuralTrade/order_{ymd}.xlsx")

# if deal != []:
#     col = ["StockID", "Action", "Price", "Qty", "TradeDate", "TradeTime"]
#     dealDF = pd.DataFrame(deal, columns = col)
#     file.GeneratorFromDF(orderDF, f"./data/ActuralTrade/deal_{ymd}.xlsx")


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
