# %%
import pandas as pd
from datetime import datetime
from util import connect as con, file, strategy as stg, tool, indicator as ind, simulation as sim
import sys

chk_sec = 60


# 做盤後模擬測試
RSIsmiDF = sim().useRSItoMakeResultDF(p_days = -1, RSI_period = 12)

if not RSIsmiDF.empty:
    fpath = "./data/Simulation/RSI.xlsx"
    if tool.checkFileExist(fpath):
        RSIsmiDF = RSIsmiDF.append(pd.read_excel(fpath))
        RSIsmiDF = RSIsmiDF.drop_duplicates(subset = ["TradeDate", "StockID", "Frequency"], keep = "first")
    file.GeneratorFromDF(RSIsmiDF, fpath)
    sys.exit()

# 1.取得連線(可以先不用憑證)
api = con().LoginToServerForStock(simulate = False)

# # 2.設定成交即時回報
# api.set_order_callback(placeOrderCallBack)

# 3.依策略決定下單清單
stkDF = file().getLastFocusStockDF()
stkDF = stg(stkDF).getFromFocusOnByStrategy(no_credit = True)

# 4.組合需要抓價量的Stocks
contracts = con(api).getContractForAPI(stkDF)

# 5.每一段時間Loop一次(13:30結束, 13:25處理最後一盤, 9:12後才看買賣)
minsSnapDF = pd.DataFrame()
rcdDF = pd.DataFrame()
resultDF = pd.DataFrame()

while True:
    # 每分做一次snapshot的累積[col = "StockID", "DateTime", "Open", "High", "Low", "Close", "Volume", "TradeDate", "TradeTime", "SnapShotTime"]
    minsSnapDF = minsSnapDF.append(con(api).getMinSnapshotData(contracts))#.sort_values(by = ["StockID", "DateTime"]).reset_index(drop = True)

    # 時間到收盤就離開
    if datetime.now().strftime("%H:%M") == "13:30":
        break
    # 9:12前就都做snapshot
    if datetime.now().strftime("%H:%M") <= "09:12":
        continue
    
    # 開始計算RSI
    minsSnapDF = minsSnapDF.sort_values(by = ["StockID", "DateTime"]).reset_index(drop = True)
    wiIndDF = ind(minsSnapDF).addRSIvalueToDF(period = 12, cnam_noprd = True)
    wiIndDF["Buy"] = 0
    wiIndDF["Sell"] = 0
    wiIndDF.loc[(wiIndDF.RSI <= 30) & (wiIndDF.RSI > 0), "Buy"] = wiIndDF.Close
    wiIndDF.loc[(wiIndDF.RSI >= 70), "Sell"] = wiIndDF.Close

    # 取每個的最新的一筆
    wiIndDF = wiIndDF.groupby(by = ["StockID"]).tail(1).reset_index()
    
    for idx, row in wiIndDF.iterrows():
        try:
            BuyFlg = rcdDF[rcdDF.StockID == row.StockID].BuyFlg.values[0]
            Freq = rcdDF[rcdDF.StockID == row.StockID].Freq.values[0]
        except:  
            BuyFlg = None
            Freq = 0
        # 處理買進的部份(處理完要做下一筆)
        if row.Buy > 0 and BuyFlg == None:
            l = []
            Freq += 1
            # 處理結果Buy的部份
            l.append(row.DateTime.strftime("%Y%m%d"))
            l.append(row.StockID)
            l.append(Freq)                    
            l.append(row.DateTime.strftime("%H:%M:%S"))
            l.append(row.Buy)
            l.append("00:00:00")
            l.append(0)
            # l只有一層,在產生DF時要再給一個[]
            resultDF = resultDF.append(pd.DataFrame([l], columns = ["TradeDate", "StockID", "Frequency","BuyTime", "Buy", "SellTime", "Sell"]))
            # 處理狀態的部份(先換有記錄的值,沒有再寫入)
            
            try:
               rcdDF.loc[rcdDF.StockID == row.StockID, "BuyFlg"] = "X"
               rcdDF.loc[rcdDF.StockID == row.StockID, "Freq"] = Freq
            except:
                l = []
                l.append(row.StockID)
                l.append("X")
                l.append(Freq)
                rcdDF = rcdDF.append(pd.DataFrame([l], columns = ["StockID", "BuyFlg","Freq"]))
            tool.WaitingTimeDecide(chk_sec)
            continue    # 換下一筆

        # 處理賣出的部份(處理完要做下一筆,若收盤就跳出)
        if BuyFlg != None:
            if row.Sell > 0:
                resultDF.loc[(resultDF.StockID == row.StockID) & (resultDF.Frequency == Freq), "Sell"] = row.Sell
                resultDF.loc[(resultDF.StockID == row.StockID) & (resultDF.Frequency == Freq), "SellTime"] = row.DateTime.strftime("%H:%M:%S")

                rcdDF.loc[rcdDF.StockID == row.StockID, "BuyFlg"] = None
                tool.WaitingTimeDecide(chk_sec)
                continue    # 換下一筆

            if datetime.now().strftime("%H:%M") >= "13:25":
                Freq  += 1
                resultDF.loc[(resultDF.StockID == row.StockID) & (resultDF.Frequency == Freq), "Sell"] = row.Close
                resultDF.loc[(resultDF.StockID == row.StockID) & (resultDF.Frequency == Freq), "SellTime"] = row.DateTime.strftime("%H:%M:%S")
                break   # 離開這個Loop
        tool.WaitingTimeDecide(chk_sec)


ym = datetime.today().strftime("%Y%m")
fpath = f"./data/Trade/{ym}"
tool.checkPathExist(fpath)
fpath = fpath + "/RSI_onlinesim.xlsx"
resultDF["Profit"] = resultDF.Sell - resultDF.Buy
if not resultDF.empty:
    if tool.checkFileExist(fpath):
        resultDF = resultDF.append(pd.read_excel(fpath))
        resultDF = resultDF.drop_duplicates(subset = ["TradeDate", "StockID", "Frequency"], keep = "first")
    file.GeneratorFromDF(resultDF, fpath)

# %%
