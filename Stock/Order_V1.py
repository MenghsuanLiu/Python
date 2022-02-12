# %%
from util.util import db, file
from scipy.stats import linregress
import pandas as pd
from datetime import datetime
import matplotlib.pyplot as plt

getTrend = []
sql = f"SELECT * FROM dailyticks WHERE Date(TradeDateTime) = 20211214 AND Time(TradeDateTime) <= '09:05:00'"
TicksDF = db().selectDatatoDF(sql_statment = sql).sort_values(by = ["StockID", "TradeDateTime"])

feq = 0
for stockid, oneStkDF in TicksDF.groupby("StockID"):
    oneStkDF.reset_index(inplace = True, drop = True)
    reg_up = linregress(x = oneStkDF.index, y = oneStkDF.Close)
    up_line = reg_up.intercept + reg_up.slope * oneStkDF.index
    # oneStkDF["Low_Trend"] = reg_up.intercept + reg_up.slope * oneStkDF.index
    # up_line = reg_up[1] + reg_up[0] * oneStkDF.index
    
    oneStkDFtmp = oneStkDF[oneStkDF.Close < up_line]
    feq = 0
    while len(oneStkDFtmp) >= 5 and feq < 50:
        feq += 1
        reg_new = linregress(x = oneStkDFtmp.index, y = oneStkDFtmp.Close)
        up_new = reg_new.intercept + reg_new.slope * oneStkDFtmp.index
        oneStkDFtmp = oneStkDFtmp[oneStkDFtmp.Close < up_new]
    oneStkDF["Low_Trend"] = reg_new.intercept + reg_new.slope * oneStkDF.index
    if reg_up.slope >= 0:
        val = "+"
    else:  
        val = "-"  
    oneStkDF.Close.plot()
    plt.plot(oneStkDF.Low_Trend)

    l = []
    l.append(str(stockid))
    l.append(str(val))
    l.append(float(reg_up.slope))
    l.append(float(reg_new.slope))
    getTrend.append(l)
TrendDF = pd.DataFrame(getTrend, columns = ["StockID", "Trend", "SlopeOrg", "SlopeNew"])
ymd = datetime.now().strftime("%Y%m%d")
path = f"./data/ActuralTrade/{ymd[0:6]}"
if not TrendDF.empty:
    fpath = f"{path}/Trend_{ymd}.xlsx"
    file.GeneratorFromDF(TrendDF, fpath)


# %%

# @api.quote.on_event
# def event_callback(resp_code: int, event_code: int, info: str, event: str):
#     global eventDF
#     l = []
#     l.append(resp_code)
#     l.append(event_code)
#     l.append(info)
#     l.append(event)
#     l.append(datetime.now().strftime("%H:%M:%S.%f"))
#     eventDF = eventDF.append(pd.DataFrame([l], columns = ["resp_code", "event_code", "info", "event", "ReceiveTime"]))
#     # print(f'Event code: {event_code} | Event: {event} | Resp_Code: {resp_code} | info: {info}')



# # 5.取得開盤後5min的OHLC的值(測試時會自動立即run)
# minSnapDF = con(api).getOpeningSnapshotData(contract = contracts, nmin_run = 5)

# # 6.依買的策略產生Buy List
# stgBuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_01(minSnapDF)

# # stgBuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_03(minSnapDF)
# BuyList = tool.DFcolumnToList(stgBuyDF, "StockID")

# # 7.下單--超過30就停止
# # if len(BuyList) > 30:
# #     sys.exit()
# # random.sample不會抓重覆 random.choices會抓重覆
# # BuyList = random.choices(BuyList, k = random.choice(range(1,len(BuyList))))
# # if len(BuyList) > 10:
# #     BuyList = random.sample(BuyList, k = 1)

# # 7.選一筆<=40做漲停板(買的到),其他的部份跌停板(買不到)
# chooseID = decideRealBuyList(stgBuyDF, 60)
# excludeID = tool.DFcolumnToList(pd.read_excel("./data/Exclude.xlsx"), "StockID")
# stgBuyDF = stgBuyDF[~stgBuyDF.StockID.isin(excludeID)]
# chooseID = []
# BuyDecide = buyStocksGenerate(2)
# for i in BuyDecide:
#     try:
#         chooseID = random.sample(tool.DFcolumnToList(stgBuyDF.loc[stgBuyDF.Open <= 60], "StockID"), k = i)
#         break
#     except:
#         continue

# for id in BuyList:
#     if id in chooseID:
#         con(api).StockNormalBuySell(stkid = id, price = "up", qty = 1, action = "Buy")
#         logger.info(f"Buy {id}(漲停)")
#         continue
#     con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Buy")
#     logger.info(f"Buy {id}(跌停)")
# # 8.休息5秒,取得成交回報
# time.sleep(5)
# callbackListDataToDF()

# tool.WaitingTimeDecide(check_secs)

# # 處理成交的部份
# # if not GdealDF.empty:
# #     dDF = pd.DataFrame()
# #     for idx, row in GdealDF.iterrows():       
# #         if row.Action == "Buy":
# #             l = []
# #             l.append(row.StockID)
# #             l.append(row.Price)
# #             l.append(round(row.Price * 1.01, 1))
# #             l.append(round(row.Price * (1 - 0.02), 1))
# #             dDF = dDF.append(pd.DataFrame([l], columns = ["StockID", "Buy", "UP", "DOWN"]))
# #     file.GeneratorFromDF(dDF, "./data/ActuralTrade/Dealbuy.xlsx")

# # 9.由庫存中找出己成交的股票
# newBuyDF = con(api).getTreasuryStockDF(exclude = whList)

# # 產生要賣的DF("StockID", "Buy", "UP", "DOWN")
# BuyDF = stg(newBuyDF).genBuyWithSellPriceDF(gfile = True)

# # BuyDF = getNewBuyDFforGetDealOrder(api, BuyList)...這由Deal產生...要再研究

# canceltime = "10:" + str(random.choice(range(10, 30)))

# stopcancel = False
# runtimes = 0
# while True:
#     runtimes += 1
#     if runtimes % 30 == 0:
#         ymd = datetime.now().strftime("%Y%m%d_%H%M%S")
#         fpath = f"./data/ActuralTrade/Tick_{ymd}.xlsx"
#         file.GeneratorFromDF(TickDF, fpath)
#         logger.info(f"Generate Tick File!{ymd}")


#     callbackListDataToDF()
#     # 取得現行報價
#     SnapShot = con(api).getSnapshotDataByStockID(contracts)

#     if datetime.now().strftime("%H:%M") == canceltime and not stopcancel:
#         # 有買的就不cancel
#         stopcancel = True
#         cancellist = tool.DFcolumnToList(stgBuyDF[~stgBuyDF.StockID.isin(chooseID)], "StockID")
#         logger.info(f"cancel list: {cancellist}")
#         for id in cancellist:
#             con(api).StockCancelOrder(id)
#     # 當stopget==True時,就不跑下面的程式
#     # if not stopget:
#     newBuyDF = con(api).getTreasuryStockDF(exclude = whList)
#     BuyDF = stg(newBuyDF).rebuildBuyWithSellPriceDF(BuyDF, gfile = True)
#     # stopget, BuyDF = stg(newBuyDF).rebuildBuyWithSellPriceDF(BuyDF, gfile = True)

#     # 不是空值才需要往下檢查是否要賣出
#     if not BuyDF.empty:
#         # 盤中遇到價格>=買價的1% or 價格<=買價的2%(就做賣單: Sell + 跌停價)
#         for idx, row in BuyDF.iterrows():
#             nowprice = SnapShot[SnapShot.StockID == row.StockID].Close.values[0]
#             if nowprice >= row.UP or nowprice <= row.DOWN:
#                 con(api).StockNormalBuySell(stkid = str(row.StockID), price = "down", qty = 1, action = "Sell")
#                 logger.info(f"Sell {row.StockID}")
#                 continue

#         # # 收盤前5mins要清倉(Sell + 跌停價)
#         if datetime.now().strftime("%H:%M") == "13:25":
#             SellList = tool.DFcolumnToList(BuyDF, "StockID")
#             for id in SellList:
#                 con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Sell")
#                 logger.info(f"Sell {row.StockID}")
#             break

#     if datetime.now().strftime("%H:%M") >= "13:25":
#         break

#     tool.WaitingTimeDecide(check_secs)

# # 取消訂閱
# con(api).UnsubscribeTickByStockList(subList)


# ymd = datetime.now().strftime("%Y%m%d_%H%M%S")
# path = f"./data/ActuralTrade/{ymd[0:6]}"
# if not GorderDF.empty:
#     fpath = f"{path}/order_{ymd}.xlsx"
#     file.GeneratorFromDF(GorderDF, fpath)
#     logger.info(f"Generate Order File Down!")
# if not GdealDF.empty:
#     fpath = f"{path}/deal_{ymd}.xlsx"
#     file.GeneratorFromDF(GdealDF, fpath)
#     logger.info(f"Generate Deal File Down!")
# if not eventDF.empty:
#     fpath = f"{path}/event_{ymd}.xlsx"
#     file.GeneratorFromDF(eventDF, fpath)
#     logger.info(f"Generate Event File Down!")

# logger.info("End")




# # 8.固定時間觀察訂單狀況,決定策略datetime.now()大約會在09:05
# tims_bfcls = tool.calculateFrequencyBetweenTwoTime(stime = datetime.now().strftime("%H:%M:%S"), etime = "13:25:00", feq = check_secs)
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
