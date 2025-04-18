# %%
 
import pandas as pd
import random
import sys
import time
import os
import shioaji as sj
import threading
from shioaji import BidAskSTKv1, TickSTKv1, Exchange
from datetime import datetime, timedelta
from util.util import connect as con, file, strategy as stg, simulation as sim, tool
from util.Logger import create_logger
from scipy.stats import linregress

itemorder = []
itemdeal = []
ticks = []
bidasks = []
GorderDF = pd.DataFrame()
GdealDF = pd.DataFrame()
GtickDF = pd.DataFrame()
GbidaskDF = pd.DataFrame()
stgBuyDF = pd.DataFrame()
BuyDF = pd.DataFrame()
whDF = pd.DataFrame()
eventDF = pd.DataFrame()

def placeOrderCallBack(state: sj.constant.OrderState, msg: dict): 
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
    global GorderDF, GdealDF, GtickDF, GbidaskDF, itemorder, itemdeal, ticks
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
        col = ["StockID", "Action", "Price", "Qty", "OrderCond", "OrderLot","TradeDate", "TradeTime", "ReceiveTime"]
        GdealDF = GdealDF.append(pd.DataFrame(itemdeal, columns = col))
        dDF = dDF.append(pd.DataFrame(itemdeal, columns = col))
        itemdeal.clear()

        fpath = f"./data/ActuralTrade/deal_{ymdt}.xlsx"
        file.GeneratorFromDF(dDF, fpath)

    if ticks != []:
        col = ["StockID", "TradeTime", "Open", "Close", "High", "Low", "Volume"]
        GtickDF = GtickDF.append(pd.DataFrame(ticks, columns = col))
        ticks.clear()

    if bidasks != []:
        col = ["StockID", "TradeTime", "BidPrice_1", "BidPrice_2", "BidPrice_3", "BidPrice_4", "BidPrice_5", "BidVolume_1", "BidVolume_2", "BidVolume_3", "BidVolume_4", "BidVolume_5", "AskPrice_1", "AskPrice_2", "AskPrice_3", "AskPrice_4", "AskPrice_5", "AskVolume_1", "AskVolume_2", "AskVolume_3", "AskVolume_4", "AskVolume_5"]
        GbidaskDF = GbidaskDF.append(pd.DataFrame(bidasks, columns = col))
        bidasks.clear()

def buyStocksGenerate(maxNum):
    while maxNum > 0:
        yield maxNum
        maxNum -= 1

# 這個function是初期再對focus的股票再做一次低價的選選股
def decideRealBuyList(stgBuy:pd.DataFrame, price:float, Stk_num:int)->list:
    BuyIDs = []
    try:
        excludeID = tool.DFcolumnToList(pd.read_excel("./data/Exclude.xlsx"), "StockID")
        stgBuyDF = stgBuy[~stgBuy.StockID.isin(excludeID)]
    except:
        stgBuyDF = stgBuy
    # 產生一個連續數值的list, 2->[2,1] , 3->[3,2,1]....
    BuyDecide = buyStocksGenerate(Stk_num)
    for i in BuyDecide:
        try:
            BuyIDs = random.sample(tool.DFcolumnToList(stgBuyDF.loc[stgBuyDF.Open <= price], "StockID"), k = i)
            break
        except:
            continue
    return BuyIDs

def makeBuyAction(api:sj.Shioaji, buy:list, choose:list):
    for id in buy:
        # if id in choose:
        #     con(api).StockNormalBuySell(stkid = id, price = "up", qty = 1, action = "Buy")
        #     logger.info(f"Buy {id}(漲停)")
        #     continue
        con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Buy")
        logger.info(f"Buy {id}(跌停)")
    # 休息5秒,取得成交回報
    time.sleep(5)

# def calFocusStockTrend()->pd.DataFrame:
def calFocusStockTrend():
    global GtickDF
    getTrend = []
    try:        
        if not GtickDF.empty:
            bkTickDF = GtickDF.copy(deep = True).sort_values(by = ["StockID", "TradeTime"]) # deep = True 才不會改到原始的DF
            for stockid, oneStkDF in bkTickDF.groupby("StockID"):
                # oneStkDF.reset_index(inplace = True, drop = True)
                reg_up = linregress(x = oneStkDF.index, y = oneStkDF.Close.astype(float))
                up_line = reg_up.intercept + reg_up.slope * oneStkDF.index
        
                oneStkDFtmp = oneStkDF[oneStkDF.Close < up_line]
                feq = 0
                while len(oneStkDFtmp) >= 5 and feq < 50:
                    feq += 1
                    reg_new = linregress(x = oneStkDFtmp.index, y = oneStkDFtmp.Close.astype(float))
                    up_new = reg_new.intercept + reg_new.slope * oneStkDFtmp.index
                    oneStkDFtmp = oneStkDFtmp[oneStkDFtmp.Close < up_new]
                oneStkDF["Low_Trend"] = reg_new.intercept + reg_new.slope * oneStkDF.index
                if reg_up.slope >= 0:
                    val = "+"
                else:  
                    val = "-"  

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
                logger.info(f"Generate Trend File Down!")
    except Exception as exc:
        logger.error(f"Tick to DF error! {exc}")
        # return pd.DataFrame(getTrend, columns = ["StockID", "Trend"])


# 先檢查資料夾是否存在..沒有就建立
tool.checkCreateYearMonthPath()

pid = os.getpid() 
# 開始log
logger = create_logger("./logs")
logger.info(f"Start PID = {pid}")

check_secs = 20
# 1.連接Server,指定帳號(預設chris),使用的CA(預設None)
api = con().ServerConnectLogin(ca = "chris")


# api = con().ServerConnectLogin(simulte = True)
# 註:更換另一個帳號
# con(api).ChangeTradeCA(ca = "lydia")

# 1.1 設定回報Tick/Event資料
@api.on_tick_stk_v1()
def quote_callback(exchange: Exchange, tick:TickSTKv1):
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
def quote_callback(exchange: Exchange, bidask:BidAskSTKv1):
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


api.quote.set_event_callback(event_callback)
# 1.2 取得現有庫存
whList = tool.DFcolumnToList(con(api).getTreasuryStockDF(), "code")
# whList = ["00885", "1301", "1904", "2002", "2330", "2353", "2616", "2705", "2823", "2883", "3186", "3258", "3704"]

# 1.3 設定交易即時回報
api.set_order_callback(placeOrderCallBack)

# 2.依策略決定下單清單
stkDF = file().getLastFocusStockDF()
stkDF = stg(stkDF).getFromFocusOnByStrategy()
# 2.1 需要訂閱的股票清單
subList = tool.DFcolumnToList(stkDF, "StockID")
# 2.2 訂閱(Focus)
con(api).SubscribeTickBidAskByStockList(subList, "tick")

# 3.組合需要抓價量的Stocks(不能當沖的不放進來)
contracts = con(api).getContractForAPI(stkDF)


getBuyData = False  #判斷是否run過取BUY資料
stopcancel = False  #判斷是否run過取消買賣資料
secondrun = False
chkpoint = "09:05"
closepoint = "13:25"
cancelpoint = "10:" + str(random.choice(range(10, 30)))
# runtimes = 0
# 非開盤時間要修正檢查時間
if sim().checkSimulationTime():
    chkpoint = (datetime.now() + timedelta(minutes = 1)).strftime("%H:%M")
    cancelpoint = (datetime.now() + timedelta(minutes = 3)).strftime("%H:%M")
    closepoint = (datetime.now() + timedelta(minutes = 5)).strftime("%H:%M")

while True:
     
    # 把Deal/Order/Tick的call back資料寫到DF中
    callbackListDataToDF()

    # 取得每次的snapshot
    eachSnapDF = con(api).getSnapshotDataByStockIDs(contracts)
    # 09:05前就只要做snapshot
    if datetime.now().strftime("%H:%M") < chkpoint:
        tool.WaitingTimeDecide(check_secs)
        continue
    
    # 用開盤5min的snapshot決定買入
    if datetime.now().strftime("%H:%M") == chkpoint and not getBuyData:
        getBuyData = True
        # 計算趨勢線,寫入excel中
        # calFocusStockTrend()
 
        
        # 依買的策略產生Buy List
        stgBuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_01(eachSnapDF)
        BuyList = tool.DFcolumnToList(stgBuyDF, "StockID")
        # 選一筆<=60做漲停板(買的到),其他的部份跌停板(買不到)
        ManualBuyList = decideRealBuyList(stgBuyDF, 60, 2)
        # 下單
        makeBuyAction(api, BuyList, ManualBuyList)
        tool.WaitingTimeDecide(check_secs)
        continue
    
    # 時間到了,取消沒有成交的部份
    if datetime.now().strftime("%H:%M") == cancelpoint and not stopcancel:
        # 有買的就不cancel
        stopcancel = True
        cancellist = tool.DFcolumnToList(stgBuyDF[~stgBuyDF.StockID.isin(ManualBuyList)], "StockID")
        logger.info(f"cancel list: {cancellist}")
        for id in cancellist:
            con(api).StockCancelOrder(id)

   
    # 由庫存中找出己成交的股票
    newBuyDF = con(api).getTreasuryStockDF(exclude = whList)
    # 產生要賣的DF("StockID", "Buy", "UP", "DOWN")
    if not secondrun:
        BuyDF = stg(newBuyDF).genBuyWithSellPriceDF(gfile = True)
        secondrun = True
    else:
        if not BuyDF.empty: 
            BuyDF = stg(newBuyDF).rebuildBuyWithSellPriceDF(BuyDF, gfile = True)

   # 不是空值才需要往下檢查是否要賣出
    if not BuyDF.empty:
        # 盤中遇到價格>=買價的1% or 價格<=買價的2%(就做賣單: Sell + 跌停價)
        for idx, row in BuyDF.iterrows():
            nowprice = eachSnapDF[eachSnapDF.StockID == row.StockID].Close.values[0]
            if nowprice >= row.UP or nowprice <= row.DOWN:
                con(api).StockNormalBuySell(stkid = str(row.StockID), price = "down", qty = 1, action = "Sell")
                logger.info(f"Sell {row.StockID}")
                continue

        # # 收盤前5mins要清倉(Sell + 跌停價)
        if datetime.now().strftime("%H:%M") == closepoint:
            SellList = tool.DFcolumnToList(BuyDF, "StockID")
            for id in SellList:
                con(api).StockNormalBuySell(stkid = id, price = "down", qty = 1, action = "Sell")
                logger.info(f"Sell {row.StockID}")
            # 取消訂閱    
            con(api).UnsubscribeTickBidAskByStockList(subList, "bidask")
            break

    if datetime.now().strftime("%H:%M") >= closepoint:
        # 取消訂閱
        con(api).UnsubscribeTickBidAskByStockList(subList, "bidask")
        break

    tool.WaitingTimeDecide(check_secs)

ymd = datetime.now().strftime("%Y%m%d_%H%M%S")
path = f"./data/ActuralTrade/{ymd[0:6]}"
if not GorderDF.empty:
    fpath = f"{path}/order_{ymd}.xlsx"
    file.GeneratorFromDF(GorderDF, fpath)
    logger.info(f"Generate Order File Down!")
if not GdealDF.empty:
    fpath = f"{path}/deal_{ymd}.xlsx"
    file.GeneratorFromDF(GdealDF, fpath)
    logger.info(f"Generate Deal File Down!")
if not GtickDF.empty:
    fpath = f"{path}/tick_{ymd}.xlsx"
    file.GeneratorFromDF(GtickDF, fpath)
    logger.info(f"Generate Tick File Down!")
if not GbidaskDF.empty:
    fpath = f"{path}/bidask_{ymd}.xlsx"
    file.GeneratorFromDF(GbidaskDF, fpath)
    logger.info(f"Generate BidAsk File Down!")
logger.info("End")
