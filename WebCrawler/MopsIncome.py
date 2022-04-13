# %%
from datetime import date
from util.Tools import FileProcess as fp, Calcuate as cal, DB, Web
from util.Tools import wlog



if __name__ == "__main__":

    wlog.info("Start")

    # 取得以今天做base的前一個年,月
    YMLst = cal.calYearQuarterMonthValue(baseday = date.today(), step = -1, qm = "M", ce = False)
    # 取得月的第一天
    FirstDate = cal.calFirstDate(period = YMLst, qm = "M", ce = False)

    # Get Parameter from Config
    ## 市場別{"sii": "上市公司", "otc": "上櫃公司", "rotc": "興櫃公司", "pub": "公開發行公司"}
    marketDict = fp().getConfigValue(key = "market")
    ## 產業別["半導體", "電子工業"]
    industryLst = fp().getConfigValue(key = "industy")


    for key, dictval in marketDict.items():
        # 0.參數準備:組一個input的List
        inputInfo = YMLst.copy()
        inputInfo.append(key)
        # 1.從web抓需要的資料
        ## 取得BeautifulSoup所產生的Object
        bsObj = Web().getBSobject(inLst = inputInfo, fun = "I")
        ## 沒有取到網頁,寫Log
        if bsObj == None:
            wlog.info(f"尚未取得{dictval} ({key}) : {FirstDate.year} / {FirstDate.month} 的營收資料!!")
            continue
        ## 取得Table Object
        tbObj = Web(bsObj).getTBobject(inLst = inputInfo, findTB = industryLst)

        # 2.從第3個Row開始loop起(Row 3 以後是資料)
        for rows in tbObj.select("table > tr")[2:]:
            pass
        break
# %%
