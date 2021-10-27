# %%
import pandas as pd
from datetime import date, datetime, timedelta
from util import connect as con, cfg, file, strategy as stg, tool, db, indicator as ind, simulation as sim


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

def getStockMinsSnapshotFromDB(stkBsData = None, date = datetime.today().strftime("%Y%m%d")):
    
    mintb = cfg().getValueByConfigFile(key = "tb_mins")
    slst = tuple(tool.DFcolumnToList(inDF = stkBsData, colname = "StockID"))
    sql = f"SELECT *, TIMESTAMP(TradeDate, TradeTime) as DateTime FROM {mintb} WHERE TradeDate = {date} AND StockID IN {slst}"
    df = db().selectDatatoDF(sql_statment = sql).sort_values(by = ["StockID", "DateTime"], ascending = True).drop(columns = ["modifytime", "TradeDate", "TradeTime"])
    return df






chk_sec = 60
closetime = "13:30:00"
RSI_period = 12

# 處理模擬的狀況
if datetime.now().time() > datetime.strptime(closetime, "%H:%M:%S").time() or datetime.today().weekday() in (5, 6):
    BuyDF = pd.DataFrame()
    # 依策略決定下單清單
    stkDF = file().getLastFocusStockDF(-1)
    stkDF = stg(stkDF).getFromFocusOnByStrategy()
    # 取snapshot的資料(用File資料中的日期+1)
    tb = cfg().getValueByConfigFile(key = "tb_mins")
    maxminsday = db().getMAXvalueFromDBTableColumn(tb_name = tb, col_name = "TradeDate")
    filemaxday = (stkDF.TradeDate.max() + timedelta(days = 1)).date()
    if maxminsday < filemaxday:
        print(f"需要更新{tb}的資料")
        quit()
    if maxminsday > filemaxday:    
        while True:
            day_snap = getStockMinsSnapshotFromDB(stkDF, (stkDF.TradeDate.max() + timedelta(days = 1)).strftime("%Y%m%d"))
            if day_snap.empty:
                filemaxday = filemaxday + timedelta(days = 1)
                continue
            break
    if maxminsday == filemaxday:
        day_snap = getStockMinsSnapshotFromDB(stkDF, filemaxday.strftime("%Y%m%d"))
    
    indDF = ind(day_snap).addRSIvalueToDF(period = RSI_period, cnam_noprd = True)
    indDF["Buy"] = 0
    indDF["Sell"] = 0
    indDF.loc[(indDF.RSI <= 20) & (indDF.RSI > 0), "Buy"] = indDF.Close
    indDF.loc[(indDF.RSI >= 80), "Sell"] = indDF.Close
    # 留下有Flag的部份
    stkbuysell = []
    for stockid, gpDF in indDF.groupby("StockID"):
        buyflag = None
        sellflag = None
        l = []
        for index, row in gpDF.iterrows():
            if buyflag == None and row.Buy > 0:
                l.append(row.StockID)
                l.append(row.DateTime.strftime("%H:%M:%S"))
                l.append(row.Buy)                
                buyflag = "X"
                continue
            if sellflag == None and l != []:
                if row.Sell > 0:
                    l.append(row.DateTime.strftime("%H:%M:%S"))
                    l.append(row.Sell)                    
                    sellflag = "X"
                    stkbuysell.append(l)
                    continue
                if row.DateTime.strftime("%H:%M:%S") == "13:25:00":
                    l.append(row.DateTime.strftime("%H:%M:%S"))
                    l.append(row.Close)                    
                    sellflag = "X"
                    stkbuysell.append(l)
                    continue
            if buyflag != None and sellflag != None:
                break
    
    resultDF = pd.DataFrame(stkbuysell, columns = ["StockID", "BuyTime", "Buy", "SellTime", "Sell"])
    resultDF["Earn"] = resultDF.Sell - resultDF.Buy
    ymd = datetime.today().strftime("%Y%m%d")
    file.GeneratorFromDF(resultDF, rf"D:\simRSI_{ymd}.xlsx")
    quit()

# %%

# 1.取得連線(可以先不用憑證)
api = con().LoginToServerForStock(simulate = False)

# # 2.設定成交即時回報
# api.set_order_callback(placeOrderCallBack)

# 3.依策略決定下單清單
stkDF = file().getLastFocusStockDF()
stkDF = stg(stkDF).getFromFocusOnByStrategy()






# 4.組合需要抓價量的Stocks
contracts = con(api).getContractForAPI(stkDF)

# 5.抓前12mins的每分鐘的Sanpshot
minsSnapDF = pd.DataFrame()
minsSnapDF = con(api).getMinsSnapshotData(contracts, start = 12, usecs = 60).sort_value(by = ["StockID", "DateTime"], ascending = True)

# 6.取得RSI的資料(只留下最近時間的那一筆)
indDF = ind(minsSnapDF).addRSIvalueToDF(period = 12).groupby("StockID").tail(1)
indDF["BuyFlag"] = ""
indDF.loc[(indDF.RSI <= 30) & (indDF.RSI > 0), "BuyFlag"] = "X"

try:
    RSI_BuyDF = stkDF.filter(items = ["StockID", "StockName", "上市/上櫃"]).merge(indDF.filter(items = ["StockID", "Open", "Close", "BuyFlag"]).rename(columns = {"Close": "Buy"}), on = ["StockID"], how = "left")
    RSI_BuyDF = RSI_BuyDF.loc[RSI_BuyDF.BuyFlag == "X"]
    RSI_BuyDF = RSI_BuyDF.drop(columns = ["BuyFlag"])
    RSI_BuyDF["BuyTime"] = datetime.now().strftime("%H:%M:%S")
    # 先把Sell的欄位加進來
    RSI_BuyDF["Sell"] = 0
    RSI_BuyDF["SellTime"] = ""
    RSI_BuyDF["Result"] = ""
except:
    quit()

# 7.30secs後開始檢查賣市價..
tool.WaitingTimeDecide(chk_sec)

# 8.固定時間觀察訂單狀況,決定策略datetime.now()大約會在09:05
bf_cls5 = tool.calcuateFrequencyBetweenTwoTime(stime = datetime.now().strftime("%H:%M:%S"), etime = "13:25:00", feq = chk_sec)

t = 0
trade_list = []
while True:
    minDF = con(api).getMinSnapshotData(contracts)
    minsSnapDF = minsSnapDF.append(minDF)
    t += 1
    # 收盤前5mins就要強制賣出,就可以離開了
    if t == bf_cls5:
        non_sell = RSI_BuyDF.loc[RSI_BuyDF.SellTime == ""]
        try:
            non_sell = non_sell.drop(columns = ["Sell", "SellTime", "Result"]).merge(minDF.filter(items = ["StockID", "Close"]).rename(columns = {"Close": "Sell"}), on = ["StockID"], how = "left")
            non_sell["SellTime"] = datetime.now().strftime("%H:%M:%S")
            non_sell["Result"] = ""
            RSI_BuyDF = RSI_BuyDF.loc[RSI_BuyDF.SellTime != ""]
            RSI_BuyDF = RSI_BuyDF.append(non_sell)
        except:
            pass
        break
    
    indDF = ind(minsSnapDF).addRSIvalueToDF(period = 12).groupby("StockID").tail(1)
    indDF["SellFlag"] = ""
    indDF.loc[indDF.RSI >= 70, "SellFlag"] = "X"
    non_sell = RSI_BuyDF.loc[RSI_BuyDF.SellTime == ""]
    indDF = indDF.loc[indDF.SellFlag == "X"]
    
    try:
        non_sell = non_sell.drop(columns = ["Sell", "SellTime", "Result"]).merge(indDF.filter(items = ["StockID", "Close"]).rename(columns = {"Close": "Sell"}), on = ["StockID"], how = "left")
        non_sell["SellTime"] = datetime.now().strftime("%H:%M:%S")
        non_sell["Result"] = ""
        RSI_BuyDF = RSI_BuyDF.loc[RSI_BuyDF.SellTime != ""]
        RSI_BuyDF = RSI_BuyDF.append(non_sell)
    except:
        continue
    
    
    tool.WaitingTimeDecide(chk_sec)

RSI_TradeDF = getTradeResultDF(stkDF, RSI_BuyDF, "RSI")

# 準備存檔資料
ymd = date.today().strftime("%Y%m%d")
trade = cfg().getValueByConfigFile(key = "tradepath")
RSI_tdfile = f"{trade}/Trade_{ymd}_RSI.xlsx"


file.GeneratorFromDF(RSI_TradeDF, RSI_tdfile)