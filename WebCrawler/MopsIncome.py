# %%
import os
import re
import requests as req
import pandas as pd
import datetime
import pymssql
import json
# import lxml
from dateutil.relativedelta import relativedelta
from bs4 import BeautifulSoup as bs
from util.Logger import create_logger

# 取BeautifulSoup物件
def getBSobj_genFile(Category, YM, genfile, wpath):
    head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
    url_model = "https://mops.twse.com.tw/nas/t21/{}/t21sc03_{}_0.html"
    # 處理網址
    url = url_model.format(Category, YM)
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "big5"
    
    ## 寫網頁原始碼到檔案中(有值就要產生File)
    if genfile != "":
        # 產生出的檔案存下來
        ## 建立目錄,不存在才建...    
        if os.path.exists(wpath) == False:
            os.makedirs(wpath)
        rootlxml = bs(urlwithhead.text, "lxml")
        with open ( web_path + "/imcome_" + Category + "_" + YM + ".html", mode = "w", encoding = "UTF-8") as web_html:
            web_html.write(rootlxml.prettify())
    #傳出BeautifulSoup物件
    return bs(urlwithhead.text, "lxml")

# 取得公司產業類別名稱
def get_CompIndustry(TBobj):
    return TBobj.find("tr").find("th").text.split("：")[1]

# 取得Header Data
def get_Header(TBobj):
    headtext = []
    for head_line1 in TBobj.select("table > tr:nth-child(1) > th:nth-child(4)"):
        headtext.append("資料年月")
        for head_line2 in tb.select("table > tr:nth-child(2) > th"):
            # print(re.sub('<br\s*?>', ' ', head_line2.text))
            headtext.append(re.sub('<br\s*?>', ' ', head_line2.text))
        # print(head_line1.text)
        for head_list in [ head_line1.text, "上市/上櫃", "BU" ]:
            headtext.append(head_list)
    return headtext

def get_SQLdata(SQLconn, sqlselect):
    df_comp = pd.read_sql(sqlselect, SQLconn)
    return df_comp

def check_CompExist(comp_df, chk_stockid):
    status = shownname = ""
    df_list = comp_df.loc[comp_df["StockID"] == chk_stockid[0]]
    if df_list.empty == True:
        status =  "append"
    elif df_list["StockName"].values != chk_stockid[1] or df_list["Market"].values != chk_stockid[2] or df_list["Industry"].values != chk_stockid[3]:
        # 做modify時要保留showname
        status =  "modify"
        shownname = df_list["EnShowName"].values[0]
    return status, shownname
# 針對PSMC要計算L及M的當月revenue(計算LSPF的,Memory用扣的)
def splitPSMCRevenueByBU(list):
    if list[1] == "6770":
        ym = list[0]
        ym = ym.split("-")[0] + str(ym.split("-")[1] if int(ym.split("-")[1]) >= 10 else "0" + ym.split("-")[1]) +"%"

        with pymssql.connect( server = "8AEISS01", user = "sap_user", password = "sap##1405", database = "BIDC" ) as conn:
            with conn.cursor() as cursor:
                cursor.execute("""SELECT SUM(revenu) as val 
                                    FROM ( 
                                        SELECT SUM(IIF( FKART NOT IN ({type1}, {type2}), LNETW * -1, LNETW)) as revenu
                                            FROM SAP.dbo.sapRevenue
                                            WHERE FKDAT LIKE {date1}
                                        UNION
                                        SELECT SUM(IIF( FKART NOT IN ({type1}, {type2}), LNETW * -1, LNETW)) as revenu
                                            FROM F12SAP.dbo.sapRevenue
                                            WHERE FKDAT LIKE {date1}
                                        ) as a""".format(type1 = "F2", type2 = "L2", date1 = ym) )
                revenueval = round([float(r[0]) for r in cursor.fetchall()][0] / 1000, 0)
    else:
        revenueval = 0
    return revenueval
# 取得欄位中的值
def get_tbColval(rowlist, colid):
    val = ""
    td_id = "td:nth-child(" + str(colid) + ")"
    for col in rowlist.select(td_id):
        if colid in (1, 2, 11):
            val = col.string.strip().replace("-", "")
        else:
            val = col.text.replace(",", "").strip()
    return val 

def getConfigData(file_path, datatype):
    with open(file_path, encoding = "UTF-8") as f:
        jfile = json.load(f)
    list_val = jfile[datatype]
    return list_val

def writeExcel(DataH, DataI, fname, genxls):
    if genxls != "":
        if DataH != [] and DataI !=[]:
            # 存成檔案時的目錄
            file_path = "./data/download_file"
        # 建立目錄,不存在才建...
            if os.path.exists(file_path) == False:
                os.makedirs(file_path)

            df_imcome = pd.DataFrame(DataI, columns = DataH)
            ## 寫到Excel
            try:
                df_imcome.to_excel(file_path + "/" + fname + ".xlsx", index = False)
                logger.info("Create " + file_path + "/" + fname + ".xlsx Success!! \n")
                return print("Create " + fname + ".xlsx Success!!")
            except:
                logger.info("Create " + file_path + "/" + fname + ".xlsx Fail!! \n")
                return print("Create " + fname + ".xlsx Fail!!")
        else:
            logger.info("No Data to Create Excel File! \n")
            return print("Did not Collect Data!!")
    else:
        logger.info("不需要產生Excel的檔案! \n")

        # print(df_imcome)
        ## 寫到csv
        # file_name = "{}_{}_{}".format(ind, catg, period)
        # for en in ["UTF-8", "BIG5"]:
        #     # df_imcome.to_csv(file_path + "/" + file_name + "_" + en.replace("-", "") + ".csv", encoding = en, index = False )
        #     df_imcome.to_csv(file_path + "/revenue_" + en.replace("-", "") + ".csv", encoding = en, index = False )
        
def getComplist_mssql():
    cols = ["StockID", "StockName", "Market", "Industry", "EnShowName"]
    with pymssql.connect( server = "RAOICD01", user = "owner_sap", password = "oic#sap21o4", database = "BIDC" ) as conn:
        with conn.cursor() as cursor:
            cursor.execute("SELECT StockID, StockName, Market, Industry, EnShowName FROM BIDC.dbo.mopsStockCompanyInfo")
            quary = cursor.fetchall()
            df_list = pd.DataFrame(quary, columns = cols)
    return df_list

def getMonthFromToday(num):
    num = num * -1
    # 年月日(用今天去抓想要的月)
    newdate = datetime.date.today() - relativedelta(months = num)
    # 用list包起來取得民國年月
    ym = [str( newdate.year - 1911 ) + "_" + str( newdate.month )]
    return ym

# %%
cfg_fname = "./config/config.json"
web_path = "./data/html_file"
dict_catg = {"sii": "上市公司", "otc": "上櫃公司", "rotc": "興櫃公司", "pub": "公開發行公司"}
# 取得需要抓取的年月清單
try:
    ym = getConfigData(cfg_fname, "yearmon")
except:
    ym = getMonthFromToday(-1)  #-1 往前一個月
# 取得市場類別的清單
stockcatg = getConfigData(cfg_fname, "stocktype") # stockcatg = ["sii", "otc", "rotc", "pub"]
# 取得產業別的清單
industy = getConfigData(cfg_fname, "industygroup") # industy = ["半導體", "電子工業"]
# 取得公司的清單(先前已存在資料庫中)
# df_Complist = getComplist_mssql()
# 判斷是否需要產生Excel File
up_xlsx = getConfigData(cfg_fname, "update_xls")



# %%
logger = create_logger("./log")
logger.info("Start \n")

data_head = []
data_item = []
data_company = []
key_list = []
ym_list = []
for catg in stockcatg:
    for period in ym:
        # 取得存入資料庫/檔案的資料年月
        yyyymm = period.split("_")
        yyyymm = str(int(yyyymm[0]) + 1911) + "-" + str(yyyymm[1]) + "-1"
        if yyyymm not in ym_list:
             ym_list.append(yyyymm)

        # 取得BeautifulSoup Data
        root = getBSobj_genFile(catg, period, "X", web_path) 

        # 取市場資訊            
        market = root.find("b")
        market = market.text.split("公司")[0]

        # 取table
        for ind in industy:
            logger.info(period + dict_catg[catg] + ind + "Start \n")
            try:
                tb = root.find("th", text = re.compile(".*" + ind)).find_parent("table")
            except:
                continue
            # 把取出的Table html資料存成File
            with open (web_path + "/tb_" + ind + "_" + catg + "_" + period + ".html", mode = "w", encoding = "UTF-8") as web_html:
                web_html.write(tb.prettify())
            # 取表頭資料
            if data_head == []:
                data_head = get_Header(tb)

# 取公司類別
            cmpindusty = get_CompIndustry(tb)

# Get Item =>從第3個Row開始loop起(Row 3 以後是資料)
            for rows in tb.select("table > tr")[2:]:
                StockID = get_tbColval(rows, 1)
                StockName = get_tbColval(rows, 2)
                CurrRevenue = get_tbColval(rows, 3)
                LastRevenue = get_tbColval(rows, 4)
                YoYRevenue = get_tbColval(rows, 5)
                LastPercent = get_tbColval(rows, 6)
                if LastPercent == "":
                    LastPercent = 0
                YoYPercent = get_tbColval(rows, 7)
                if YoYPercent == "":
                    YoYPercent = 0
                CurrCount = get_tbColval(rows, 8)
                LastCount = get_tbColval(rows, 9)
                DiffPercent = get_tbColval(rows, 10)
                if DiffPercent == "":
                    DiffPercent = 0
                Remark = get_tbColval(rows, 11)


                collect = [yyyymm, StockID, StockName, int(CurrRevenue), int(LastRevenue), int(YoYRevenue), float(LastPercent), float(YoYPercent), int(CurrCount), int(LastCount), float(DiffPercent), Remark, market]
                data_item.append(collect)
                # if StockID != "":
                #     key = [yyyymm, StockID]
                #     if key not in key_list:
                #         collect = [yyyymm, StockID, StockName, int(CurrRevenue), int(LastRevenue), int(YoYRevenue), float(LastPercent), float(YoYPercent), int(CurrCount), int(LastCount), float(DiffPercent), Remark, market]
                #         # 遇到PSMC要拆BU
                #         psmc_lspf_val = splitPSMCRevenueByBU(collect)
                #         if psmc_lspf_val == 0:
                #             collect.append("")
                #         else:
                #             collect_tmp = collect.copy()
                #             psmc_m_val = collect[3] - psmc_lspf_val
                #             collect_tmp[3] = psmc_lspf_val
                #             collect_tmp.append("L")
                #             data_item.append(collect_tmp)
                #             collect[3]  = psmc_m_val
                #             collect.append("M")
                #         data_item.append(collect)
                #         key_list.append(key)

                    
                    
                #     collect = [StockID, StockName, market, cmpindusty]
                #     if collect not in data_company:
                #         chk, shown = check_CompExist(df_Complist, collect)
                #         if chk == "append":
                #             collect.append("")
                #             data_company.append(collect)    
                #         if chk == "modify":
                #             collect.append(shown)
                #             data_company.append(collect)




""" if data_item != []:
    # 先刪資料
    for ym in ym_list:
        SQL_Delete = ("DELETE FROM BIDC.dbo.mopsRevenueByCompany WHERE YearMonth = '" + ym + "'")
        cursor.execute(SQL_Delete)
        conn_sql.commit()
        print(ym, "Data Deleted!!")

    # 寫資料到MS SQL(Revenue)
    SQL_Insert = ("INSERT INTO BIDC.dbo.mopsRevenueByCompany (YearMonth, StockID, Revenue, Remark, BU) VALUES (?, ?, ?, ?, ?);")
    # Insart資料
    for list in data_item:
        value = [ list[0], list[1], list[3]*1000, list[11], list[13] ]
        cursor.execute(SQL_Insert, value)
        conn_sql.commit()
    print("Revenue Data Update Complete!!")

# 寫資料到MS SQL(Company)
if data_company !=[]:
    SQL_Delete = ("DELETE FROM BIDC.dbo.mopsStockCompanyInfo WHERE StockID = ?")
    for id in data_company:
        value = [id[0]]
        cursor.execute(SQL_Delete, value)
        conn_sql.commit()
        print("Company ID", id[0], "Deleted!")

    SQL_Insert = ("INSERT INTO BIDC.dbo.mopsStockCompanyInfo (StockID, StockName, Market, Industry, EnShowName) VALUES (?, ?, ?, ?, ?)")
    for list in data_company:
        value = [ list[0], list[1], list[2], list[3], list[4] ]
        cursor.execute(SQL_Insert, value)
        conn_sql.commit()
        print("Company ID Data", list[0], "Updated!!") """
# conn_sql.close()
# %%
# 產生Excel File
writeExcel(data_head, data_item, "revenue", up_xlsx)
logger.info("Export Done! \n")