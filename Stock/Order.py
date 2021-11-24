# %%
import pandas as pd
import random
import sys
import time
from shioaji import constant
from datetime import datetime, timedelta
from util.util import connect as con, file, strategy as stg, tool
from util.Logger import create_logger

itemorder = []
itemdeal = []
GorderDF = pd.DataFrame()
GdealDF = pd.DataFrame()
BuyDF = pd.DataFrame()
whDF = pd.DataFrame()
eventDF = pd.DataFrame()
def placeOrderCallBack(order_state: constant.OrderState, order: dict):
    # # 用global才可以告訴function要修改的是全域變數
    # global itemorder, itemdeal
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
    elif order_state == "TFTDEAL":
    # elif order_state == constant.OrderState.TFTDeal:
    # if order_state == constant.OrderState.TFTDeal:
        dl = []
        dl.append(order["code"])
        dl.append(order["action"]["value"])
        dl.append(order["price"])
        dl.append(order["quantity"])
        dl.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%Y%m%d"))
        dl.append(datetime.fromtimestamp(int(order["status"]["exchange_ts"])).strftime("%H:%M:%S"))
        dl.append(datetime.now().strftime("%H:%M:%S.%f"))
        itemdeal.append(dl)

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
    oDF = pd.DataFrame()
    dDF = pd.DataFrame()
    ymdt = datetime.now().strftime("%Y%m%d_%H%M%S")
    if itemorder != []:
        col = ["StockID", "Action", "Price", "Qty", "OrderType", "PriceType", "CancelQty", "TradeDate", "TradeTime", "ReceiveTime"]
        GorderDF = GorderDF.append(pd.DataFrame(itemorder, columns = col))
        oDF = oDF.append(pd.DataFrame(itemorder, columns = col))
        itemorder.clear()
               
        fpath = f"./data/ActuralTrade/order_{ymdt}.xlsx"
        file.GeneratorFromDF(oDF, fpath)

    if itemdeal != []:
        col = ["StockID", "Action", "Price", "Qty", "TradeDate", "TradeTime", "ReceiveTime"]
        GdealDF = GdealDF.append(pd.DataFrame(itemdeal, columns = col))
        dDF = dDF.append(pd.DataFrame(itemdeal, columns = col))
        itemdeal.clear()

        fpath = f"./data/ActuralTrade/deal_{ymdt}.xlsx"
        file.GeneratorFromDF(dDF, fpath)


# logger = create_logger("./logs")
# logger.info("Start")
# 先檢查資料夾是否存在..沒有就建立
tool.checkCreateYearMonthPath()

check_secs = 30
# 1.連接Server,指定帳號(預設chris),使用的CA(預設None)
api = con().ServerConnectLogin(ca = "chris")


@api.quote.on_event
def event_callback(resp_code: int, event_code: int, info: str, event: str):
    global eventDF
    l = []
    l.append(resp_code)
    l.append(event_code)
    l.append(info)
    l.append(event)
    l.append(datetime.now().strftime("%H:%M:%S.%f"))
    eventDF = eventDF.append(pd.DataFrame([l], columns = ["resp_code", "event_code", "info", "event", "ReceiveTime"]))
    # print(f'Event code: {event_code} | Event: {event} | Resp_Code: {resp_code} | info: {info}')

# api = con().ServerConnectLogin(simulte = True)
# 註:更換另一個帳號
# con(api).ChangeTradeCA(ca = "lydia")

# 2.設定成交即時回報
api.set_order_callback(placeOrderCallBack)

# 3.取得現有庫存
whList = tool.DFcolumnToList(con(api).getTreasuryStockDF(), "code")
# whList = ["00885", "1301", "1904", "2002", "2330", "2353", "2616", "2705", "2823", "2883", "3186", "3258", "3704"]


# 4.依策略決定下單清單
stkDF = file().getLastFocusStockDF()
stkDF = stg(stkDF).getFromFocusOnByStrategy()

# 5.組合需要抓價量的Stocks
contracts = con(api).getContractForAPI(stkDF)

# 5.取得開盤後5min的OHLC的值(測試時會自動立即run)
minSnapDF = con(api).getOpeningSnapshotData(contract = contracts, nmin_run = 5)

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

# 7.選一筆<=40做漲停板(買的到),其他的部份跌停板(買不到)
excludeID = tool.DFcolumnToList(pd.read_excel("./data/Exclude.xlsx"), "StockID")
stgBuyDF = stgBuyDF[~stgBuyDF.StockID.isin(excludeID)]
chooseID = []
for i in range(2, 0, -1):
    try:
        chooseID = random.sample(tool.DFcolumnToList(stgBuyDF.loc[stgBuyDF.Open <= 50], "StockID"), k = i)
    except:
        continue

for id in BuyList:
    if id in chooseID:
        con(api).StockNormalBuySell(stkid = id, price = "up", qty = 1, action = "Buy")
        continue
    con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Buy")
# 8.休息5秒,取得成交回報
time.sleep(5)
callbackListDataToDF()

tool.WaitingTimeDecide(check_secs)

# 處理成交的部份
if not GdealDF.empty:
    for idx, row in GdealDF.iterrows():       
        if row.Action == "Buy":
            l = []
            l.append(row.StockID)
            l.append(row.Price)
            l.append(round(row.Price * 1.01, 1))
            l.append(round(row.Price * (1 - 0.02), 1))
            BuyDF = BuyDF.append(pd.DataFrame([l], columns = ["StockID", "Buy", "UP", "DOWN"]))

    bkBuyDF = BuyDF.copy(deep = True)   # deep = True, copy才不會被改變原來的BuyDF
    file.GeneratorFromDF(BuyDF, "./data/ActuralTrade/Dealbuy.xlsx")

# 9.由庫存中找出己成交的股票
newBuyDF = con(api).getTreasuryStockDF(exclude = whList)

# 產生要賣的DF("StockID", "Buy", "UP", "DOWN")
BuyDF = stg(newBuyDF).genBuyWithSellPriceDF(gfile = True)

# BuyDF = getNewBuyDFforGetDealOrder(api, BuyList)...這由Deal產生...要再研究

canceltime = "10:" + str(random.choice(range(10, 30)))

# stopget = False
while True:
    callbackListDataToDF()
    # 取得現行報價
    SnapShot = con(api).getMinSnapshotData(contracts)

    if datetime.now().strftime("%H:%M") == canceltime:
        # 有買的就不cancel
        cancellist = tool.DFcolumnToList(stgBuyDF[~stgBuyDF.StockID.isin(chooseID)], "StockID")
        for id in cancellist:
            con(api).StockCancelOrder(id)
    # 當stopget==True時,就不跑下面的程式
    # if not stopget:
    newBuyDF = con(api).getTreasuryStockDF(exclude = whList)
    BuyDF = stg(newBuyDF).rebuildBuyWithSellPriceDF(BuyDF, gfile = True)
    # stopget, BuyDF = stg(newBuyDF).rebuildBuyWithSellPriceDF(BuyDF, gfile = True)

    # 不是空值才需要往下檢查是否要賣出
    if not BuyDF.empty:
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



ymd = datetime.now().strftime("%Y%m%d_%H%M%S")
path = f"./data/ActuralTrade/{ymd[0:6]}"
if not GorderDF.empty:
    fpath = f"{path}/order_{ymd}.xlsx"
    file.GeneratorFromDF(GorderDF, fpath)
if not GdealDF.empty:
    fpath = f"{path}/deal_{ymd}.xlsx"
    file.GeneratorFromDF(GdealDF, fpath)
if not eventDF.empty:
    fpath = f"{path}/event_{ymd}.xlsx"
    file.GeneratorFromDF(eventDF, fpath)






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
