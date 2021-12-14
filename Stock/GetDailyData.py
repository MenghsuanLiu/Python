# %%
import pandas as pd
from datetime import date, timedelta, datetime
from util.util import connect as con, indicator as ind, cfg, db, file, tool, craw, strategy as stg, simulation as sim
# %%
def writeDailyRawDataDB(api = None, StkDF: pd.DataFrame = None):
    tb = cfg().getValueByConfigFile(key = "tb_daily")
    sql = f"SELECT StockID, MAX(TradeDate) as TradeDate FROM {tb} group by StockID"
    lastday_stocks = db().selectDatatoDF(sql_statment = sql)
    kBarDF = pd.DataFrame()
    for index, row in StkDF.iterrows():
        udate = datetime.strptime(row["update_date"], "%Y/%m/%d").date()
        try:
            lastday = lastday_stocks.loc[lastday_stocks.StockID == row["StockID"], "TradeDate"].values[0]
        except:
            lastday = udate - timedelta(days = 400)

        if lastday < udate:
            DF = con(api).getKbarData(stkid = row["StockID"], sdate = (lastday + timedelta(days = 1)).strftime("%Y-%m-%d"), edate = udate.strftime("%Y-%m-%d"))
            kBarDF = kBarDF.append(DF)
    # 資料庫有資料 kBarDF就可能是空的       
    if not kBarDF.empty:
        # kBarDF = kBarDF.filter(items = ["StockID",  "TradeDate", "TradeTime", "Open", "High", "Low", "Close", "Volume"]).drop_duplicates(subset = ["StockID", "TradeDate", "TradeTime"], keep = "first")
        kBarDF = kBarDF.filter(items = ["StockID",  "TradeDate", "TradeTime", "Open", "High", "Low", "Close", "Volume"])
        DkBarDF = kBarDF.groupby(["StockID", "TradeDate"], sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
        # 每日的OHLC資料
        if not DkBarDF.empty:
            db().updateDFtoDB(DkBarDF, tb_name = tb)

def writeDailyMinsKbarDataToDB(api = None):
    no_update = []
    tb = cfg().getValueByConfigFile(key = "tb_mins")
    sql = f"SELECT StockID, MAX(TradeDate) as TradeDate FROM {tb} group by StockID"
    stkldayDF = db().selectDatatoDF(sql_statment = sql)
    bcDF = db().selectDatatoDF(cfg().getValueByConfigFile(key = "tb_basic"))
    bcDF = bcDF.merge(stkldayDF, on = ["StockID"], how = "left")
    for index, row in bcDF.iterrows():
        try:
            udate = row.TradeDate + timedelta(days = 1)
        except:
            udate = date.today() - timedelta(days = 300)
        if udate > date.today():
            continue
        stkDF = con(api).getKbarData(stkid = row.StockID, sdate = udate.strftime("%Y-%m-%d"), edate = date.today().strftime("%Y-%m-%d")).filter(items = ["StockID", "TradeDate", "TradeTime", "Open", "High", "Low", "Close", "Volume"])
        if stkDF.empty:
            # 不是遇到週末才需要show沒有成功的部份
            if udate.weekday() not in (5, 6):
                no_update.append(row.StockID)
            continue
        stkDF = stkDF.drop_duplicates(subset = ["StockID", "TradeDate", "TradeTime"], keep = "first")
        print(f"StockID: {row.StockID}")
        db().updateDFtoDB(stkDF, tb_name = tb)

    if no_update != []:
        print(f"沒有更新的Stock如下:{no_update}")

def writeDailyKbarDataToDB(StkDF: pd.DataFrame):
    if StkDF.empty:
        return
    tb = cfg().getValueByConfigFile(key = "tb_daily")    
    sql = f"SELECT MAX(TradeDate) as TradeDate FROM {tb}"
    daily_maxday = db().selectDatatoDF(sql_statment = sql).iloc[0,0]

    tb = cfg().getValueByConfigFile(key = "tb_mins")
    sql = f"SELECT MAX(TradeDate) as TradeDate FROM {tb}"
    mins_maxday = db().selectDatatoDF(sql_statment = sql).iloc[0,0]
    if daily_maxday < mins_maxday:
        stktuple = tuple(tool.DFcolumnToList(StkDF, colname = "StockID"))
        tb = cfg().getValueByConfigFile(key = "tb_mins")
        mins_maxday = mins_maxday.strftime("%Y%m%d")
        sql = f"SELECT * FROM {tb} WHERE TradeDate = {mins_maxday} AND StockID in {stktuple}"
        minsDF = db().selectDatatoDF(sql_statment = sql).drop(columns = ["modifytime"])
        DkBarDF = minsDF.groupby(["StockID", "TradeDate"], sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
        tb = cfg().getValueByConfigFile(key = "tb_daily")
        db().updateDFtoDB(DkBarDF, tb_name = tb)
    
def writeLegalPersonDailyVolumeDB(stkBsData: pd.DataFrame):
    # 取得TabName
    tb = cfg().getValueByConfigFile(key = "tb_volume")
    sql = f"SELECT MAX(TradeDate) as TradeDate FROM {tb}"
    allDF = pd.DataFrame()
    dailyDF = pd.DataFrame()
    Head = []
    ItemData = []
    try:
        vol_lastday = db().selectDatatoDF(sql_statment = sql).iloc[0,0]
        stk_lastday = datetime.strptime(stkBsData.update_date.max(), "%Y/%m/%d").date()
    except Exception as exc:
        return print(exc) 
    # 日期相同,表示db有資料了...Exit
    if vol_lastday == stk_lastday:
        return print(f"最近一個交易日的量資料{tb}己存在!!") 
    # Loop日期,抓資料寫入db
    while True:
        vol_lastday += timedelta(days = 1)
        # 抓出上市/上櫃的List
        markets = craw().getMarketList()
        for mkt in markets:
            ymd = vol_lastday.strftime("%Y%m%d")
            # 取得網頁物件(沒有值就換下一個市場)
            try:
                bsobj = craw().getBSobject(YMD = ymd, market = mkt)
                tbobj = craw().getTBobjectFromBSobject(in_bsobj = bsobj, tbID = 0, market = mkt)
            except:
                continue
            
            # Head List是空值,就要取一下(用上市的表頭就好)
            if Head == [] and mkt == "TSE":
                Head = craw().getHeaderLine(in_tbobj = tbobj)
            ItemData = craw().getItemListForMarket(in_tbobj = tbobj, market = mkt)
            mktDF = pd.DataFrame(ItemData, columns = Head)
            dailyDF = dailyDF.append(mktDF)

        # # 產生DataFrame(每一日的資料)
        # df_daily = pd.DataFrame(ItemData, columns = Head)
        if not dailyDF.empty:
        # 1.準備要用的資料及換column name
            dailyDF = dailyDF.drop(columns = ["證券名稱", "外資自營商買進股數", "外資自營商賣出股數", "外資自營商買賣超股數"]).rename(columns = {"證券代號": "StockID", "外陸資買進股數(不含外資自營商)": "ForeignBuy", "外陸資賣出股數(不含外資自營商)": "ForeignSell", "外陸資買賣超股數(不含外資自營商)": "ForeignBalance", "投信買進股數": "CreditBuy", "投信賣出股數": "CreditSell", "投信買賣超股數": "CreditBalance", "自營商買賣超股數": "SelfTotalBalance", "自營商買進股數(自行買賣)": "SelfBuy", "自營商賣出股數(自行買賣)": "SelfSell", "自營商買賣超股數(自行買賣)": "SelfBalance", "自營商買進股數(避險)": "SelfHedgingBuy", "自營商賣出股數(避險)": "SelfHedgingSell", "自營商買賣超股數(避險)": "SelfHedgingBalance", "三大法人買賣超股數": "LegalPersonBalance"})
            # 2.放入日期
            dailyDF.insert(1, "TradeDate", vol_lastday)
            # 3.把DF放入最後要出去的DF
            allDF = allDF.append(dailyDF)
        # 當資料庫的日期累加到api中的日期就離開...
        if vol_lastday == stk_lastday:
            break
    # 留下有關心的股票
    allDF = pd.merge(allDF, stkBsData.filter(items = ["StockID"]), on = ["StockID"])

    db().updateDFtoDB(allDF, tb_name = tb)
    

    # day_check = False
    # for mkt in marketlist:
    #     # 找出離今天最近日期有值的日期
    #     for i in range(0,10):
    #         web_ymd = (date.today() - timedelta(days = i)).strftime("%Y%m%d")
    #         try:
    #             TB_Obj = getTBobj(getBSobj(web_ymd, mkt, cfg), 0, mkt, cfg)
    #             break
    #         except:
    #             continue
    #     # 表示這次的loop還沒有檢查日期
    #     if day_check == False:
    #         # db connection
    #         rddb_con = db.mySQLconn(tb.split(".")[0], "read")
    #         # 抓出Table中最後一筆日期,預設是日期格式,要轉成YYYYMMDD
    #         dblast_ymd = pd.read_sql(f"SELECT DISTINCT TradeDate FROM {tb} WHERE TradeDate = (SELECT MAX(TradeDate) FROM {tb})", con = rddb_con)
    #         dblast_ymd = dblast_ymd.iloc[0,0].strftime("%Y%m%d")
    #         # 最後一個交易日和Table最後日期若一致就不用往下走
    #         if dblast_ymd == web_ymd:        
    #             return print(f"最近一個交易日的量資料{tb}己存在!!")            
    #         # 這個年月日給面寫db用
    #         db_ymd = web_ymd
    #         day_check = True
    #     # 取得表頭(只用上市的表頭就好)
    #     if mkt == "TSE":
    #         ItemData = []
    #         Header = getHeaderLine(TB_Obj)
    #     # 取得Item
    #     for rows in TB_Obj.select("table > tbody > tr")[0:]:
    #         itemlist = []
    #         colnum = 0
    #         for col in rows.select("td"):
    #             colnum += 1
    #             if colnum in (1, 2):
    #                 val = col.string.strip()
    #             else:                
    #                 val = int(col.text.replace(",", "").strip())
    #             if mkt == "OTC" and colnum in [9, 10, 11, 21, 22]:
    #                 continue
    #             itemlist.append(val)
    #         if  mkt == "OTC":
    #             neworder = list(range(0,11)) + [17] + list(range(11,17)) + [18]
    #             itemlist = [itemlist[i] for i in neworder]   
    #         ItemData.append(itemlist)
    # # 產生DataFrame
    # df_vol = pd.DataFrame(ItemData, columns = Header)
    # # 寫到資料庫(前面有先檢查了...若有資料就離開..日後若不產生file就要檢查db)
    
    # # 1.準備要用的資料及換column name
    # df_vol = df_vol.drop(columns = ["證券名稱", "外資自營商買進股數", "外資自營商賣出股數", "外資自營商買賣超股數"]).rename(columns = {"證券代號": "StockID", "外陸資買進股數(不含外資自營商)": "ForeignBuy", "外陸資賣出股數(不含外資自營商)": "ForeignSell", "外陸資買賣超股數(不含外資自營商)": "ForeignBalance", "投信買進股數": "CreditBuy", "投信賣出股數": "CreditSell", "投信買賣超股數": "CreditBalance", "自營商買賣超股數": "SelfTotalBalance", "自營商買進股數(自行買賣)": "SelfBuy", "自營商賣出股數(自行買賣)": "SelfSell", "自營商買賣超股數(自行買賣)": "SelfBalance", "自營商買進股數(避險)": "SelfHedgingBuy", "自營商賣出股數(避險)": "SelfHedgingSell", "自營商買賣超股數(避險)": "SelfHedgingBalance", "三大法人買賣超股數": "LegalPersonBalance"})
    # df_vol.insert(1, "TradeDate", db_ymd)
    # # 2.留下有關心的股票
    # df_vol = pd.merge(df_vol, stk_data.filter(items = ["StockID"]), on = ["StockID"])
    # # 3.刪舊資料
    # condition = {"TradeDate": (db_ymd)}
    # db.delDataFromDB(tb, condition)
    # # 4.更新資料    
    # db.updateDataToDB(tb, df_vol)

# 把基本資料及量都併進來
def getStockDailyDataFromDB(stkBsData: pd.DataFrame, days:int = 250)->pd.DataFrame:
    dytb = cfg().getValueByConfigFile(key = "tb_daily")
    slst = tuple(tool.DFcolumnToList(inDF = stkBsData, colname = "StockID"))
    sql = f"SELECT DISTINCT TradeDate FROM {dytb}"
    sdate = db().selectDatatoDF(sql_statment = sql)
    sdate = sdate.sort_index(ascending = False).reset_index(drop = True)
    sdate = sdate.loc[days][0].strftime("%Y%m%d")
    sql = f"SELECT * FROM {dytb} WHERE TradeDate >= {sdate} AND StockID IN {slst}"
    df = db().selectDatatoDF(sql_statment = sql).sort_values(by = ["StockID", "TradeDate"], ascending = True)
    df = mergeVolumeDataDB(df)
    df = df.merge(stkBsData, on = ["StockID"], how = "left")
    return df

def mergeVolumeDataDB(in_DF: pd.DataFrame)->pd.DataFrame:
    # 找出這次資料的最後一筆日期
    tb = cfg().getValueByConfigFile(key = "tb_volume")
    max_ymd = in_DF.TradeDate.max().strftime("%Y%m%d")
    sql = f"SELECT * FROM {tb} WHERE TradeDate = {max_ymd}"
    
    try:
        volDF = db().selectDatatoDF(sql_statment = sql).filter(items = ["StockID", "TradeDate", "CreditBalance", "ForeignBalance", "SelfTotalBalance"]).rename(columns = {"CreditBalance": "投信(股數)", "ForeignBalance": "外資(股數)", "SelfTotalBalance": "自營商(股數)" })
        out_DF = in_DF.merge(volDF, on = ["StockID", "TradeDate"], how = "left")
        return out_DF
    except Exception as exc:
        print(exc)

    # df = in_DF.sort_values(by = "TradeDate", ascending = False)
    # df_ymd = df["TradeDate"].head(1).values[0].strftime("%Y%m%d")

    # 從DB抓取資料
    # tb_vol = cfg().getValueByConfigFile(key = "tb_volume")
    # sql = f"SELECT * FROM {tb_vol} WHERE TradeDate = {df_ymd}"
    # vol_df = db().selectDatatoDF(sql_statment = sql).filter(items = ["StockID", "TradeDate", "CreditBalance"]).rename(columns = {"CreditBalance": "投信買賣超股數"})
    # tb_vol = cfg.getConfigValue(cfgname, "tb_volume")
    # filt = {"TradeDate": df_ymd}
    # vol_df = db.readDataFromDBtoDF(tb_vol, filt).filter(items = ["StockID", "TradeDate", "CreditBalance"]).rename(columns = {"CreditBalance": "投信買賣超股數"})
    # vol_df.insert(0, "TradeDate", df["TradeDate"].head(1).values[0])
    # if not vol_df.empty:
    #     return dframe.merge(vol_df, on = ["StockID", "TradeDate"], how = "left")
    # else:
    #     print(f"沒有取到{tb_vol}的資料!!")

def getLastPeriodDF(in_DF: pd.DataFrame, period:int = 5)->pd.DataFrame:
    outDF = pd.DataFrame()
    outDF = in_DF.groupby("StockID").tail(period)
    return outDF

def writeResultDataToFile(fullDF: pd.DataFrame):
    max_ymd = fullDF.TradeDate.max().strftime("%Y%m%d")
    fpath = cfg().getValueByConfigFile(key = "dailypath") + f"/{max_ymd[0:6]}"
    fname = f"{fpath}/" + cfg().getValueByConfigFile(key = "resultname") + f"_{max_ymd}.xlsx"

    outDF = getLastPeriodDF(in_DF = fullDF, period = 1).filter(items = (["StockID", "StockName", "上市/上櫃", "投信(股數)", "外資(股數)", "自營商(股數)", "TradeDate", "Close", "Volume", "MFI", ] + [x for x in fullDF.columns[fullDF.columns.str.contains("sgl")]]))
    file.GeneratorFromDF(outDF, fname)
    
    fname = f"{fpath}/FocusList_{max_ymd}.xlsx"
    stgDF = pd.DataFrame()
    stgDF = stg(outDF).getFromFocusOnByStrategy(no_credit = True)
    stgDF = stgDF[["StockID", "StockName", "cateDesc", "上市/上櫃", "投信(股數)", "外資(股數)", "自營商(股數)", "TradeDate", "Close", "Volume", "MFI", "sgl_SMA", "sgl_SAR", "sgl_MAXMIN", "sgl_BBANDS", "sgl_MACD"]]
    file.GeneratorFromDF(stgDF, fname)
    fname = cfg().getValueByConfigFile(key = "dailypath") + "/8002.xlsx"
    file.GeneratorFromDF(stgDF, fname)

    stgDF = stgDF[["TradeDate", "StockID", "StockName", "上市/上櫃", "cateDesc", "Close", "Volume", "MFI", "sgl_SMA", "sgl_SAR", "sgl_MAXMIN", "sgl_BBANDS", "sgl_MACD"]].rename(columns = {"TradeDate": "Date", "上市/上櫃": "Market", "cateDesc": "Category", "sgl_SMA": "signalSMA", "sgl_SAR": "signalSAR", "sgl_MAXMIN": "signalMAXMIN", "sgl_BBANDS": "signalBBANDS", "sgl_MACD": "signalMACD"})
    db().updateDFtoDB(stgDF, tb_name = "dailybuystrategy")

def writeDailyFocusStockTicks(api):
    stkDF_new = file().getLastFocusStockDF()
    stkDF = stg(stkDF_new).getFromFocusOnByStrategy()
    BuyList = tool.DFcolumnToList(stkDF, "StockID")
    tickDF = pd.DataFrame()

    for id in BuyList:
        tk = api.ticks(contract = api.Contracts.Stocks[id], date = date.today().strftime("%Y-%m-%d"))
        tDF = pd.DataFrame({**tk})
        tDF.ts = pd.to_datetime(tDF.ts)
        tDF.insert(0, "StockID", id)
        tickDF = tickDF.append(tDF)
    tickDF = tickDF.filter(items = ["StockID", "ts", "close", "volume", "bid_price", "bid_volume", "ask_price", "ask_volume"]).rename(columns = {"ts": "TradeDateTime", "close": "Close", "volume": "Volume", "bid_price": "BidPrice", "bid_volume": "BidVolume", "ask_price": "AskPrice", "ask_volume": "AskVolume"})
    db().updateDFtoDB(tickDF, tb_name = "dailyticks")


# 先檢查資料夾是否存在..沒有就建立
tool.checkCreateYearMonthPath()

api = con().ServerConnectLogin( user = "lydia")

BsData = con(api).getStockDataByCondition()

writeDailyFocusStockTicks(api)
writeDailyMinsKbarDataToDB(api)
writeDailyKbarDataToDB(BsData)
writeDailyRawDataDB(api, BsData)    # 這支去補足前面漏的
writeLegalPersonDailyVolumeDB(BsData)


# 取得每天的成交資料(後面數字是往回抓幾天)
stkDF = getStockDailyDataFromDB(BsData, 250)
stkDFwithInd = ind(stkDF).addMAvalueToDF()  # Default ma_type = SAR, period = [5, 10, 20, 60]
stkDFwithInd = ind(stkDFwithInd).addBBANDvalueToDF()   # Default period = 10, sigma = 2
stkDFwithInd = ind(stkDFwithInd).addSARvalueToDF(acc = 0.02, max = 0.2)   # Default acc = 0.02, max = 0.2
stkDFwithInd = ind(stkDFwithInd).addSARvalueToDF(acc = 0.03, max = 0.3)   # Default acc = 0.02, max = 0.2
stkDFwithInd = ind(stkDFwithInd).addMAXMINvalueToDF()   # Default period = [120, 240], fn = ["MAX", "MIN"]
stkDFwithInd = ind(stkDFwithInd).addRSIvalueToDF(period = 6)
stkDFwithInd = ind(stkDFwithInd).addRSIvalueToDF(period = 12)
stkDFwithInd = ind(stkDFwithInd).addMACDvalueToDF() # Default f_period = 12, s_period = 26, sign_period = 9
stkDFwithInd = ind(stkDFwithInd).addKDJvalueToDF() # Default fk_perd = 9, s_perd = 3
stkDFwithInd = ind(stkDFwithInd).addMFIvalueToDF()

stkDFwithInd = getLastPeriodDF(stkDFwithInd, 100)   # 後面算指標時會用到52天前的資料
stkDFwithInd = ind(stkDFwithInd).getSignalByIndicator(inds = ["SMA", "SAR", "MAXMIN", "BBANDS", "MACD"]) # Default = ["SMA", "SAR", "MAXMIN", "BBands", "RSI", "MACD", "KDJ"]
writeResultDataToFile(stkDFwithInd)


# 做盤後模擬測試
RSIsmiDF = sim().useRSItoMakeResultDF(p_days = -1, RSI_period = 12)

if not RSIsmiDF.empty:
    fpath = "./data/Simulation/RSI.xlsx"
    if tool.checkFileExist(fpath):
        RSIsmiDF = RSIsmiDF.append(pd.read_excel(fpath)).reset_index(drop=True)
        RSIsmiDF[["TradeDate", "StockID"]] = RSIsmiDF[["TradeDate", "StockID"]].astype(str)
        RSIsmiDF = RSIsmiDF.drop_duplicates(subset = ["TradeDate", "StockID", "Frequency"], keep = "first")
    file.GeneratorFromDF(RSIsmiDF, fpath)


today = datetime.now().strftime("%Y-%m-%d")
sql = f"SELECT StockID, Date(TradeDateTime) as TickDate, TIME_FORMAT(TradeDateTime, '%T.%f') as TickTime, Close, Volume, BidPrice, BidVolume, AskPrice, AskVolume FROM dailyticks WHERE Date(TradeDateTime) = '{today}' AND Time(TradeDateTime) <= '09:05:00'"
TicksDF = db().selectDatatoDF(sql_statment = sql).sort_values(by = ["StockID", "TickDate", "TickTime"])

tickpath = "./data/PlotData/Ticks.csv"
if not tool.checkFileExist(tickpath):
    file.GeneratorFromDF(TicksDF, tickpath, "csv")
else:
    with open(tickpath, "a") as f:
        TicksDF.to_csv(f, header = False, index = False, line_terminator = "\n")

# %%



# 只要上市/上櫃,不要金融, KY股, 股價>=20
# def getStockData(api, stocks):
#     # api.Contracts.Stocks資料結構
#     ## [exchange(市場), code(代碼), symbol(市場+代碼), name(公司名), category(產業分類), unit(1張1000股), limit_up(前一交易日漲停價), limit_down(前一交易日跌停價), reference(前一交易日收盤價), update_date(更新日)]
#     df = []
#     for s in stocks:
#         df_market =[]
#         i = 0
#         # 上市(筆數太多要等一下)
#         if s == "TSE":
#             market = api.Contracts.Stocks.TSE
#             time.sleep(10)
#         # 上櫃    
#         if s == "OTC":
#             market = api.Contracts.Stocks.OTC
#         # 興櫃
#         if s == "OES":  
#             market = api.Contracts.Stocks.OES
        
#         for id in market:
#             df_market.append({**id})
#         df_market = pd.DataFrame(df_market)
#         # https://members.sitca.org.tw/OPF/K0000/files/F/01/%E8%AD%89%E5%88%B8%E4%BB%A3%E7%A2%BC%E7%B7%A8%E7%A2%BC%E5%8E%9F%E5%89%87.doc分類對照表(17金融)
#         # 不要權證/金融股 / 小於20元
#         df_market = df_market[~df_market["category"].isin(["00", "", "17"]) & ~df_market["name"].str.contains("KY") & ~df_market["name"].str.contains("特")]
#         # df_market = df_market[( df_market["limit_up"] + df_market["limit_down"] ) / 2 >= 20]
#         df_market = df_market[df_market["reference"] >= 20]


#         while True:
#             date_check = (date.today() - timedelta(days = i)).strftime("%Y/%m/%d")
#             df_check = df_market[df_market["update_date"] == date_check]
#             i += 1
#             if not df_check.empty:
#                 df_market = df_check
#                 break
    
#         if s == stocks[0]:
#             df = df_market
#         else:
#             df = df.append(df_market)
    
#     df = df.filter(items = ["code", "name", "exchange", "category", "update_date"]).rename(columns = {"code": "StockID", "name": "StockName", "exchange": "上市/上櫃"}).replace({"TSE": "上市", "OTC": "上櫃", "OES": "興櫃"})
#     # 下面這段是更新DB用的
#     toDB = df.filter(items = ["StockID", "StockName", "上市/上櫃", "category"]).rename(columns = {"StockName": "Name", "上市/上櫃": "Exchange", "category": "categoryID"})
#     db.updateDataToDB("stock.basicdata", toDB)
#     return df.reset_index(drop = True)
# 
# 
# def getStockSMA(dframe, day_list):
#     first = True
#     for stockid, gp_df in dframe.groupby("StockID"):
#         if type(day_list) is int:
#             gp_df[f"MA_{day_list}"] = talib.SMA(gp_df.Close, timeperiod = day_list)
#         else:
#             for madays in day_list:
#                 gp_df[f"MA_{madays}"] = talib.SMA(gp_df.Close, timeperiod = madays)
#         if first == True:
#             df = gp_df
#             first = False
#         else:
#             df = df.append(gp_df)  
#     return df

# def getStockBBands(dframe, period, stdNbr):
#     first = True
#     for stockid, gp_df in dframe.groupby("StockID"):
#         gp_df["upperband"], gp_df["middleband"], gp_df["lowerband"] = talib.BBANDS( gp_df["Close"], timeperiod = period, nbdevup = stdNbr, nbdevdn = stdNbr, matype = 0)

#         if first == True:
#             df = gp_df
#             first = False
#         else:
#             df = df.append(gp_df)  
#     return df

# def getStockSAR(dframe, acc, max):
#     first = True
#     title = str(acc).replace(".", "")
#     for stockid, gp_df in dframe.groupby("StockID"):
#         gp_df[f"SAR_{title}"] = talib.SAR(gp_df["High"], gp_df["Low"], acceleration = acc, maximum = max)

#         if first == True:
#             df = gp_df
#             first = False
#         else:
#             df = df.append(gp_df)  
#     return df

# def getStockMaxMin(dframe, day_list, type_list):
#     first = True
#     for stockid, gp_df in dframe.groupby("StockID"):
#         for fn in type_list:
#             for days in day_list:
#                 if fn.lower() == "max":
#                     gp_df[f"{fn}_{days}"] = gp_df["Close"].rolling(days).max()
#                 if fn.lower() == "min":
#                     gp_df[f"{fn}_{days}"] = gp_df["Close"].rolling(days).min()
#         if first == True:
#             df = gp_df
#             first = False
#         else:
#             df = df.append(gp_df)
#     return df

# def getStockMACD(dframe, day_list):
#     first = True
#     for stockid, gp_df in dframe.groupby("StockID"):
#         for d in day_list:
#             # 调用talib计算指数移动平均线的值
#             gp_df[f"EMA{d}"] = talib.EMA(gp_df.Close, timeperiod = d)

#         # 调用talib计算MACD指标
#         gp_df["MACD"], gp_df["MACDsignal"], gp_df["MACDhist"] = talib.MACD(gp_df.Close, fastperiod = day_list[0], slowperiod = day_list[1], signalperiod = day_list[2])
        
#         if first == True:
#             df = gp_df
#             first = False
#         else:
#             df = df.append(gp_df)     
#     return df

# # RSI計算=>https://www.moneydj.com/kmdj/wiki/wikiviewer.aspx?keyid=f2aa7c2e-f6b5-447f-b5b7-d77572aa4724
# def getStockRSI(dframe, day_list):
#     DFrsi = pd.DataFrame()
#     for stockid, gp_df in dframe.groupby("StockID"):
#         if type(day_list) is int:
#             gp_df[f"RSI_{day_list}"] = talib.RSI(gp_df.Close, timeperiod = day_list)
#         else:
#             for rsidays in day_list:
#                 gp_df[f"RSI_{rsidays}"] = talib.RSI(gp_df.Close, timeperiod = rsidays)
#         DFrsi = DFrsi.append(gp_df)
#     return DFrsi

# def getSignal(dataframe, tatype):
#     colnam = f"sgl_{tatype}"
#     dataframe[colnam] = 0
#     if tatype.lower() == "sma":
#         dataframe.loc[(dataframe.Close > dataframe.MA_10) & (dataframe.Close > dataframe.MA_60), colnam] = 1
#         dataframe.loc[(dataframe.Close < dataframe.MA_10) & (dataframe.Close < dataframe.MA_60), colnam] = -1
#     if tatype.lower() == "bbands":
#         dataframe.loc[dataframe.Close > dataframe.upperband, colnam] = -1
#         dataframe.loc[dataframe.Close < dataframe.lowerband, colnam] = 1
#     if tatype[0:3].lower() == "sar":
#         high_9 = dataframe.High.rolling(9).max()
#         low_9 = dataframe.Low.rolling(9).min()
#         dataframe["tenkan_sen_line"] = (high_9 + low_9) / 2
#         high_26 = dataframe.High.rolling(26).max()
#         low_26 = dataframe.Low.rolling(26).min()
#         dataframe["kijun_sen_line"] = (high_26 + low_26) / 2
#         dataframe["senkou_spna_A"] = ((dataframe.tenkan_sen_line + dataframe.kijun_sen_line) / 2).shift(26)
#         high_52 = dataframe.High.rolling(52).max()
#         low_52 = dataframe.High.rolling(52).min()
#         dataframe["senkou_spna_B"] = ((high_52 + low_52) / 2).shift(26)
#         dataframe["chikou_span"] = dataframe.Close.shift(-26)
#         if tatype[-3:] == "002":
#             dataframe.loc[(dataframe.Close > dataframe.senkou_spna_A) & (dataframe.Close > dataframe.senkou_spna_B) & (dataframe.Close > dataframe.SAR_002), colnam] = 1
#             dataframe.loc[(dataframe.Close < dataframe.senkou_spna_A) & (dataframe.Close < dataframe.senkou_spna_B) & (dataframe.Close < dataframe.SAR_002), colnam] = -1
#         if tatype[-3:] == "003":
#             dataframe.loc[(dataframe.Close > dataframe.senkou_spna_A) & (dataframe.Close > dataframe.senkou_spna_B) & (dataframe.Close > dataframe.SAR_003), colnam] = 1
#             dataframe.loc[(dataframe.Close < dataframe.senkou_spna_A) & (dataframe.Close < dataframe.senkou_spna_B) & (dataframe.Close < dataframe.SAR_003), colnam] = -1
#         dataframe = dataframe.drop(columns = ["tenkan_sen_line", "kijun_sen_line", "senkou_spna_A", "senkou_spna_B", "chikou_span"])
#     if tatype[0:6].lower() == "maxmin":
#         dataframe.loc[(dataframe["Close"] >= dataframe[f"max_{tatype[-3:]}"]), colnam] = 1
#         dataframe.loc[(dataframe["Close"] <= dataframe[f"min_{tatype[-3:]}"]), colnam] = -1
#     # 短天期的RSI由下往上突破長天期的RSI線時，表示走勢有轉而增強的跡象，可以考慮買進。反之若短天期的RSI由上往下突破時，則走勢轉弱，考慮賣出    
#     if tatype.lower() == "rsi":
#         dataframe.loc[(dataframe.RSI_6 > dataframe.RSI_12), colnam] = 1
#         dataframe.loc[(dataframe.RSI_6 > dataframe.RSI_12), colnam] = -1
#     return dataframe

# # def getStockKD(dframe):
# #     for stockid, gp_df in dframe.groupby("StockID"):
# #         gp_df["KD"] = abstract.STOCH(gp_df)


# # File的部份目前未使用
# def getStockDailyDataFile(StkDF, cfgname, days):
#     stk_lst = StkDF["StockID"].astype(str).to_list()
#     fpath = cfg.getConfigValue(cfgname, "filepath")
#     fpath = f"{fpath}/" + cfg.getConfigValue(cfgname, "hisname") + ".csv"
#     # 讀取資料
#     df_history = pd.read_csv(fpath, low_memory = False)
#     # StockID由int轉str
#     df_history["StockID"] = df_history["StockID"].apply(str)
#     # 只留下這次要的Stock List
#     df_history = df_history[df_history.StockID.isin(stk_lst)]
#     # 轉換日期格式
#     df_history["ts_date"] = pd.to_datetime(df_history["ts_date"], format = "%Y-%m-%d").dt.date

#     # 只留下每個股票後250筆,要用後...後面算數SMA類的資料才會對
#     first = True
#     for stockid, gp_df in df_history.groupby("StockID"):
#         # stk_up_date = StkDF[StkDF["StockID"] == stockid].update_date.values[0]
#         gp_df = gp_df.sort_values(by = "ts_date", ascending = True)
#         # 今天沒有交易資料就不要留這支
#         # if gp_df["ts_date"].tail(1).values[0].strftime("%Y/%m/%d") != stk_up_date:
#         #     continue
#         gp_df = gp_df.tail(days)
#         if first == True:
#             df = gp_df
#             first = False
#         else:
#             df = df.append(gp_df)

#     return df.reset_index(drop = True)

# def writeLegalPersonDailyVolumeFile(marketlist, cfgname):
#     fpath = cfg.getConfigValue(cfgname, "dailypath")
#     if os.path.exists(fpath) == False:
#         os.makedirs(fpath)

#     day_check = False
#     for mkt in marketlist:
#         # 找出離今天最近日期有值的日期
#         for i in range(0,10):
#             web_ymd = (date.today() - timedelta(days = i)).strftime("%Y%m%d")
#             try:
#                 TB_Obj = getTBobj(getBSobj(web_ymd, mkt, cfg), 0, mkt, cfg)
#                 break
#             except:
#                 continue
#         # 表示這次的loop還沒有檢查日期
#         if day_check == False:
#             # 找出現存的檔案最近的日期[File: DailyVolume_<YYYYMMDD>.csv]
#             file_list = sorted([s for s in os.listdir(fpath) if cfg.getConfigValue(cfgname, "volname") in s], reverse = True)
#             file_last_date = ((file_list[0].split("_"))[1].split("."))[0]
#             if file_last_date == web_ymd:
#                 return print(f"最近一個交易的檔案己存在!!({file_list[0]})")
#             # 準備檔案名
#             volfile = f"{fpath}/" + cfg.getConfigValue(cfgname, "volname") + f"_{web_ymd}.csv"
#             day_check = True
#         # 取得表頭(只用上市的表頭就好)
#         if mkt == "TSE":
#             ItemData = []
#             Header = getHeaderLine(TB_Obj)
#         # 取得Item
#         for rows in TB_Obj.select("table > tbody > tr")[0:]:
#             itemlist = []
#             colnum = 0
#             for col in rows.select("td"):
#                 colnum += 1
#                 if colnum in (1, 2):
#                     val = col.string.strip()
#                 else:                
#                     val = int(col.text.replace(",", "").strip())
#                 if mkt == "OTC" and colnum in [9, 10, 11, 21, 22]:
#                     continue
#                 itemlist.append(val)
#             if  mkt == "OTC":
#                 neworder = list(range(0,11)) + [17] + list(range(11,17)) + [18]
#                 itemlist = [itemlist[i] for i in neworder]   
#             ItemData.append(itemlist)
#     # 產生DataFrame
#     df_vol = pd.DataFrame(ItemData, columns = Header).sort_values(by =  ["投信買賣超股數"], ascending = False) 
#     file.genFiles(cfgname, df_vol, volfile, "csv")
#     return

# def writeRawDataFile(api, StkDF, cfgname):  
#     Stk_list = StkDF["StockID"].to_list()
#     file_exist = ""
#     fpath = cfg.getConfigValue(cfgname, "filepath")
#     # bkpath = cfg.getConfigValue(cfgname, "bkpath")
#     dypath = cfg.getConfigValue(cfgname, "dailypath")
#     hisfile = f"{fpath}/" + cfg.getConfigValue(cfgname, "hisname") + ".csv"
#     first = True
#     # # 建立目錄,不存在才建...(./data)
#     if os.path.exists(fpath) == False:
#         os.makedirs(fpath)
#     if os.path.exists(dypath) == False:
#         os.makedirs(dypath)    
#     #檔案存在就把它抓出來變成dataframe        
#     if os.path.isfile(hisfile) == True:
#         file_exist = "X"
#         df_history = pd.read_csv(hisfile, low_memory = False)
#         df_history["StockID"] = df_history["StockID"].apply(str)
#         # 存一個DF是這次沒有要抓資料的
#         df_notinlist = df_history[~df_history.StockID.isin(Stk_list)]
#         # 這個DF是這次有用到的History Data
#         df_history = df_history[df_history.StockID.isin(Stk_list)] 
#         # 抓出History中的最後一個日期               
#         df_tmp = df_history.sort_values(by = "ts_date", ascending = False)
#         dfbk_date = (datetime.strptime(df_tmp["ts_date"].head(1).values[0], "%Y-%m-%d")).strftime("%Y%m%d")
    
#     for id in Stk_list:        
#         for i in range(0, 10):
#             # 算出最近有資料的那一天
#             data_date = date.today() - timedelta(days = i)
#             stk_today = pd.DataFrame({**api.kbars(api.Contracts.Stocks[id], start = data_date.strftime("%Y-%m-%d"))})
#             if not stk_today.empty:
#                 tmp_df = stk_today
#                 stk_today["ts_date"] = pd.to_datetime(stk_today.ts).dt.date
#                 stk_today["ts_time"] = pd.to_datetime(stk_today.ts).dt.time
#                 stk_today.insert(0, "StockID", str(id))
#                 stk_today = stk_today.sort_values(by = "ts")
#                 break
#         # 資料日期的最後一天 = 備份資料的最後一天,就離開程式不用更新    
#         if data_date.strftime("%Y%m%d") == dfbk_date:
#             return
        
#         # 約抓一年份的資料
#         # d_range = [datetime.strptime(f"{date.today().year - 1}-01-01", "%Y-%m-%d"), date.today()]
#         d_range = [data_date - timedelta(days = 400), data_date]

#         if file_exist == "X":
#             his_df = df_history.loc[df_history["StockID"] == str(id)].sort_values(by = "ts_date")
#             if not his_df.empty:
#                 # 把Range的開始換成資料庫日期的最後一天 + 1
#                 d_range[0] = datetime.strptime(his_df["ts_date"].tail(1).values[0], "%Y-%m-%d") + timedelta(days = 1)
        
#         # 資料庫最後日期 > 最近有資料日期=>表示資料有更新"最近有資料的那一天",就換下一個股票
#         if d_range[0].strftime("%Y-%m-%d") > d_range[1].strftime("%Y-%m-%d"):
#             continue
            
#         # 資料庫最後日期 < 最近有資料日期 => 把今天抓的放進stk_df,其他的再補抓    
#         if d_range[0].strftime("%Y-%m-%d") < d_range[1].strftime("%Y-%m-%d"):
#             # 不要用d_range[1]..後面可能會有"同一天"的問題產生
#             to_date = data_date - timedelta(days = 1)
#             # 收集其他天的資料(遇到週一,stk_df會是空的) 
#             stk_df = pd.DataFrame({**api.kbars(api.Contracts.Stocks[id], start = d_range[0].strftime("%Y-%m-%d"), end = to_date.strftime("%Y-%m-%d"))})
#             # 把前面己經抓今天的資料放進來
#             # df_tmp = stk_today.drop(columns = ["StockID", "ts_datetime"])
#             if stk_df.empty:
#                 stk_df = tmp_df
#             else:    
#                 stk_df = stk_df.append(tmp_df)

#         # 資料庫最後日期 = 最近有資料日期 => 把抓到的今天資料放進來
#         if d_range[0].strftime("%Y-%m-%d") == d_range[1].strftime("%Y-%m-%d"):
#             stk_df = tmp_df
#         # 轉換日期格式(Grouping使用)
#         stk_df["ts_date"] = pd.to_datetime(stk_df.ts).dt.date
#         stk_df = stk_df.sort_values(by = "ts")
#         stk_df = stk_df.groupby("ts_date", sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
#         stk_df.insert(0, "StockID", str(id))
#         if first == True:
#             df_new = stk_df
#             df_today = stk_today
#             first = False
#         else:
#             df_new = df_new.append(stk_df)
#             df_today = df_today.append(stk_today)
#     # 把今天的部份留一份下來寫DB用        
#     df_todb = df_new.rename(columns = {"ts_date": "TradeDate"})

#     # 把歷史資料放進DF中
#     if file_exist == "X":
#         # hisbkfile = f"{bkpath}/" + cfg.getConfigValue(cfgname, "hisname") + f"_to_{dfbk_date}.csv"
#         hisbkfile = f"{dypath}/" + cfg.getConfigValue(cfgname, "hisname") + f"_to_{dfbk_date}.csv"
#         df_history["ts_date"] = pd.to_datetime(df_history["ts_date"], format = "%Y-%m-%d").dt.date
#         # 把沒有在StockList中的再寫回今天的DF
#         if not df_notinlist.empty:
#             df_notinlist["ts_date"] = pd.to_datetime(df_notinlist["ts_date"], format = "%Y-%m-%d").dt.date
#             df_new = df_new.append(df_notinlist)    
#         df_new = df_new.append(df_history)
#         # if os.path.exists(bkpath) == False:
#         #     os.makedirs(bkpath)
#         # 把原本的資料備存(太早備存有Bug就要一直搬回來)
#         try:
#             os.rename(hisfile, hisbkfile)
#         except FileExistsError:
#             os.remove(hisbkfile) 
#             os.rename(hisfile, hisbkfile)
    
#     # 累積的歷史資料
#     df_new = df_new.sort_values(by = ["StockID", "ts_date"], ascending = True).reset_index(drop = True)
#     file.genFiles(cfgname, df_new, hisfile, "csv")

#     fname = f"{dypath}/" + cfg.getConfigValue(cfgname, "kbarname") + f"_{data_date}.csv"
#     df_today = df_today.sort_values(by = ["StockID", "ts_date", "ts_time"]).reset_index(drop = True)
#     file.genFiles(cfgname, df_today, fname, "csv")
#     return

# def mergeVolumeDataFile(dframe, cfgname):
#     # 找出這次資料的最後一筆日期
#     df = dframe.sort_values(by = "TradeDate", ascending = False)
#     df_ymd = df["TradeDate"].head(1).values[0].strftime("%Y%m%d")
#     # 取出檔案清單,同時檢查需要的檔案是否存在
#     dlypath = cfg.getConfigValue(cfgname, "dailypath")
#     volfilename = cfg.getConfigValue(cfgname, "volname") + f"_{df_ymd}.csv"
#     volfullpath = dlypath + "/" + volfilename
#     file_list = sorted([s for s in os.listdir(dlypath) if cfg.getConfigValue(cfgname, "volname") in s], reverse = True)
#     try:
#         file_list.index(volfilename)
#     except:
#         return
#         # writeLegalPersonDailyVolumeFile(cfgname)
#     vol_df = pd.read_csv(volfullpath, low_memory = False).filter(items = ["證券代號", "投信買賣超股數"]).rename(columns = {"證券代號": "StockID"})
#     vol_df.insert(0, "ts_date", df["ts_date"].head(1).values[0])
#     return dframe.merge(vol_df, on = ["StockID", "ts_date"], how = "left")
# def getBSobj(YYYYMMDD, market, cfgname):
#     head_info = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
    
#     # 上市
#     if market == "TSE":
#         # 網頁取得自 https://www.twse.com.tw/zh/page/trading/fund/T86.html (列印 / HTML)
#         # url = f"https://www.twse.com.tw/fund/T86?response=html&date={YYYYMMDD}&selectType=ALL"
#         url = f"https://www.twse.com.tw/fund/T86?response=html&date={YYYYMMDD}&selectType=ALLBUT0999"
#     # 上櫃
#     if market == "OTC":
#         # 網頁取得自 https://www.tpex.org.tw/web/stock/3insti/daily_trade/3itrade_hedge.php?l=zh-tw (列印/匯出HTML)
#         ymd = f"{str(int(YYYYMMDD[0:4]) - 1911)}/{YYYYMMDD[4:6]}/{YYYYMMDD[6:8]}"
#         url = f"https://www.tpex.org.tw/web/stock/3insti/daily_trade/3itrade_hedge_result.php?l=zh-tw&o=htm&se=EW&t=D&d={ymd}&s=0,asc"
#     # 處理網址
#     urlwithhead = req.get(url, headers = head_info)
#     urlwithhead.encoding = "utf-8"
#     # 抓config檔決定是否要產生File
#     genfile = cfg.getConfigValue(cfgname, "genhtml")

#     # 判斷是否要產生File,不產生就直接把BS Obj傳出去
#     if genfile != "":
#         ## 寫網頁原始碼到檔案中cfg是config檔的路徑及檔名
#         wpath = cfg.getConfigValue(cfgname, "webpath")
#         # 產生出的檔案存下來
#         ## 建立目錄,不存在才建...
#         if os.path.exists(wpath) == False:
#             os.makedirs(wpath)
#         rootlxml = bs(urlwithhead.text, "lxml")
#         with open(f"{wpath}/{market}_三大法人買賣超日報_{YYYYMMDD}.html", mode="w", encoding="UTF-8") as web_html:
#             web_html.write(rootlxml.prettify())

#     #傳出BeautifulSoup物件     
#     return bs(urlwithhead.text, "lxml")

# def getTBobj(bsobj, tbID, market, cfgname):
#     tb = bsobj.find_all("table")[tbID]
#     # 抓config檔決定是否要產生File
#     genfile = cfg.getConfigValue(cfgname, "genhtml")
#     # 判斷是否要產生File,不產生就直接把BS Obj傳出去
#     if genfile != "":
#         ## 寫網頁原始碼到檔案中cfg是config檔的路徑及檔名
#         wpath = cfg.getConfigValue(cfgname, "webpath")
#         # 產生出的檔案存下來
#         ## 建立目錄,不存在才建...
#         if os.path.exists(wpath) == False:
#             os.makedirs(wpath)
#         with open(f"{wpath}/{market}_table.html", mode="w", encoding="UTF-8") as web_html:
#             web_html.write(tb.prettify())
#     return tb

# def getHeaderLine(tbObj):
#     headtext = []
#     for head in tbObj.select("table > thead > tr:nth-child(2) > td"):
#         headtext.append(head.text)
#     return headtext


