# https://openapi.twse.com.tw/
# https://www.tpex.org.tw/openapi/
# %%
from util.Tools import wlog, DB, Web, FileProcess as fp, Calcuate as cal
import pandas as pd
import sys

# %%
if __name__ == "__main__":
    wlog.info("Start")
    # API List
    api_urls = fp().getConfigValue(key = "revenue")
    # 留下的欄位名
    col_keep = ["StockID", "Revenue", "Remark"]
    # 欄位名轉換的Dict
    tcol_rev = {
        "公司代號": col_keep[0],
        "營業收入-當月營收": col_keep[1],
        "備註": col_keep[2]
    }
    tcol_com = {
        "公司代號": col_keep[0],
        "公司名稱": "StockName",
        "產業別": "Industry"
    }
    # 需要關注的產業別
    target_inds = fp().getConfigValue(key = "fc_industy")
   
    # 建立一個空白的DataFrame
    urev_df = pd.DataFrame()
    ucmp_df = pd.DataFrame()
    # 取得Table中最後一個月份(做資料比對決定是否往後走)
    last_ym = DB().getTableLastPeriodData(tbname = "mopsRevenueByCompany")
    # 取公司清單
    com_tb = DB().getTableData(tbname = "BIDC.dbo.mopsStockCompanyInfo")

    # 由API取得資料
    for market, url in api_urls.items():
        wlog.info(f"正在處理 {market} 數據...")
        # 1.由API獲取資料(DataFrame)
        # 2.留下需要的產業
        api_df = Web.fetchDataFromAPI(url, market)
        api_df = api_df[api_df["產業別"].isin(target_inds)]
        # api取回資料的年月抓第一筆代表
        api_ym = [str(date) for date in api_df["資料年月"].unique()][0]
        # 比較資料時間:歷史資料最新年月 = API的資料年月,就離開
        if last_ym == api_ym:
            continue
        # 1.備份DF讓公司資料用
        # 2.加市場欄位
        # 3.欄位改名
        # 4.留下需要的欄位
        # 5.比對留下沒有在DB Table的部份
        com_df = api_df.copy()
        com_df["Market"] = market
        com_df.rename(columns = tcol_com, inplace = True)
        com_df = com_df[["StockID", "StockName", "Market", "Industry"]]
        com_df = com_df[~com_df["StockID"].isin(com_tb["StockID"])]
        # 1.需要進Table的欄位做名稱轉換
        # 2.對營收欄位做值的轉換+000
        # 3.留下需要用的欄位
        # 4.加BU欄位
        # 5.把Remark中的短線變空白
        api_df.rename(columns = tcol_rev, inplace = True)
        api_df["Revenue"] = api_df["Revenue"] + "000"
        api_df = api_df[col_keep]
        api_df["BU"] = ""
        api_df["Remark"] = api_df["Remark"].replace("-", "")
        # 遇到資料有PSMC時要拆BU
        if "6770" in api_df["StockID"].values:
            # 取LSPF的該月revenue
            lspf_revenue = DB().getLRevenueByPeriod(yyymm = api_ym)
            # 取出6770那一筆同時加入BU
            df_psmc = api_df.query('StockID == "6770"').assign( BU = "L", Revenue = lspf_revenue)
            # 把api取回的那一筆做成M BU的資料    
            api_df.loc[api_df["StockID"] == "6770", ["BU", "Revenue"]] = ["M", int(api_df.query('StockID == "6770"')["Revenue"]) - lspf_revenue]
            # 把L BU的資料併回原來的DataFrame
            api_df = pd.concat([api_df, pd.DataFrame(df_psmc, columns = api_df.columns)], ignore_index=True)
        # 收集要存進DB的資料
        urev_df = pd.concat([urev_df, api_df], ignore_index=True)
        ucmp_df = pd.concat([ucmp_df, com_df], ignore_index=True)
    # 遇到空值就離開程式
    if urev_df.empty:
        wlog.info("沒有資料需要被更新!!!")
        wlog.info("End")
        sys.exit()
    
    # 產生Excel
    fp().genDataToExcel(fn = "R", fname = last_ym, df = urev_df)
    fp().genDataToExcel(fn = "C", fname = "", df = ucmp_df)

    # 寫資料回Table
    fstDate = cal.getFirstDate(yyymm = api_ym, qm = "M")
    urev_df["YearMonth"] = fstDate
    DB().updateDataToTable(df = urev_df, fdate = fstDate, tbname = "mopsRevenueByCompany")
    DB().updateDataToTable(df = ucmp_df, fdate = "", tbname = "mopsStockCompanyInfo")


    wlog.info("End")
