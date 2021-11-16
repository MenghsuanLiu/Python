# %%
# 2021/11/05 測Order的資料接收
import pandas as pd
import random
import sys
import time
from shioaji import constant
from datetime import datetime
from util import connect as con, file, strategy as stg, tool

itemorder = []
itemdeal = []
GorderDF = pd.DataFrame()
GdealDF = pd.DataFrame()
BuyDF = pd.DataFrame()
def placeOrderCallBack(order_state: constant.OrderState, order: dict):
    # # 用global才可以告訴function要修改的是全域變數
    # global orderDF, dealDF

    if order_state == constant.OrderState.TFTOrder: 
        l = []
        l.append(order["contract"]["code"])
        l.append(order["order"]["action"])
        l.append(order["order"]["price"])
        l.append(order["order"]["quantity"])
        l.append(order["order"]["order_type"])
        l.append(order["order"]["price_type"])
        l.append(order["status"]["cancel_quantity"])
        l.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%Y%m%d"))
        l.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%H:%M:%S"))
        l.append(datetime.now().strftime("%H:%M:%S.%f"))
        itemorder.append(l)
        

    if order_state == constant.OrderState.TFTDeal:
        l = []
        # col = ["StockID", "Action", "Price", "Qty", "TradeDate", "TradeTime"]
        l.append(order["code"])
        l.append(order["action"]["value"])
        l.append(order["price"])
        l.append(order["quantity"])
        l.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%Y%m%d"))
        l.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%H:%M:%S"))
        l.append(datetime.now().strftime("%H:%M:%S.%f"))
        itemdeal.append(l)

def getNewBuyDFforGetDealOrder(api_in, buylist:list):
    outBuyDF = pd.DataFrame()
    outbuylist = []
    if GdealDF.empty:
        con(api_in).StockCancelOrder()
        sys.exit()
    for idx, row in GdealDF.iterrows():        
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
        
def ListToDF(item: list, func: str)->pd.DataFrame:
    if item == []:
        return pd.DataFrame()
    if func == "order":
        col = ["StockID", "Action", "Price", "Qty", "OrderType", "PriceType", "CancelQty", "TradeDate", "TradeTime", "ReceiveTime"]
    elif func == "deal":
        col = ["StockID", "Action", "Price", "Qty", "TradeDate", "TradeTime"]
    
    return pd.DataFrame(item, columns = col)
    

def callbackListDataToDF():
    global GorderDF, GdealDF, itemorder, itemdeal
    if itemorder != []:
        col = ["StockID", "Action", "Price", "Qty", "OrderType", "PriceType", "CancelQty", "TradeDate", "TradeTime", "ReceiveTime"]
        GorderDF = GorderDF.append(pd.DataFrame(itemorder, columns = col))
        itemorder.clear()

    if  itemdeal != []:
        col = ["StockID", "Action", "Price", "Qty", "TradeDate", "TradeTime", "ReceiveTime"]
        GdealDF = GdealDF.append(pd.DataFrame(itemdeal, columns = col))
        itemdeal.clear()
    
# orderDF = pd.DataFrame()
# dealDF = pd.DataFrame()
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

# 7.選一筆做漲停板(買的到),其他的部份跌停板(買不到)
chooseID = random.sample(BuyList, k = 1)

for id in BuyList:
    if id in chooseID:
        con(api).StockNormalBuySell(stkid = id, price = "up", qty = 1, action = "Buy")
        continue
    con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Buy")
# 8.休息5秒,取得成交回報
time.sleep(5)
callbackListDataToDF()
if not GorderDF.empty:
    file.GeneratorFromDF(GorderDF, "./data/ActuralTrade/test_global.xlsx")
tool.WaitingTimeDecide(check_secs)

for idx, row in GdealDF.iterrows():       
    if row.Action == "Buy":
        l = []
        l.append(row.StockID)
        l.append(row.Price)
        l.append(round(int(row.Price) * 1.01, 1))
        l.append(round(int(row.Price) * (1 - 0.02), 1))
        BuyDF = BuyDF.append([l], columns = ["StockID", "Buy", "UP", "DOWN"])
file.GeneratorFromDF(BuyDF, "./data/ActuralTrade/buy.xlsx")

# 8.檢查一下成交的狀況(沒有成交資訊...就先全部Cancel,離開程式)有成交就算出成交後賣的上下限價
# BuyDF = getNewBuyDFforGetDealOrder(api, BuyList)

canceltime = "10:" + str(random.choice(range(10, 60)))

ymd = datetime.now().strftime("%Y%m")
path = f"./data/ActuralTrade/{ymd}"
tool.checkPathExist(path)
if not BuyDF.empty:
    bkBuyDF = BuyDF.copy(deep = True)   # deep = True, copy才不會被改變原來的BuyDF

while True:
    callbackListDataToDF()
    # 取得現行報價
    SnapShot = con(api).getMinSnapshotData(contracts)

    if datetime.now().strftime("%H:%M") == canceltime:
        con(api).StockCancelOrder()
    
    # 不是空值才需要往下檢查是否要賣出
    if not BuyDF.empty:
        BuyDF = checkSoldStatusForBuyDF(bkBuyDF, GdealDF)

        # 盤中遇到價格>=買價的1% or 價格<=買價的2%(就做賣單: Sell + 跌停價)
        for idx, row in BuyDF.iterrows():
            nowprice = SnapShot[SnapShot.StockID == row.StockID].Close.values[0]
            if nowprice >= row.UP or nowprice <= row.DOWN:
                con(api).StockNormalBuySell(stkid = str(row.StockID), price = "down", qty = 1, action = "Sell")
                continue

        # # 收盤前5mins要清倉(Sell + 跌停價)
        if datetime.now().strftime("%H:%M") == "13:25":
            SellList = tool.DFcolumnToList(BuyDF, "StockID")
            for id in SellList:
                con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Sell")
            break  
    if datetime.now().strftime("%H:%M") >= "13:25":
        break

    tool.WaitingTimeDecide(check_secs)


ymd = datetime.now().strftime("%Y%m")
path = f"./data/ActuralTrade/{ymd}"
tool.checkPathExist(path)
ymd = datetime.now().strftime("%Y%m%d_%H%M%S")

if not GorderDF.empty:
    fpath = f"{path}/order_{ymd}.xlsx"
    file.GeneratorFromDF(GorderDF, fpath)
if not GdealDF.empty:
    fpath = f"{path}/deal_{ymd}.xlsx"
    file.GeneratorFromDF(GdealDF, fpath)







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
