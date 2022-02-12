# %%
 
import pandas as pd
import random
import sys
import time
import os
import shioaji as sj
from shioaji import BidAskSTKv1, TickSTKv1, Exchange
from datetime import datetime, timedelta
from util.util import connect as con, file, strategy as stg, simulation as sim, tool, mytime as tm, cfg
from util.Logger import create_logger

deal = pd.read_excel(".\data\ActuralTrade\deal_20220119_105520.xlsx")
GoperDF = pd.DataFrame(columns = ["StockID", "Price", "Up", "Down", "Qty", "BuyTime", "SellTime"])
l = []
for row in deal.iterrows():
    l.append(row[1]["StockID"])
    l.append(row[1]["Price"])
    l.append(round(row[1]["Price"] * 1.02,1))
    l.append(round(row[1]["Price"] * 0.98,1))
    l.append(row[1]["Qty"])
    l.append(row[1]["TradeTime"])
    l.append("")
    GoperDF = GoperDF.append(pd.DataFrame([l], columns = ["StockID", "Price", "Up", "Down", "Qty", "BuyTime", "SellTime"]))
    l.clear()
GoperDF = GoperDF.reset_index(drop = True)


# %%


itemorder = []
itemdeal = []
ticks = []
bidasks = []
GorderDF = pd.DataFrame()
GdealDF = pd.DataFrame()
GoperDF = pd.DataFrame(columns = ["StockID", "Price", "Up", "Down", "Qty", "BuyTime", "SellTime"])

GtickDF = pd.DataFrame()
GbidaskDF = pd.DataFrame()
stgBuyDF = pd.DataFrame()
BuyDF = pd.DataFrame()
whDF = pd.DataFrame()
eventDF = pd.DataFrame()

def placeOrderCallBack(state: sj.constant.OrderState, msg: dict): 
    global itemorder, itemdeal
    if state == sj.constant.OrderState.TFTDeal:
        l = []
        l.append(msg["code"])
        l.append(msg["action"])
        l.append(msg["price"])
        l.append(msg["quantity"])
        l.append(msg["order_cond"])
        l.append(msg["order_lot"])
        l.append(datetime.fromtimestamp(msg["ts"]).strftime("%Y%m%d"))
        l.append(datetime.fromtimestamp(msg["ts"]).strftime("%H:%M:%S"))
        l.append(datetime.now().strftime("%H:%M:%S.%f"))
        logger.info(f"get dealData: {msg}")
        itemdeal.append(l)
    elif state == sj.constant.OrderState.TFTOrder:
        # logger.info(f"get orderData: {msg}")
        l = []
        l.append(msg["contract"]["code"])
        l.append(msg["order"]["action"])
        l.append(msg["order"]["price"])
        l.append(msg["order"]["quantity"])
        l.append(msg["order"]["order_type"])
        l.append(msg["order"]["price_type"])
        l.append(msg["status"]["cancel_quantity"])
        l.append(datetime.fromtimestamp(int(msg["status"]["exchange_ts"])).strftime("%Y%m%d"))
        l.append(datetime.fromtimestamp(int(msg["status"]["exchange_ts"])).strftime("%H:%M:%S"))
        l.append(datetime.now().strftime("%H:%M:%S.%f"))
        itemorder.append(l)
    
def CallBackListToDF(last: bool = False) -> None:
    global GorderDF, GdealDF, GoperDF, itemdeal, itemorder

    oDF = pd.DataFrame()
    dDF = pd.DataFrame()
    ymdt = datetime.now().strftime("%Y%m%d_%H%M%S")
    file_path = cfg().getValueByConfigFile(key = "dailypath") + f"/{ymdt[0:6]}"

    if itemorder != []:
        col = ["StockID", "Action", "Price", "Qty", "OrderType", "PriceType", "CancelQty", "TradeDate", "TradeTime", "ReceiveTime"]
        GorderDF = GorderDF.append(pd.DataFrame(itemorder, columns = col))
        # 準備存成File用的DF
        oDF = oDF.append(pd.DataFrame(itemorder, columns = col))
        file.GeneratorFromDF(oDF, f"{file_path}/order_{ymdt}.xlsx")
        itemorder.clear()


    if itemdeal != []:

        col = ["StockID", "Action", "Price", "Qty", "OrderCond", "OrderLot","TradeDate", "TradeTime", "ReceiveTime"]
        GdealDF = GdealDF.append(pd.DataFrame(itemdeal, columns = col))
        # 準備存成File用的DF
        dDF = dDF.append(pd.DataFrame(itemdeal, columns = col))
        file.GeneratorFromDF(dDF, f"{file_path}/deal_{ymdt}.xlsx")
        itemdeal.clear()

        buyDF = pd.DataFrame()
        sellDF = pd.DataFrame()
        buyDF = dDF.loc[dDF.Action == "Buy"]
        sellDF = dDF.loc[dDF.Action == "Sell"]
        if not buyDF.empty:
            GoperDF = GoperDF.append(buyDF.filter(items = ["StockID", "Price", "Qty", "TradeTime"]))
        
    # 產生當天最後的結果檔案
    if last:
        if not GorderDF.empty:
            file.GeneratorFromDF(GorderDF, f"{file_path}/order_{ymdt[0:8]}.xlsx")
        if not GdealDF.empty:
            file.GeneratorFromDF(GdealDF, f"{file_path}/deal_{ymdt[0:8]}.xlsx")




# def getNewBuyDFforGetDealOrder(api_in, buylist:list):
#     outBuyDF = pd.DataFrame()
#     outbuylist = []
#     if GdealDF.empty:
#         con(api_in).StockCancelOrder()
#         sys.exit()
#     for idx, row in GdealDF.iterrows():        
#         if row.Action == "Buy":
#             l = []
#             outbuylist.append(row.StockID)
#             l.append(row.StockID)
#             l.append(row.Price)
#             l.append(round(int(row.Price) * 1.01, 1))
#             l.append(round(int(row.Price) * (1 - 0.02), 1))
#             outBuyDF = outBuyDF.append([l], columns = ["StockID", "Buy", "UP", "DOWN"])
#     diff = list(set(buylist).difference(outbuylist))
#     if diff != []:
#         for stkID in diff:
#             con(api_in).StockCancelOrder(stkID)
#     return outBuyDF

# def checkSoldStatusForBuyDF(buyDF: pd.DataFrame, cbDF: pd.DataFrame)->pd.DataFrame:
#     outBuyDF = pd.DataFrame()
#     for idx, row in buyDF.iterrows():
#         # 檢查沒有sell時就要留下這筆
#         if not ((cbDF.StockID == row.StockID) & (cbDF.Action == "Sell")).any():
#             outBuyDF = outBuyDF.append(row)
#     return outBuyDF 
        
# def ListToDF(item: list, func: str)->pd.DataFrame:
#     if item == []:
#         return pd.DataFrame()
#     if func == "order":
#         col = ["StockID", "Action", "Price", "Qty", "OrderType", "PriceType", "CancelQty", "TradeDate", "TradeTime", "ReceiveTime"]
#     elif func == "deal":
#         col = ["StockID", "Action", "Price", "Qty", "TradeDate", "TradeTime"]
    
#     return pd.DataFrame(item, columns = col)
    
# def callbackListDataToDF():
#     global GorderDF, GdealDF, GtickDF, GbidaskDF, itemorder, itemdeal, ticks
#     oDF = pd.DataFrame()
#     dDF = pd.DataFrame()
#     ymdt = datetime.now().strftime("%Y%m%d_%H%M%S")
#     if itemorder != []:
#         col = ["StockID", "Action", "Price", "Qty", "OrderType", "PriceType", "CancelQty", "TradeDate", "TradeTime", "ReceiveTime"]
#         GorderDF = GorderDF.append(pd.DataFrame(itemorder, columns = col))
#         oDF = oDF.append(pd.DataFrame(itemorder, columns = col))
#         itemorder.clear()
               
#         fpath = f"./data/ActuralTrade/order_{ymdt}.xlsx"
#         file.GeneratorFromDF(oDF, fpath)

#     if itemdeal != []:
#         col = ["StockID", "Action", "Price", "Qty", "OrderCond", "OrderLot","TradeDate", "TradeTime", "ReceiveTime"]
#         GdealDF = GdealDF.append(pd.DataFrame(itemdeal, columns = col))
#         dDF = dDF.append(pd.DataFrame(itemdeal, columns = col))
#         itemdeal.clear()

#         fpath = f"./data/ActuralTrade/deal_{ymdt}.xlsx"
#         file.GeneratorFromDF(dDF, fpath)

#     if ticks != []:
#         col = ["StockID", "TradeTime", "Open", "Close", "High", "Low", "Volume"]
#         GtickDF = GtickDF.append(pd.DataFrame(ticks, columns = col))
#         ticks.clear()

#     if bidasks != []:
#         col = ["StockID", "TradeTime", "BidPrice_1", "BidPrice_2", "BidPrice_3", "BidPrice_4", "BidPrice_5", "BidVolume_1", "BidVolume_2", "BidVolume_3", "BidVolume_4", "BidVolume_5", "AskPrice_1", "AskPrice_2", "AskPrice_3", "AskPrice_4", "AskPrice_5", "AskVolume_1", "AskVolume_2", "AskVolume_3", "AskVolume_4", "AskVolume_5"]
#         GbidaskDF = GbidaskDF.append(pd.DataFrame(bidasks, columns = col))
#         bidasks.clear()

# def buyStocksGenerate(maxNum):
#     while maxNum > 0:
#         yield maxNum
#         maxNum -= 1

# # 這個function是初期再對focus的股票再做一次低價的選選股
# def decideRealBuyList(stgBuy:pd.DataFrame, price:float, Stk_num:int)->list:
#     BuyIDs = []
#     try:
#         excludeID = tool.DFcolumnToList(pd.read_excel("./data/Exclude.xlsx"), "StockID")
#         stgBuyDF = stgBuy[~stgBuy.StockID.isin(excludeID)]
#     except:
#         stgBuyDF = stgBuy
#     # 產生一個連續數值的list, 2->[2,1] , 3->[3,2,1]....
#     BuyDecide = buyStocksGenerate(Stk_num)
#     for i in BuyDecide:
#         try:
#             BuyIDs = random.sample(tool.DFcolumnToList(stgBuyDF.loc[stgBuyDF.Open <= price], "StockID"), k = i)
#             break
#         except:
#             continue
#     return BuyIDs

# def makeBuyAction(api:sj.Shioaji, buy:list, choose:list):
#     for id in buy:
#         # if id in choose:
#         #     con(api).StockNormalBuySell(stkid = id, price = "up", qty = 1, action = "Buy")
#         #     logger.info(f"Buy {id}(漲停)")
#         #     continue
#         con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Buy")
#         logger.info(f"Buy {id}(跌停)")
#     # 休息5秒,取得成交回報
#     time.sleep(5)

if __name__ == "__main__":
    # 先檢查資料夾是否存在..沒有就建立
    tool.checkCreateYearMonthPath()

    # 開始log
    logger = create_logger("./logs")
    # 設定更新秒數
    wait_secs = 20


    # 1.連接Server,指定帳號(預設chris),使用的CA(預設None)
    api = con().ServerConnectLogin(ca = "chris")

    # 2.取得股票清單(只留下可以當沖的)
    stkDF = file.getPreviousTransactionFocusStockDF()
    stkLst = tool.DFcolumnToList(stkDF, "StockID")
    contracts = con(api).getContractForAPI(stkDF)

    # 3.訂閱/回報
    # 3.1 設定交易即時回報
    api.set_order_callback(placeOrderCallBack)
    # 3.2 設定回報資料(Tick / Bidask / Event)
    @api.on_tick_stk_v1()
    def quote_callback_tick(exchange: Exchange, tick:TickSTKv1):
        global ticks
        l = []
        l.append(tick.code)
        l.append(tick.datetime.strftime("%H:%M:%S.%f"))
        l.append(tick.open)
        # l.append(tick.avg_price)
        l.append(tick.close)
        l.append(tick.high)
        l.append(tick.low)
        # l.append(tick.amount)
        # l.append(tick.total_amount)
        l.append(tick.volume)
        # l.append(tick.total_volume)
        # l.append(tick.tick_type)
        # l.append(tick.chg_type)
        # l.append(tick.price_chg)
        # l.append(tick.ptc_chg)
        # l.append(tick.bid_side_total_vol)
        # l.append(tick.ask_side_total_vol)
        ticks.append(l)
        # logger.info(f"Exchange: {exchange}, Tick: {tick}")

    @api.on_bidask_stk_v1()
    def quote_callback_bidask(exchange: Exchange, bidask:BidAskSTKv1):
        global bidasks
        l = []
        l.append(bidask.code)
        l.append(bidask.datetime.strftime("%H:%M:%S.%f"))
        l.append(bidask.bid_price[0])
        l.append(bidask.bid_price[1])
        l.append(bidask.bid_price[2])
        l.append(bidask.bid_price[3])
        l.append(bidask.bid_price[4])
        l.append(bidask.bid_volume[0])
        l.append(bidask.bid_volume[1])
        l.append(bidask.bid_volume[2])
        l.append(bidask.bid_volume[3])
        l.append(bidask.bid_volume[4])
        l.append(bidask.ask_price[0])
        l.append(bidask.ask_price[1])
        l.append(bidask.ask_price[2])
        l.append(bidask.ask_price[3])
        l.append(bidask.ask_price[4])
        l.append(bidask.ask_volume[0])
        l.append(bidask.ask_volume[1])
        l.append(bidask.ask_volume[2])
        l.append(bidask.ask_volume[3])
        l.append(bidask.ask_volume[4])
        bidasks.append(l)
        # logger.info(f"Exchange: {exchange}, BidAsk: {bidask}")

    @api.quote.on_event
    def event_callback(resp_code: int, event_code: int, info: str, event: str):
        logger.info(f'Event code: {event_code} | Event: {event}')

    # 3.3 訂閱(Event)
    api.quote.set_event_callback(event_callback)    
    # 3.4 訂閱(Tick / Bidask)
    con(api).SubscribeTickBidAskByStockList(stkLst, "tick")
    # con(api).SubscribeTickBidAskByStockList(stkLst, "bidask")
    # con(api).SubscribeTickBidAskByStockList(stkLst)
    
    # 4.時間設定
    mkOrderTime = tm().getMakeOrderTime()
    cancelOrderTime = tm().getOrderCancelTime()
    closeTime = tm().getOrderCloseTime()

    # 5.進行買賣監控
    BuyFlag = False #判斷是否還要進入下單的部份
    CancelFlag = False #判斷是否還要進入下單的部份
    while True:
        # Deal/Order的call back資料寫到DF及檔案
        CallBackListToDF(last = False)
        # Get Snapshot
        eachSnapDF = con(api).getSnapshotDataByStockIDs(contracts)
        # 09:05前就只要做snapshot
        if datetime.now().strftime("%H:%M") < mkOrderTime:
            tool.WaitingTimeDecide(wait_secs)
            continue
        # 用開盤5min的snapshot決定買入
        if datetime.now().strftime("%H:%M") == mkOrderTime and not BuyFlag:
            BuyFlag = True
            # 依買的策略產生Buy List
            BuyList = stg(stkDF).getBuyStockListByStrategy(eachSnapDF)
            # 以零股現價下單
            for id in BuyList:
                con(api).StockNormalBuySell(stkid = id, price = "now", qty = 1, action = "Buy", lot = "IntradayOdd")
            tool.WaitingTimeDecide(wait_secs)
            continue
        # 時間到指定時間仍未成交部份取消
        if datetime.now().strftime("%H:%M") == cancelOrderTime and not CancelFlag:
            CancelFlag = True


        # 收盤後就取消訂閱的部份
        if datetime.now().strftime("%H:%M") >= closeTime:
            # 取消訂閱
            con(api).UnsubscribeTickBidAskByStockList(stkLst, "tick")
            break

        tool.WaitingTimeDecide(wait_secs)
    
    # 6.今天所有交易過程寫到File
    CallBackListToDF(last = True)
    # 7.結束
    logger.info("End")
# getBuyData = False  #判斷是否run過取BUY資料
# stopcancel = False  #判斷是否run過取消買賣資料
# secondrun = False

# while True:
     
#     # 把Deal/Order/Tick的call back資料寫到DF中
#     callbackListDataToDF()

#     # 取得每次的snapshot
#     eachSnapDF = con(api).getSnapshotDataByStockIDs(contracts)
#     # 09:05前就只要做snapshot
#     if datetime.now().strftime("%H:%M") < chkpoint:
#         tool.WaitingTimeDecide(check_secs)
#         continue
    
#     # 用開盤5min的snapshot決定買入
#     if datetime.now().strftime("%H:%M") == chkpoint and not getBuyData:
#         getBuyData = True
#         # 計算趨勢線,寫入excel中
#         # calFocusStockTrend()
 
        
#         # 依買的策略產生Buy List
#         stgBuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_01(eachSnapDF)
#         BuyList = tool.DFcolumnToList(stgBuyDF, "StockID")
#         # 選一筆<=60做漲停板(買的到),其他的部份跌停板(買不到)
#         ManualBuyList = decideRealBuyList(stgBuyDF, 60, 2)
#         # 下單
#         makeBuyAction(api, BuyList, ManualBuyList)
#         tool.WaitingTimeDecide(check_secs)
#         continue
    
#     # 時間到了,取消沒有成交的部份
#     if datetime.now().strftime("%H:%M") == cancelpoint and not stopcancel:
#         # 有買的就不cancel
#         stopcancel = True
#         cancellist = tool.DFcolumnToList(stgBuyDF[~stgBuyDF.StockID.isin(ManualBuyList)], "StockID")
#         logger.info(f"cancel list: {cancellist}")
#         for id in cancellist:
#             con(api).StockCancelOrder(id)

   
#     # 由庫存中找出己成交的股票
#     newBuyDF = con(api).getTreasuryStockDF(exclude = whList)
#     # 產生要賣的DF("StockID", "Buy", "UP", "DOWN")
#     if not secondrun:
#         BuyDF = stg(newBuyDF).genBuyWithSellPriceDF(gfile = True)
#         secondrun = True
#     else:
#         if not BuyDF.empty: 
#             BuyDF = stg(newBuyDF).rebuildBuyWithSellPriceDF(BuyDF, gfile = True)

#    # 不是空值才需要往下檢查是否要賣出
#     if not BuyDF.empty:
#         # 盤中遇到價格>=買價的1% or 價格<=買價的2%(就做賣單: Sell + 跌停價)
#         for idx, row in BuyDF.iterrows():
#             nowprice = eachSnapDF[eachSnapDF.StockID == row.StockID].Close.values[0]
#             if nowprice >= row.UP or nowprice <= row.DOWN:
#                 con(api).StockNormalBuySell(stkid = str(row.StockID), price = "down", qty = 1, action = "Sell")
#                 logger.info(f"Sell {row.StockID}")
#                 continue

#         # # 收盤前5mins要清倉(Sell + 跌停價)
#         if datetime.now().strftime("%H:%M") == closepoint:
#             SellList = tool.DFcolumnToList(BuyDF, "StockID")
#             for id in SellList:
#                 con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Sell")
#                 logger.info(f"Sell {row.StockID}")
#             # 取消訂閱    
#             con(api).UnsubscribeTickBidAskByStockList(subList, "bidask")
#             break

#     if datetime.now().strftime("%H:%M") >= closepoint:
#         # 取消訂閱
#         con(api).UnsubscribeTickBidAskByStockList(subList, "bidask")
#         break

#     tool.WaitingTimeDecide(check_secs)

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
# if not GtickDF.empty:
#     fpath = f"{path}/tick_{ymd}.xlsx"
#     file.GeneratorFromDF(GtickDF, fpath)
#     logger.info(f"Generate Tick File Down!")
# if not GbidaskDF.empty:
#     fpath = f"{path}/bidask_{ymd}.xlsx"
#     file.GeneratorFromDF(GbidaskDF, fpath)
#     logger.info(f"Generate BidAsk File Down!")
# logger.info("End")

# %%
