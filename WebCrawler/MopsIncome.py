# %%
import os
import re
import requests as req
import pandas as pd
import numpy as np
import datetime
import pymssql
import json
from dateutil.relativedelta import relativedelta
from bs4 import BeautifulSoup as bs
from util.Logger import create_logger
from util.EncryptionDecrypt import dectry

# 取BeautifulSoup物件
def getBSobj_genFile(Category, YM, genfile, wpath):
    head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
    url= f"https://mops.twse.com.tw/nas/t21/{Category}/t21sc03_{YM}_0.html"
    # 處理網址
    # url = url_model.format(Category, YM)
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "big5"
    
    ## 寫網頁原始碼到檔案中(有值就要產生File)
    if genfile != "":
        # 產生出的檔案存下來
        ## 建立目錄,不存在才建...    
        if os.path.exists(wpath) == False:
            os.makedirs(wpath)
        rootlxml = bs(urlwithhead.text, "lxml")
        with open ( f"{web_path}/imcome_{Category}_{YM}.html", mode = "w", encoding = "UTF-8") as web_html:
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

# def get_SQLdata(SQLconn, sqlselect):
#     df_comp = pd.read_sql(sqlselect, SQLconn)
#     return df_comp

def checkCompExist(comp_df, chk_stockid):
    if comp_df != None:
        df_list = comp_df.loc[comp_df["StockID"] == chk_stockid[0]]
        if df_list.empty == True:
            status =  "append"
        elif df_list["StockName"].values != chk_stockid[1] or df_list["Market"].values != chk_stockid[2] or df_list["Industry"].values != chk_stockid[3]:
            # 做modify時要保留showname
            status =  "modify"
            shownname = df_list["EnShowName"].values[0]
    else:
        status =  "append"    
    return status, shownname
# 針對PSMC要計算L及M的當月revenue(計算LSPF的,Memory用扣的)
def splitPSMCRevenueByBU(list, updb):
    revenueval = 0
    pwd_enc = "215_203_225_72_88_148_169_83_98_"
    pwd = dectry(pwd_enc)
    if updb != "" and list[1] == "6770":
        ym = list[0]
        ym = ym.split("-")[0] + str(ym.split("-")[1] if int(ym.split("-")[1]) >= 10 else "0" + ym.split("-")[1]) +"%"

        with pymssql.connect( server = "8AEISS01", user = "sap_user", password = pwd, database = "BIDC" ) as conn:
            with conn.cursor() as cursor:
                try:
                    type1, type2 = "F2", "L2"
                    cursor.execute(f"""SELECT SUM(revenu) as val 
                                        FROM ( 
                                            SELECT SUM(IIF( FKART NOT IN ('{type1}', '{type2}'), LNETW * -1, LNETW)) as revenu
                                                FROM SAP.dbo.sapRevenue
                                                WHERE FKDAT LIKE '{ym}'
                                            UNION
                                            SELECT SUM(IIF( FKART NOT IN ('{type1}', '{type2}'), LNETW * -1, LNETW)) as revenu
                                                FROM F12SAP.dbo.sapRevenue
                                                WHERE FKDAT LIKE '{ym}'
                                            ) as a""")
                    revenueval = round([float(r[0]) for r in cursor.fetchall()][0] / 1000, 0)
                except:
                    logger.exception("message")
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

def writeExcel(cfgfile, DataH, DataI, fname, genxls):
    if genxls != "":
        if DataH != [] and DataI !=[]:
            # 存成檔案時的目錄
            # file_path = r"./data/download_file"
            file_path = getConfigData(cfgfile, "filepath")
            # 建立目錄,不存在才建...
            if os.path.exists(file_path) == False:
                os.makedirs(file_path)
            # 最後一個欄位是為了寫資料庫加的
            for x in DataI:
                del x[-1]
            # 轉換成DataFrame    
            df_imcome = pd.DataFrame(DataI, columns = DataH)
            ## 寫到Excel
            try:
                df_imcome.to_excel(rf"{file_path}/{fname}.xlsx", index = False)
                logger.info(f"Create {file_path}/{fname}.xlsx Success!!")
                return print(f"Create {fname}.xlsx Success!!")
            except:
                logger.exception("message")
                return print(f"Create {fname}.xlsx Fail!!")
        else:
            logger.info("No Data to Create Excel File!")
            return print("Did not Collect Data!!")
    else:
        logger.info("不需要產生Excel的檔案!")

        # print(df_imcome)
        ## 寫到csv
        # file_name = "{}_{}_{}".format(ind, catg, period)
        # for en in ["UTF-8", "BIG5"]:
        #     # df_imcome.to_csv(file_path + "/" + file_name + "_" + en.replace("-", "") + ".csv", encoding = en, index = False )
        #     df_imcome.to_csv(file_path + "/revenue_" + en.replace("-", "") + ".csv", encoding = en, index = False )
        
def getComplist_mssql(db):
    df_list = []
    pwd_enc = "211_211_212_72_168_196_229_85_94_217_153_"
    pwd = dectry(pwd_enc)
    if db != "":
        head = ["StockID", "StockName", "Market", "Industry", "EnShowName"]
        with pymssql.connect( server = "RAOICD01", user = "owner_sap", password = pwd, database = "BIDC" ) as conn:
            with conn.cursor() as cursor:
                try:
                    cursor.execute("SELECT StockID, StockName, Market, Industry, EnShowName FROM BIDC.dbo.mopsStockCompanyInfo")
                    quary = cursor.fetchall()
                    df_list = pd.DataFrame(quary, columns = head)
                    return df_list
                except:
                    logger.exception("message")
                    return
    
def updateRevenue_mssql(db, DataI, ymlist):
    pwd_enc = "211_211_212_72_168_196_229_85_94_217_153_"
    pwd = dectry(pwd_enc)
    if db != "" and DataI != []:
        # 資料先做轉換
        ym_tuple = [x for x in zip(*[iter(ymlist)])]

        ary_data = np.array(DataI)
        item_tuple = list(map(tuple, ary_data[:,[0, 13, 1, 14, 11]]))
        # 連結資料庫
        with pymssql.connect( server = "RAOICD01", user = "owner_sap", password = pwd, database = "BIDC" ) as conn:
            with conn.cursor() as cursor:
                # 先刪資料
                try:      
                    cursor.executemany("DELETE FROM BIDC.dbo.mopsRevenueByCompany WHERE YearMonth = %s", ym_tuple)
                    conn.commit()
                    logger.info("mopsRevenueByCompany Delete Complete")
                except:
                    logger.exception("message")
                    return
                # 寫入資料
                try:
                    cursor.executemany("INSERT INTO BIDC.dbo.mopsRevenueByCompany (YearMonth, BU, StockID, Revenue, Remark) VALUES (%s, %s, %s, %d, %s)", item_tuple) 
                    conn.commit()
                    logger.info("mopsRevenueByCompany Insert Complete")
                except:
                    logger.exception("message")
                    return
 
# 更新DB中Company List的Data     
def updateCompList_mssql(Cdata, cfg):
    pwd_enc = "211_211_212_72_168_196_229_85_94_217_153_"
    pwd = dectry(pwd_enc)
    if db != "" and Cdata != []:
        ary_data = np.array(Cdata)
        sid_tuple = list(map(tuple, ary_data[:,0]))
        comp_tuple = list(map(tuple, ary_data))
        # 連結資料庫
        with pymssql.connect( server = "RAOICD01", user = "owner_sap", password = pwd, database = "BIDC" ) as conn:
            with conn.cursor() as cursor:
                # 先刪資料
                try:      
                    cursor.executemany("DELETE FROM BIDC.dbo.mopsStockCompanyInfo WHERE StockID = %s", sid_tuple)
                    conn.commit()
                    logger.info("mopsStockCompanyInfo Delete Complete")
                except:
                    logger.exception("message")
                    return

                # 寫入資料
                try:
                    cursor.executemany("INSERT INTO BIDC.dbo.mopsStockCompanyInfo (StockID, StockName, Market, Industry, EnShowName) VALUES (%s, %s, %s, %s, %s)", comp_tuple) 
                    conn.commit()
                    logger.info("mopsStockCompanyInfo Insert Complete")
                except:
                    logger.exception("message")
                    return    

def getMonthFromToday(num):
    num = num * -1
    # 年月日(用今天去抓想要的月)
    newdate = datetime.date.today() - relativedelta(months = num)
    # 用list包起來取得民國年月
    ym = [str( newdate.year - 1911 ) + "_" + str( newdate.month )]
    return ym


# %%
logger = create_logger("./log")
logger.info("Start")
cfg_fname = "./config/config.json"
# web_path = "./data/html_file"
dict_catg = {"sii": "上市公司", "otc": "上櫃公司", "rotc": "興櫃公司", "pub": "公開發行公司"}

# 取得需要抓取的年月清單
try:
    ym = getConfigData(cfg_fname, "yearmon")
except:
    ym = getMonthFromToday(-1)  #-1 往前一個月

# 取得web檔存放路徑
web_path = getConfigData(cfg_fname, "webpath") # web_path = "./data/html_file"
     
# 取得市場類別的清單
stockcatg = getConfigData(cfg_fname, "stocktype") # stockcatg = ["sii", "otc", "rotc", "pub"]

# 取得產業別的清單
industy = getConfigData(cfg_fname, "industygroup") # industy = ["半導體", "電子工業"]

# 判斷是否需要產生Excel File
up_xlsx = getConfigData(cfg_fname, "update_xls")

# 判斷是否Update DB
up_db = getConfigData(cfg_fname, "update_db")

# 取得公司的清單(先前已存在資料庫中)
df_Complist = getComplist_mssql(up_db)

# %%
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
            logger.info(f"{period} {dict_catg[catg]} {ind} Start")
            try:
                tb = root.find("th", text = re.compile(".*" + ind)).find_parent("table")
            except:
                continue
            # 把取出的Table html資料存成File
            with open (rf"{web_path}/tb_{ind}_{catg}_{period}.html", mode = "w", encoding = "UTF-8") as web_html:
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
                # 收集資料放到data_item,同時若遇到PSMC就要去拆BU計算
                if StockID != "":
                    key = [yyyymm, StockID]
                    if key not in key_list:
                        collect = [yyyymm, StockID, StockName, int(CurrRevenue), int(LastRevenue), int(YoYRevenue), float(LastPercent), float(YoYPercent), int(CurrCount), int(LastCount), float(DiffPercent), Remark, market]                        
                        # 遇到PSMC要拆BU
                        psmc_lspf_val = splitPSMCRevenueByBU(collect, up_db)
                        if psmc_lspf_val == 0:
                            collect.append("")
                            collect.append(int(CurrRevenue) * 1000)
                        else:
                            collect_tmp = collect.copy()
                            psmc_m_val = collect[3] - psmc_lspf_val
                            collect_tmp[3] = psmc_lspf_val
                            collect_tmp.append("L")
                            collect_tmp.append(int(psmc_lspf_val) * 1000)
                            data_item.append(collect_tmp)
                            collect[3]  = psmc_m_val
                            collect.append("M")
                            collect.append(int(psmc_m_val) * 1000)
                        data_item.append(collect)
                        key_list.append(key)
                    
                    # 收集公司清單的資料
                    collect = [StockID, StockName, market, cmpindusty]
                    if collect not in data_company:
                        chk, shown = check_CompExist(df_Complist, collect, up_db)
                        if chk == "append":
                            collect.append("")
                            data_company.append(collect)    
                        if chk == "modify":
                            collect.append(shown)
                            data_company.append(collect)
# %%
# 營收資料寫入資料庫中
updateRevenue_mssql(up_db, data_item, ym_list)

# 公司清單寫入資料庫中
updateCompList_mssql(up_db, data_company)

# 產生Excel File
writeExcel(cfg_fname, data_head, data_item, "revenue", up_xlsx)
logger.info("Export Done!")
