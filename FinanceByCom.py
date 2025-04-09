# %%
from util.Tools import wlog, DB, Web, FileProcess as fp, Calcuate as cal
import pandas as pd

# 留下的欄位名
col_keep = ["YQ_Date", "StockID", "Assets", "Liabilities", "Oper_Revenue", "GP_Oper", "Oper_Expenses", "NetOtherIncome", "NetOperIncome", "nonOperIncome", "PF_BeforeTax", "Profit", "PF_AttrOwners", "Inter_Expense", "Tax_Expense", "DP_Expense", "Amor_Expense", "EPS", "RD_Expense", "OrdinaryShare", "WaferQty_12", "WaferQty_8", "PSMC_ExRate"]

tcol_fin = {
        "年度": "Year",
        "季別": "Quarter",
        "公司代號": col_keep[1],
        "營業收入": col_keep[4],
        "營業毛利（毛損）": col_keep[5],
        "營業費用": col_keep[6],
        "其他收益及費損淨額": col_keep[7],
        "營業利益（損失）": col_keep[8],
        "營業外收入及支出": col_keep[9],
        "稅前淨利（淨損）": col_keep[10],
        "所得稅費用（利益）": col_keep[14],
        "繼續營業單位本期淨利（淨損）": col_keep[11],
        "淨利（淨損）歸屬於母公司業主": col_keep[12],
        "基本每股盈餘（元）": col_keep[17],
        "資產總額": col_keep[2],
        "資產總計": col_keep[2],
        "負債總額": col_keep[3],
        "負債總計": col_keep[3],
        "股本": col_keep[19]
    }

# %%
if __name__ == "__main__":
    
    wlog.info("Start")
    # API List
    api_urls = fp().getConfigValue(key = "finance")
    # 目標公司
    target_com = fp().getConfigValue(key = "fc_com")
    # 取得Table中最後一個月份(做資料比對決定是否往後走)
    last_df = DB().getTableLastPeriodData(tbname = "mopsFinancialByCompany")
    # 取各公司前幾季加總資料,抓Year(Today()) - 1
    com_df = DB().getTableData(tbname = "mopsFinancialByCompany")

    full_df = pd.DataFrame()
    for market, urls in api_urls.items():
        wlog.info(f"正在處理 {market} 數據...")

        mkt_df = pd.DataFrame()
        for url in urls:
            # 1.由API獲取資料(DataFrame)
            # 2.遇到(mopsfin_t187ap07_O_ci)上櫃公司資產負債表(一般業)會有欄位是英文的狀況,需要轉換
            # 3.留下需要的公司(指定)
            # 4.留下需要的公司(跟Table資料比對)
            api_df = Web.fetchDataFromAPI(url, market)
            api_df = api_df.rename(columns={ "Date": "出表日期", "SecuritiesCompanyCode": "公司代號", "CompanyName": "公司名稱"})
            api_df = api_df[api_df["公司代號"].isin(target_com)]
            api_df = api_df[~api_df.set_index(["年度", "季別", "公司代號"]).index.isin(last_df.set_index(["年度", "季別", "公司代號"]).index)]
            # 沒資料就換下一個市場Loop
            if api_df.empty:
                break
            # 收集這個市場(上市/上櫃)的DataFrame,第一次做copy,第二次就做往後長欄位
            if mkt_df.empty:
                mkt_df = api_df.copy()
            else:
                mkt_df = pd.merge(mkt_df, api_df, on = ["出表日期", "年度", "季別", "公司代號", "公司名稱"], how = "left")
        # 這個市場(上市/上櫃)沒有資料就換下一個市場
        if mkt_df.empty:
            wlog.info(f"沒有需要更新的資料({market})....")
            continue
        # 欄位更名(有用到的才換)
        mkt_df.rename(columns = tcol_fin, inplace = True)
        # 先處理不需要計算的欄位的Type轉換
        cal_cols = [col_keep[2], col_keep[3], col_keep[-4]]
        mkt_df[cal_cols] = mkt_df[cal_cols].replace('', 0).fillna(0).apply(lambda col: (col.astype(float) * 1000).astype("int64"))
        # 取得需要計算的欄位名
        cal_cols = [col for col in com_df.columns if col in mkt_df.columns]
        cal_cols = [col for col in cal_cols if col not in ["Year", "StockID", "EPS"]]
        # 把欄位值轉換成數值並*1000(需處理空白及NA)
        mkt_df[cal_cols] = mkt_df[cal_cols].replace('', 0).fillna(0).apply(lambda col: (col.astype(float) * 1000).astype("int64"))        
        # EPS為Float需另外處理
        cal_cols.append("EPS")
        mkt_df[cal_cols[-1]] = mkt_df[cal_cols[-1]].replace('', 0).fillna(0).astype(float)
        # 取季存入Table的年月
        api_yq = [str(date) for date in mkt_df.Year.unique()][0]+"0"+[str(date) for date in mkt_df.Quarter.unique()][0]
        QDate = cal.getFirstDate(yyymm = api_yq, qm = "Q")
        # 取得平均ExchangeRate
        AvgRate = DB().getPSMCAvgRate(QDate)
        # 在此次的Loop中若有6770就要處理WaferQty
        if "6770" in mkt_df["StockID"].values:
            # 取得WaferQty
            wQty_df = DB().getPSMCWaferQty(fdate = QDate)
        # 給YQ_Date, PSMC_ExRate, WaferQty_12, WaferQty_8, Inter_Expense, DP_Expense, Amor_Expense, RD_Expense欄位,
        mkt_df[col_keep[0]]  = QDate
        mkt_df[col_keep[-1]] = AvgRate
        mkt_df[col_keep[-3]] = 0
        mkt_df[col_keep[-2]] = 0
        mkt_df[col_keep[13]] = 0
        mkt_df[col_keep[15]] = 0
        mkt_df[col_keep[16]] = 0
        mkt_df[col_keep[18]] = 0

        # 處理每一個Row的資料
        for idx, row in mkt_df.iterrows():
            # 6770要給出貨數量
            if row.StockID == "6770":
                mkt_df.at[idx, col_keep[-2]] = wQty_df.iloc[0][col_keep[-2]]
                mkt_df.at[idx, col_keep[-3]] = wQty_df.iloc[0][col_keep[-3]]

            # 取出己存在Table的資料(同年同公司代碼)
            com_row = com_df.query(f"Year == {row.Year} & StockID == '{row.StockID}'")
            # 沒取到代表這次資料為第一季
            if com_row.empty:
                    continue
            # 有資料就需要做計算(API資料-Table當年資料)
            for col in cal_cols:
                # 遇到EPS需要轉換(因row[col]為Float,com_row.iloc[0][col]為decimal.Decimal不能互減)
                if col == "EPS":
                    mkt_df.at[idx, col] = row[col]  - float(com_row.iloc[0][col])
                    continue
                if col in mkt_df.columns and col in com_row.columns:
                    mkt_df.at[idx, col] = row[col]  - int(com_row.iloc[0][col])
        # 留下mkt_df有的欄位,並寫入full_df
        exist_cols = [col for col in col_keep if col in mkt_df.columns]
        if full_df.empty:
            full_df = mkt_df[exist_cols]
        else:
            full_df = pd.concat([full_df, mkt_df[exist_cols]], ignore_index=True)

    # 產生Excel
    fp().genDataToExcel(fn = "F", fname = QDate.strftime("%Y%m%d"), df = full_df)
    # 寫資料回Table
    DB().updateDataToTable(df = full_df, fdate = "", tbname = "mopsFinancialByCompany")
    wlog.info("End")

# %%
