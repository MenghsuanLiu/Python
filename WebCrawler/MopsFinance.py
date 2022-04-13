# %%
from datetime import date
from util.Tools import FileProcess as fp, Calcuate as cal, DB, Web
from util.Tools import wlog

if __name__ == "__main__":
    wlog.info("Start")
    
    # 取得以今天做base的前一個年,季
    YQLst = cal.calYearQuarterMonthValue(baseday = date.today(), step = -1, qm = "Q", ce = True)
    # 取得這一季的第一天
    FirstDate = cal.calFirstDate(period = YQLst, qm = "Q")
    
    # 取得平均ExchangeRate
    AvgRate = DB().getAVGRateFromDB(YQLst, "Q")
    # 取得WaferQty
    WQtyDict = DB().getWaferQtyByPeriod(fdate = FirstDate)
    # 取得前三季的Income加總
    inComeDict = Web().getCurrentYearIncomeAccumulate(period = YQLst)
    # 取得前一季的cashFlow
    cashFlowDict =Web().getPreviousQuarterCashFlow(period = YQLst)

    # Get Parameter from Config
    ## 需要抓的友廠股票代碼
    StkLst = fp().getConfigValue(key = "stocklist")
    ## 需要抓會計科目的List
    G0Lst = fp().getConfigValue(key = "glst0")
    G1Lst = fp().getConfigValue(key = "glst1")
    G2Lst = fp().getConfigValue(key = "glst2")

    ItemData = []
    # Loop 需要抓的股票代碼
    for stkID in StkLst:
        # 0.參數準備:組一個input的List
        inputInfo = YQLst.copy()
        inputInfo.append(stkID)
        
        # 1.從web抓需要的資料
        ## 取得BeautifulSoup所產生的Object
        bsObj = Web().getBSobject(inLst = inputInfo, fun = "F")
        ## 沒有取到網頁,寫Log
        if bsObj == None:
            wlog.info(f"{stkID} 沒有 {YQLst[0]} Q{YQLst[1]} 的季度財報資料!!")
            continue
        
        ## 取第一個table(BalanceSheet)
        tbObj_Balance = Web(bsObj).getTBobject(inLst = inputInfo, findTB = 0)
        ## 取第二個table(Statement of Comprehensive Income)
        tbObj_Income = Web(bsObj).getTBobject(inLst = inputInfo, findTB = 1)
        ## 取第三個table(Cash Flows)
        tbObj_CashFlows = Web(bsObj).getTBobject(inLst = inputInfo, findTB = 2)       

        # 2.產生該StockID的List
        itemLst = []
        ## 2.1 StockID / Date / Rate / Qty8 / Qty12
        for val in (stkID, str(FirstDate), AvgRate, int(WQtyDict.get(stkID, "0")[0]), int(WQtyDict.get(stkID, "0")[1])):
            itemLst.append(val)

        ## 2.2 總資產(1XXX) / 總負債(2XXX) / 普通股股本(3110)
        for glkey in G0Lst:
            val = int(Web(tbObj_Balance).getItemValue(key = glkey)) * 1000
            itemLst.append(val)

        ## 2.3 營業收入(4000) / 營業毛利(5950) / 營業費用(6000) / 其他收益(6500) / 營業利益(6900) / 營業外收支(7000) / 母公司業主(8610) / 所得稅費用(7950)
        ##     稅後淨利(8200) / 稀釋每股盈餘(9850) / 研究發展費用(6300)
        for glkey in G1Lst:
            if glkey == "9750":
                val = float(Web(tbObj_Income).getItemValue(key = glkey)) - float(inComeDict[stkID][glkey])
            else:
                val = (int(Web(tbObj_Income).getItemValue(key = glkey)) - int(inComeDict[stkID][glkey])) * 1000
            itemLst.append(val)
        ## 2.4 稅前淨利(A10000) / 利息費用(A20900) / 折舊費用(A20100) / 攤銷費用(A20200)
        for glkey in G2Lst:
            val = (int(Web(tbObj_CashFlows).getItemValue(key = glkey)) - int(cashFlowDict[stkID][glkey])) * 1000
            itemLst.append(val)
        # 3.收集所有的Item產生[[],[]...]
        ItemData.append(itemLst)
    
    
    # 產生Excel
    fp(obj = bsObj, idata = ItemData).generateDataToExcelFile(fun = "F", period = YQLst)
    # 寫季度財報資料進DB
    DB(idata = ItemData).updateDataToTable(fdate = FirstDate, tbname = "BIDC.dbo.mopsFinancialByCompany")

    wlog.info("End")
