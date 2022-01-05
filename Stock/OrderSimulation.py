# %%
import pandas as pd
import time
from datetime import date, datetime, timedelta
from shioaji import TickSTKv1, Exchange
from util.util import connect as con, cfg, file, strategy as stg, tool, db, indicator as ind, simulation as sim

def checkPriceToSell(invDF, min_data, last_flg):
    # 有庫存真實資料要換掉
    # 1.留下未賣出的,invDF只有買進的清單
    nosold_InvDF = invDF.loc[invDF["Sell"] == 0]
    # 2.己賣出的就不要再來做Join
    sold_InvDF = invDF.loc[invDF["Sell"] != 0]
    # 3.都賣完了就離開...
    if nosold_InvDF.empty:
        return sold_InvDF, "X"
    # 4.還沒賣的就和現價做join
    nosold_InvDF = nosold_InvDF.merge(min_data.filter(items = ["StockID", "Close"]), on = ["StockID"], how = "left")
    # 5.決定下賣出單的邏輯
    # 5.1 最後5分鐘就跌停價賣出(呈現最後收盤價)
    if last_flg == "X":
        nosold_InvDF["Sell"] = nosold_InvDF["Close"]
        nosold_InvDF["SellTime"] = datetime.now().strftime("%H:%M:%S")
        nosold_InvDF.loc[nosold_InvDF["Close"] > nosold_InvDF["Buy"], "Result"] = "+"
        nosold_InvDF.loc[nosold_InvDF["Close"] < nosold_InvDF["Buy"], "Result"] = "-"
    else:
    # 5.2 觀察這個時間點是否符合Buy + 1% / Buy - 2%
        nosold_InvDF.loc[(nosold_InvDF["Close"] > round(nosold_InvDF["Buy"] * 1.01, 1) ) | (nosold_InvDF["Close"] <= round(nosold_InvDF["Buy"] * (1 - 0.02), 1)), "Sell"] = nosold_InvDF["Close"]
        nosold_InvDF.loc[(nosold_InvDF["Close"] > round(nosold_InvDF["Buy"] * 1.01, 1) ) | (nosold_InvDF["Close"] <= round(nosold_InvDF["Buy"] * (1 - 0.02), 1)),  "SellTime"] = datetime.now().strftime("%H:%M:%S")
        nosold_InvDF.loc[nosold_InvDF["Close"] > round(nosold_InvDF["Buy"] * 1.01, 1), "Result"] = "+"
        nosold_InvDF.loc[nosold_InvDF["Close"] <= round(nosold_InvDF["Buy"] * (1 - 0.02), 1), "Result"] = "-"
    # 6.把不要的欄位Drop掉    
    out_InvDF = nosold_InvDF.drop(columns = ["Close"])
    # 7.檢查賣出清單是否不為空,和這次運算的部份Union
    if not sold_InvDF.empty:
        out_InvDF = pd.concat([out_InvDF, sold_InvDF])
    return out_InvDF.sort_values(by = ["StockID"]), ""

def getBuyTimeAndBuyPrice(BuyDF, SanpShotDF):
    if not BuyDF.empty:
        BuyResultDF = BuyDF.merge(SanpShotDF.filter(items = ["StockID", "Close"]).rename(columns = {"Close": "Buy"}), on = ["StockID"], how = "left")
        # BuyResultDF["BuyTime"] = datetime.now().apply(lambda x: x.strftime("%H:%M:%S"))
        BuyResultDF["BuyTime"] = datetime.now().strftime("%H:%M:%S")
        # 先把Sell的欄位加進來
        BuyResultDF["Sell"] = 0
        BuyResultDF["SellTime"] = ""
        BuyResultDF["Result"] = ""
    return BuyResultDF

def getTradeResultDF(CarestkDF, BuyDF, Strategy):
    TradeDF = CarestkDF.filter(items = ["StockID", "StockName", "上市/上櫃", "cateDesc", "Close"]).rename(columns = {"Close": "前一交易收盤", "cateDesc": "產業別" }).merge(BuyDF.filter(items = ["StockID", "Open", "Buy", "BuyTime", "Sell", "SellTime", "Result"]), on = ["StockID"], how = "left" )
    TradeDF["獲利狀況"] = TradeDF["Sell"] - TradeDF["Buy"]

    insertDF = TradeDF.filter(items = ["StockID", "前一交易收盤", "Open", "Buy", "BuyTime", "Sell", "SellTime", "獲利狀況"]).rename(columns = {"前一交易收盤": "LastClose", "獲利狀況": "Result"})
    insertDF.insert(0, "Strategy", str(Strategy))
    insertDF.insert(2, "TradeDate", date.today().strftime("%Y%m%d"))

    TradeDF.loc["Total"]= TradeDF.sum(numeric_only = True, axis = 0, skipna = True)
    try:
        db().updateDFtoDB(insertDF, tb_name = "dailysimulation")
    except:
        pass

    return TradeDF

def collectBuyOrderDataRule1(stkDF, min5_data):
    # 1.排序這5 mins的資料
    Stk_OHLC = min5_data.sort_values(by = ["StockID", "DateTime"]).reset_index()
    # 2.取得OHLC的值
    FocusLst = Stk_OHLC.groupby(by = ["StockID"], sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).rename(columns = {"Open": "5minOpen", "High": "5minHigh", "Low": "5minLow", "Close": "5minClose", "Volume": "5minVolume"})
    
    # 關注的股票(前一天篩的),只留ID及Close
    FocusLst = FocusLst.merge(stkDF.filter(items = ["StockID", "StockName", "Close"]).rename(columns = {"Close": "lastClose"}), on = ["StockID"], how = "left")

    FocusLst["Buy"] = 0
    FocusLst["BuyTime"] = ""
    # a.5min價 < 前一交易收盤價+5% b.5min價 > 開盤價(紅K) c.5min價>= 最高價*(1 - 0.01)
    FocusLst.loc[(FocusLst["5minClose"] < FocusLst["lastClose"] * 1.05) & (FocusLst["5minClose"] >= FocusLst["5minOpen"]) & (FocusLst["5minClose"] >= round(FocusLst["5minHigh"] * (1 - 0.01),1)), "Buy"] = FocusLst["5minClose"]
    FocusLst.loc[FocusLst.Buy != 0, "BuyTime"] = datetime.now().strftime("%H:%M:%S")
    return FocusLst.reset_index(drop = True)

def collectBuyOrderDataRule0(stkDF, min5_data):
    # 1.排序這5 mins的資料
    Stk_OHLC = min5_data.sort_values(by = ["StockID", "DateTime"]).reset_index()
    # 2.取得OHLC的值
    Stk_OHLC = Stk_OHLC.groupby(by = ["StockID"], sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum})
    # 關注的股票(前一天篩的),只留ID及Close
    CareStk = stkDF.filter(items = ["StockID", "StockName", "Close"]).rename(columns = {"Close": "lastClose"})    
    CareStk = CareStk.merge(Stk_OHLC.filter(items = ["StockID", "Close"]).rename(columns = {"Close": "5minClose"}), on = ["StockID"], how = "left")
    # 5分鐘只要低於前一交易日收盤的+5%以內,都列為買入對象
    CareStk["Buy"] = 0
    CareStk["BuyTime"] = ""
    
    CareStk.loc[(CareStk["5minClose"] < CareStk["lastClose"] * 1.05), "Buy"] = CareStk["5minClose"]
    CareStk.loc[(CareStk["5minClose"] < CareStk["lastClose"] * 1.05), "BuyTime"] = datetime.now().strftime("%H:%M:%S")

    return CareStk.reset_index(drop = True)
    
def getExcuteTime():
    extime = "09:05"
    if sim().checkSimulationTime():
        extime = (datetime.now() + timedelta(minutes = 2)).strftime("%H:%M")
    return extime


# 先檢查資料夾是否存在..沒有就建立
tool.checkCreateYearMonthPath()
ticks = []
ticksDF = pd.DataFrame()

chk_sec = 20

# 1.連接Server,指定帳號(預設chris),使用的CA(預設None)
api = con().ServerConnectLogin( user = "lydia")

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

# 2.依策略決定下單清單
stkDF_new = file().getLastFocusStockDF()
stkDF = stg(stkDF_new).getFromFocusOnByStrategy()
# 2.1 需要訂閱的股票清單
subList = tool.DFcolumnToList(stkDF, "StockID")
# 2.2 訂閱(Focus)
con(api).SubscribeTickBidAskByStockList(subList)


# 3.組合需要抓價量的Stocks
contracts = con(api).getContractForAPI(stkDF)

R0_BuyDF = pd.DataFrame()
R1_BuyDF = pd.DataFrame()
resultDF = pd.DataFrame()



while True:
    # 收集tick資料
    if ticks != []:
        ticksDF = ticksDF.append(pd.DataFrame(ticks, columns = ["StockID", "TradeTime", "Open", "Close", "High", "Low", "Volume"]))
        ticks.clear()
    # 收集snapshot資料
    secDF = con(api).getSnapshotDataByStockIDs(contracts)
    # 09:05前就只要做snapshot
    if datetime.now().strftime("%H:%M") < "09:05":
        tool.WaitingTimeDecide(chk_sec)
        continue
    
    ## 用開盤5min的snapshot決定買入
    if datetime.now().strftime("%H:%M") == "09:05" and R0_BuyDF.empty:
        # 依策略決定下單清單
        R0_BuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_01(secDF)
        R1_BuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_02(secDF)
        # 下單,取買價及時間(先用5min Close當買價)
        R0_BuyDF = getBuyTimeAndBuyPrice(R0_BuyDF, secDF)
        R1_BuyDF = getBuyTimeAndBuyPrice(R1_BuyDF, secDF)
        
        SlopeDF = tool.calculateTrendSlope(ticksDF)
        # 取消訂閱
        con(api).UnsubscribeTickBidAskByStockList(subList)

        tool.WaitingTimeDecide(chk_sec)
        continue

    ## 每30secs檢查
    R0_BuyDF, SoldOut = checkPriceToSell(R0_BuyDF, secDF, "")
    R1_BuyDF, SoldOut = checkPriceToSell(R1_BuyDF, secDF, "")
    if datetime.now().strftime("%H:%M") >= "13:25":
        R0_BuyDF, SoldOut = checkPriceToSell(R0_BuyDF, secDF, "X")
        R1_BuyDF, SoldOut = checkPriceToSell(R1_BuyDF, secDF, "X")
        break
    
    tool.WaitingTimeDecide(chk_sec)


R0_TradeDF = getTradeResultDF(stkDF, R0_BuyDF, "R0")
R1_TradeDF = getTradeResultDF(stkDF, R1_BuyDF, "R1")
R0_TradeDF = R0_TradeDF.merge(SlopeDF, on = ["StockID"], how = "left")
R1_TradeDF = R1_TradeDF.merge(SlopeDF, on = ["StockID"], how = "left")
# 準備存檔資料
ymd = date.today().strftime("%Y%m%d")
trade_path = cfg().getValueByConfigFile(key = "tradepath") + f"/{ymd[0:6]}"
# Rule0 / Rule1處理檔案的部份
file.GeneratorFromDF(R0_TradeDF, f"{trade_path}/Trade_{ymd}_R0.xlsx")
file.GeneratorFromDF(R1_TradeDF, f"{trade_path}/Trade_{ymd}_R1.xlsx")


# while True:
#     secDF = con(api).getSnapshotDataByStockID(contracts)
    
#     # 每分鐘存留一版secDF,做成minDF(0也要做一次)
#     if dotimes % 2 == 0:
#         minDF = minDF.append(secDF)
    
#     # 09:05前就只要做snapshot
#     if datetime.now().strftime("%H:%M") < "09:05":
#     # if datetime.now().strftime("%H:%M") < getExcuteTime():
#         dotimes += 1
#         tool.WaitingTimeDecide(chk_sec)
#         continue

#     # 原策略
#     ## 用開盤5min的snapshot決定買入
#     if datetime.now().strftime("%H:%M") == "09:05" and R0_BuyDF.empty:
#     # if datetime.now().strftime("%H:%M") == getExcuteTime() and R0_BuyDF.empty:
#         dotimes += 1
#         # 依策略決定下單清單
#         R0_BuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_01(secDF)
#         R1_BuyDF = stg(stkDF).BuyStrategyFromOpenSnapDF_02(secDF)
#         # 下單,取買價及時間(先用5min Close當買價)
#         R0_BuyDF = getBuyTimeAndBuyPrice(R0_BuyDF, secDF)
#         R1_BuyDF = getBuyTimeAndBuyPrice(R1_BuyDF, secDF)
#         tool.WaitingTimeDecide(chk_sec)
#         continue

 
#     ## 每30secs檢查
#     R0_BuyDF, SoldOut = checkPriceToSell(R0_BuyDF, secDF, "")
#     R1_BuyDF, SoldOut = checkPriceToSell(R1_BuyDF, secDF, "")

#     # RSI策略
#     # 9:13開始才要檢查RSI
#     if datetime.now().strftime("%H:%M") >= "09:13" and dotimes % 2 == 0:
#         minsSnapDF = minDF.sort_values(by = ["StockID", "DateTime"]).reset_index(drop = True)
#         wiIndDF = ind(minsSnapDF).addRSIvalueToDF(period = 12, cnam_noprd = True)
#         wiIndDF["Buy"] = 0
#         wiIndDF["Sell"] = 0
#         wiIndDF.loc[(wiIndDF.RSI <= 30) & (wiIndDF.RSI > 0), "Buy"] = wiIndDF.Close
#         wiIndDF.loc[(wiIndDF.RSI >= 70), "Sell"] = wiIndDF.Close
#         # 取每個的最新的一筆
#         wiIndDF = wiIndDF.groupby(by = ["StockID"]).tail(1).reset_index()
        
#         # 對每支Stock做檢查
#         for idx, row in wiIndDF.iterrows():
#             try:
#                 BuyFlg = recordDF[recordDF.StockID == row.StockID].BuyFlg.values[0]
#                 Freq = recordDF[recordDF.StockID == row.StockID].Freq.values[0]
#             except:  
#                 BuyFlg = ""
#                 Freq = 0

#             # 處理買進的部份(處理完要做下一筆)
#             if row.Buy > 0 and BuyFlg == "":
#                 l = []
#                 Freq += 1
#                 # 處理結果Buy的部份
#                 l.append(row.DateTime.strftime("%Y%m%d"))
#                 l.append(row.StockID)
#                 l.append(Freq)                    
#                 l.append(row.DateTime.strftime("%H:%M:%S"))
#                 l.append(row.Buy)
#                 l.append("00:00:00")
#                 l.append(0)
#                 # l只有一層,在產生DF時要再給一個[]
#                 resultDF = resultDF.append(pd.DataFrame([l], columns = ["TradeDate", "StockID", "Frequency","BuyTime", "Buy", "SellTime", "Sell"]))
#                 # 處理狀態的部份(先換有記錄的值,沒有再寫入)
                
#                 if Freq == 1:
#                     l = []
#                     l.append(row.StockID)
#                     l.append("X")
#                     l.append(Freq)
#                     recordDF = recordDF.append(pd.DataFrame([l], columns = ["StockID", "BuyFlg","Freq"]))
#                 else:
#                     recordDF.loc[recordDF.StockID == row.StockID, "BuyFlg"] = "X"
#                     recordDF.loc[recordDF.StockID == row.StockID, "Freq"] = Freq
#                 # try:
#                 #     rcdDF.loc[rcdDF.StockID == row.StockID, "BuyFlg"] = "X"
#                 #     rcdDF.loc[rcdDF.StockID == row.StockID, "Freq"] = Freq
#                 # except:
#                 #     l = []
#                 #     l.append(row.StockID)
#                 #     l.append("X")
#                 #     l.append(Freq)
#                 #     rcdDF = rcdDF.append(pd.DataFrame([l], columns = ["StockID", "BuyFlg","Freq"]))
#                 continue    # 換下一筆

#             # 處理賣出的部份(處理完要做下一筆,若收盤就跳出)
#             if BuyFlg == "X":
                
#                 if row.Sell > 0:
#                     resultDF.loc[(resultDF.StockID == row.StockID) & (resultDF.Frequency == Freq), "Sell"] = row.Sell
#                     resultDF.loc[(resultDF.StockID == row.StockID) & (resultDF.Frequency == Freq), "SellTime"] = row.DateTime.strftime("%H:%M:%S")

#                     recordDF.loc[recordDF.StockID == row.StockID, "BuyFlg"] = ""
#                     continue    # 換下一筆
#                 # 做收盤前的清倉
#                 if datetime.now().strftime("%H:%M") >= "13:25":
#                     # Freq  += 1
#                     resultDF.loc[(resultDF.StockID == row.StockID) & (resultDF.Frequency == Freq), "Sell"] = row.Close
#                     resultDF.loc[(resultDF.StockID == row.StockID) & (resultDF.Frequency == Freq), "SellTime"] = row.DateTime.strftime("%H:%M:%S")
    
#     if datetime.now().strftime("%H:%M") >= "13:25":
#         R0_BuyDF, SoldOut = checkPriceToSell(R0_BuyDF, secDF, "X")
#         R1_BuyDF, SoldOut = checkPriceToSell(R1_BuyDF, secDF, "X")
#         break
    
#     dotimes += 1
#     tool.WaitingTimeDecide(chk_sec)

# R0_TradeDF = getTradeResultDF(stkDF, R0_BuyDF, "R0")
# R1_TradeDF = getTradeResultDF(stkDF, R1_BuyDF, "R1")


# # 準備存檔資料
# ymd = date.today().strftime("%Y%m%d")
# trade_path = cfg().getValueByConfigFile(key = "tradepath") + f"/{ymd[0:6]}"
# tool.checkPathExist(trade_path)
# # Rule0 / Rule1處理檔案的部份
# file.GeneratorFromDF(R0_TradeDF, f"{trade_path}/Trade_{ymd}_R0.xlsx")
# file.GeneratorFromDF(R1_TradeDF, f"{trade_path}/Trade_{ymd}_R1.xlsx")
# # RSI處理檔案的部份
# resultDF["Profit"] = resultDF.Sell - resultDF.Buy
# file.GeneratorFromDF(resultDF, f"{trade_path}/RSI_onlinesim_{ymd}.xlsx")

# %%
# 每分鐘抓的SnapShot資料存到DB中
# todayDF = todayDF.sort_values(by = ["StockID", "DateTime", "SnapShotTime"])
# SnapDF = todayDF.filter( items = ["StockID", "TradeDate", "TradeTime", "SnapShotTime", "Open", "High", "Low", "Close", "Volume"])
# try:
#     SnapDF = SnapDF.groupby(["StockID", "TradeDate", "TradeTime", "SnapShotTime"], sort = True).agg({"Open": "first", "High": "first", "Low": "first", "Close": "first", "Volume": "first"}).reset_index()
#     db.updateDataToDB(cfg.getConfigValue(cfg_fname, "tb_snap"), SnapDF)
# except:
#     file.genFiles(cfg_fname, todayDF, newfile, "xlsx")


# SoldOut = ""
# R0InventoryDF = pd.DataFrame()
# R1InventoryDF = pd.DataFrame()
# todayDF = pd.DataFrame()
# mins5DF = pd.DataFrame()
# for i in range(0, 271):
#     # 希望第一筆不要抓到前一天的資料,先停一下
#     if i == 0:
#         time.sleep(10)
#     # 先給一個空的DF
#     minDF = pd.DataFrame()
#     # 取得每一分鐘的Snapshots,並轉換時間格式
#     minDF = pd.DataFrame(api.snapshots(contracts)).filter(items = ["code", "ts", "open", "high", "low", "close", "volume" ]).rename(columns = {"code": "StockID", "ts": "DateTime", "open": "Open", "high": "High", "low": "Low", "close": "Close", "volume": "Volume"})
#     minDF.DateTime = pd.to_datetime(minDF.DateTime)
#     minDF["TradeDate"] = pd.to_datetime(minDF.DateTime).dt.strftime("%Y%m%d")
#     minDF["TradeTime"] = pd.to_datetime(minDF.DateTime).dt.time
#     minDF["SnapShotTime"] = datetime.now().strftime("%H:%M:%S")
#     # [若有其他天要測..要關這段]只留下當天的snapshots(開盤時有可能取到前一天的)..
#     minDF = minDF[minDF["TradeDate"] == date.today().strftime("%Y%m%d")]
#     # minDF = minDF.drop(columns = "Date")
#     minDF.StockID = minDF.StockID.astype(str)
#     # 收集今天的Snapshot
#     todayDF = todayDF.append(minDF)
#     # 收集前5min的Snapshot
#     if i <= 5:
#         mins5DF = mins5DF.append(minDF)
#     # 五分鐘時查看K找出符合條件的清單()
#     if i == 5:
#         # now = date.today().strftime("%Y%m%d") + "_" + time.strftime("%H%M%S", time.localtime())
#         # 1.依邏輯抓出要下單的部份(StckID[股票代碼], Close[下單金額])
#         R0_BuyDF = collectBuyOrderDataRule0(stkDF, mins5DF)
#         R1_BuyDF = collectBuyOrderDataRule1(stkDF, mins5DF)
#         # 2.下單    

#     if i in range(6, 264):
#         # 1.檢查庫存(先用下單list模擬)
#         if R0InventoryDF.empty:
#             R0InventoryDF = R0_BuyDF.loc[R0_BuyDF.Buy != 0]
#             R0InventoryDF["Sell"] = 0
#             R0InventoryDF["SellTime"] = ""
#             R0InventoryDF["Result"] = ""
#         if R1InventoryDF.empty:
#             R1InventoryDF = R1_BuyDF.loc[R1_BuyDF.Buy != 0]
#             R1InventoryDF["Sell"] = 0
#             R1InventoryDF["SellTime"] = ""
#             R1InventoryDF["Result"] = ""

        
#         # 2.檢查漲到目標值或跌到出場目標(先不對SoldOut做處理)
#         R0InventoryDF, SoldOut = checkPriceToSell(R0InventoryDF, minDF, "")
#         R1InventoryDF, SoldOut = checkPriceToSell(R1InventoryDF, minDF, "")
         
#         # 3.下單
#         # 4.如全部賣完離開這個loop
#    # 中途全部賣完就離開
 

#     if i == 265:              
#         # 1.檢查庫存
#         # 2.跌停出掉
#         R0InventoryDF, SoldOut = checkPriceToSell(R0InventoryDF, minDF, "X")
#         R1InventoryDF, SoldOut = checkPriceToSell(R1InventoryDF, minDF, "X")
 
#     time.sleep(60 - int(datetime.now().strftime("%S")))
#     # time.sleep(1)
    




# R0TradeDF = stkDF.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).rename(columns = {"Close": "前一交易收盤"}).merge(R0InventoryDF.filter(items = ["StockID", "Buy", "BuyTime", "Sell", "SellTime", "Result"]), on = ["StockID"], how = "left" )
# R0TradeDF["獲利狀況"] = R0TradeDF["Sell"] - R0TradeDF["Buy"]
# R0TradeDF.loc["Total"]= R0TradeDF.sum(numeric_only = True, axis = 0, skipna = True)

# R1TradeDF = stk_data.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).rename(columns = {"Close": "前一交易收盤"}).merge(R1InventoryDF.filter(items = ["StockID", "Buy", "BuyTime", "Sell", "SellTime", "Result"]), on = ["StockID"], how = "left" )
# R1TradeDF["獲利狀況"] = R1TradeDF["Sell"] - R1TradeDF["Buy"]
# R1TradeDF.loc["Total"]= R1TradeDF.sum(numeric_only = True, axis = 0, skipna = True)

# R0tdfile = f"./data/backup_file/Trade_{ymd}_R0.xlsx"
# R1tdfile = f"./data/backup_file/Trade_{ymd}_R1.xlsx"

# file.genFiles(cfg_fname, R0TradeDF, R0tdfile, "xlsx")
# file.genFiles(cfg_fname, R1TradeDF, R1tdfile, "xlsx")


# # %%
# # 每分鐘抓的SnapShot資料存到DB中
# todayDF = todayDF.sort_values(by = ["StockID", "DateTime", "SnapShotTime"])
# SnapDF = todayDF.filter( items = ["StockID", "TradeDate", "TradeTime", "SnapShotTime", "Open", "High", "Low", "Close", "Volume"])
# try:
#     SnapDF = SnapDF.groupby(["StockID", "TradeDate", "TradeTime", "SnapShotTime"], sort = True).agg({"Open": "first", "High": "first", "Low": "first", "Close": "first", "Volume": "first"}).reset_index()
#     db.updateDataToDB(cfg.getConfigValue(cfg_fname, "tb_snap"), SnapDF)
# except:
#     file.genFiles(cfg_fname, todayDF, newfile, "xlsx")


# def getAttentionStockDF(cfg_file):
#     filelst = os.listdir(cfg.getConfigValue(cfg_file, "dailypath"))
#     # matching = [s for s in files if cfg.getConfigValue(cfg_file, "resultname") in s]
#     matching = []
#     i = 0
#     while True:
#         # 算出最近有資料的那一天
#         Dexist_date = (date.today() - timedelta(days = i)).strftime("%Y%m%d")
#         fname = cfg.getConfigValue(cfg_file, "resultname") + f"_{Dexist_date}.xlsx"
#         matching = [s for s in filelst if fname in s]
#         i += 1
#         if matching !=[]:
#             filefullpath = cfg.getConfigValue(cfg_file, "dailypath") + "/" + cfg.getConfigValue(cfg_file, "resultname") + f"_{Dexist_date}.xlsx"
#             break

#     # for file in matching:
#     #     filefullpath = cfg.getConfigValue(cfg_file, "filepath") + f"/{file}"
#     #     break
#     stkDF = pd.read_excel(filefullpath)
#     # 邏輯: 前一交易日成交價 > 60MA & 10MA,且成交量 >= 5000張 
#     # stkDF = stkDF.loc[(stkDF.sgl_SMA > 0) & (stkDF.Volume >= 5000)]
#     stkDF = stkDF.loc[(stkDF.sgl_SMA > 0) & (stkDF.Volume >= 5000) & (stkDF.sgl_SAR_002 > 0)]
#     stkDF.StockID = stkDF.StockID.astype(str)
#     basicDF = getStockIndustryCategory(cfg_file)
#     stkDF = stkDF.merge(basicDF, on = ["StockID"], how = "left").drop(columns = ["cateID"])
#     return stkDF

# def getListContractForAPI(api, STKDF):
#     stkLst = STKDF["StockID"].astype(str).tolist()
#     cts = []
#     for stk in stkLst:
#         cts.append(api.Contracts.Stocks[stk])
#     return cts

# def StockDefaultAccount(id):

# def getminSnapshot(api, Contract): 
#     minDF = pd.DataFrame(api.snapshots(Contract)).filter(items = ["code", "ts", "open", "high", "low", "close", "volume" ]).rename(columns = {"code": "StockID", "ts": "DateTime", "open": "Open", "high": "High", "low": "Low", "close": "Close", "volume": "Volume"})
#     minDF.DateTime = pd.to_datetime(minDF.DateTime)
#     minDF["TradeDate"] = pd.to_datetime(minDF.DateTime).dt.strftime("%Y%m%d")
#     minDF["TradeTime"] = pd.to_datetime(minDF.DateTime).dt.time
#     minDF["SnapShotTime"] = datetime.now().strftime("%H:%M:%S")
#     minDF.StockID = minDF.StockID.astype(str)
#     return minDF

# def getBuyStockDF(FocusDF, SanpShotDF, Rule):
#     BuyDF = pd.DataFrame()
#     # HoldDF = pd.DataFrame()
#     MergeDF = FocusDF.filter(items = ["StockID", "StockName", "上市/上櫃", "Close"]).merge(SanpShotDF.filter(items = ["StockID", "Open", "High", "Close"]).rename(columns = {"Close": "5minClose"}), on = ["StockID"], how = "left")

#     MergeDF["BuyFlag"] = ""
#     if Rule == "R0":
#         MergeDF.loc[(MergeDF["5minClose"] < MergeDF["Close"] * 1.05), "BuyFlag"] = "X"
#     if Rule == "R1":
#         # a.5min價 < 前一交易收盤價+5% b.5min價 >= 開盤價(紅K) c.5min價>= 最高價*(1 - 0.01)
#         MergeDF.loc[(MergeDF["5minClose"] < MergeDF["Close"] * 1.05) & (MergeDF["5minClose"] >= MergeDF["Open"]) & (MergeDF["5minClose"] >= MergeDF["High"] * (1 - 0.01)), "BuyFlag"] = "X"    
#     BuyDF = MergeDF.loc[MergeDF.BuyFlag == "X"]
#     # HoldDF = MergeDF.loc[MergeDF.BuyFlag == ""]
#     return BuyDF.drop(columns = ["BuyFlag", "High", "5minClose", "Close"])

# def getStockIndustryCategory(cfg_file):
#     basicDF = db.readDataFromDBtoDF(cfg.getConfigValue(cfg_file, "tb_basic"), "").filter(items = ["StockID", "categoryID"]).rename(columns = {"categoryID": "cateID"})
#     cateDF = db.readDataFromDBtoDF(cfg.getConfigValue(cfg_file, "tb_ind"), "").filter(items = ["cateID", "cateDesc"])
#     basicDF = basicDF.merge(cateDF, on = "cateID", how = "left")
#     return basicDF
