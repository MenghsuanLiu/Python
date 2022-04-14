# %%
from datetime import date
from util.Tools import FileProcess as fp, Calcuate as cal, DB, Web
from util.Tools import wlog

def checkRowDataIsEmpty(irow: any)->bool:
    try:
        if irow.select("td") == []:
            return True
        if irow.select("th")[0].text == "合計":
            return True
    except:
        pass
    return False


if __name__ == "__main__":

    wlog.info("Start")

    # 取得以今天做base的前一個年,月
    YMLst = cal.calYearQuarterMonthValue(baseday = date.today(), step = -1, qm = "M", ce = False)
    # 取得月的第一天
    FirstDate = cal.calFirstDate(period = YMLst, qm = "M", ce = False)
    # 取得LSPF的Revenue
    LSPFRevenue = DB().getLSPFRevenueByPeriod(fdate = FirstDate)

    # Get Parameter from Config
    ## 市場別{"sii": "上市公司", "otc": "上櫃公司", "rotc": "興櫃公司", "pub": "公開發行公司"}
    marketDict = fp().getConfigValue(key = "market")
    ## 產業別["半導體", "電子工業"]
    industryLst = fp().getConfigValue(key = "industy")

    ItemData = []
    for key, mktval in marketDict.items():
        # 0.參數準備:組一個input的List
        inputInfo = YMLst.copy()
        inputInfo.append(key)
        # 1.從web抓需要的資料
        ## 取得BeautifulSoup所產生的Object
        bsObj = Web().getBSobject(inLst = inputInfo, fun = "I")
        ## 沒有取到網頁,寫Log
        if bsObj == None:
            wlog.info(f"尚未取得{mktval} ({key}) : {FirstDate.year} / {FirstDate.month} 的營收資料!!")
            continue
        ## 取得Table Object
        tbObj = Web(bsObj).getTBobject(inLst = inputInfo, findTB = industryLst)

        # 2.從第2個Table開始loop起, 抓出每一個Row()
        for rows in tbObj.select("table > tr")[2:]:
            # 2.1.檢查是否要換下一筆
            if checkRowDataIsEmpty(irow = rows):
                continue
            iLst = []
            # 2.2.日期
            iLst.append(str(FirstDate))
            # 2.3.市場別
            iLst.append(mktval)
            # 2.4.公司代號/公司名稱/當月營收/上月營收/去年當月營收/上月比較增減(%)/去年同月增減(%)/當月累計營收/去年累計營收/前期比較增減(%)/備註
            for i in range(1, len(rows.select("td")) + 1):
                iLst.append(Web(obj = rows).getItemValue(key = i, fun = "I"))
            # 2.5.PSMC要拆item,同時加一欄BU
            if iLst[2] == "6770":
                iLstBK = iLst.copy()
                iLstBK[4] = LSPFRevenue
                iLstBK.append("L")
                iLstBK.append(int(LSPFRevenue) * 1000)
                ItemData.append(iLstBK)

                iLst[4] = iLst[4] - LSPFRevenue
                iLst.append("M")
            else:
                iLst.append("")
            # 2.6.再加一欄算出revenue(到個位數)
            iLst.append(int(iLst[4]) * 1000)

            # 3.收集所有的Item產生[[],[]...]
            ItemData.append(iLst)
    # 產生Excel
    fp(obj = tbObj, idata = ItemData).generateDataToExcelFile(fun = "I", period = YMLst)
    # 公司主檔資料進DB
    # DB(idata = ItemData).updateDataToTable(fdate = FirstDate, tbname = "BIDC.dbo.mopsStockCompanyInfo")
    # 公司營收資料進DB
    DB(idata = ItemData).updateDataToTable(fdate = FirstDate, tbname = "BIDC.dbo.mopsFinancialByCompany")

    wlog.info("End")
# %%
