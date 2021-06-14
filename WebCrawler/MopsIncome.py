# %%
import os
import re
from bs4.element import CData
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

# 取得config檔中的資料
def getConfigData(file_path, datatype):
    try:
        with open(file_path, encoding = "UTF-8") as f:
            jfile = json.load(f)
        return ({True: None, False: jfile[datatype]}[jfile[datatype] == "" or jfile[datatype] == "None" or jfile[datatype] ==[]])
    except:
        return None

# 取BeautifulSoup物件[產業別, 年月, 設定檔路徑]
def getBSobj_genFile(Catg_YM_cfg):
    head_info = {"User-Agent":"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"}
    url= f"https://mops.twse.com.tw/nas/t21/{Catg_YM_cfg[0]}/t21sc03_{Catg_YM_cfg[1]}_0.html"
    # 處理網址
    # url = url_model.format(Category, YM)
    urlwithhead = req.get(url, headers = head_info)
    urlwithhead.encoding = "big5"
    genfile = getConfigData(Catg_YM_cfg[2], "gen_html")


    ## 寫網頁原始碼到檔案中(有值就要產生File)
    if genfile != None:
        wpath = getConfigData(Catg_YM_cfg[2], "webpath")
        # 產生出的檔案存下來
        ## 建立目錄,不存在才建...    
        if os.path.exists(wpath) == False:
            os.makedirs(wpath)
        rootlxml = bs(urlwithhead.text, "lxml")
        with open ( f"{wpath}/imcome_{Catg_YM_cfg[0]}_{Catg_YM_cfg[1]}.html", mode = "w", encoding = "UTF-8") as web_html:
            web_html.write(rootlxml.prettify())
    #傳出BeautifulSoup物件
    return bs(urlwithhead.text, "lxml")

# 取得Table Object From BS Object
def getTBobj_genFile(bsobj, Catg_YM_cfg, ind):
    try:
        tb = bsobj.find("th", text = re.compile(".*" + ind)).find_parent("table")
    except:
        return None
    
    genfile = getConfigData(Catg_YM_cfg[2], "gen_html")
    if genfile != None:
        web_path = getConfigData(Catg_YM_cfg[2], "webpath")
        with open (f"{web_path}/tb_{ind}_{Catg_YM_cfg[0]}_{Catg_YM_cfg[1]}.html", mode = "w", encoding = "UTF-8") as web_html:
            web_html.write(tb.prettify())
    return tb    

# 取得民國年月...從今天開始算,出來就是List
def getChineseMonthFromToday(num):
    num = num * -1
    # 年月日(用今天去抓想要的月)
    newdate = datetime.date.today() - relativedelta(months = num)
    # 用list包起來取得民國年月
    ym = [str( newdate.year - 1911 ) + "_" + str( newdate.month )]
    return ym

# 取得民國年List
def getChineseYearMonthList(cfg):
    ym = getConfigData(cfg, "manual_yearmon")
    if ym == None:
        return getChineseMonthFromToday(-1)
    else:
        if not isinstance(ym, list):
            return [ym]
        else:
            return ym

# 取得公司類別代碼及中文說明
def getCategoryChinseseDesc(cfg):
    catglist = getConfigData(cfg, "stocktype")
    ym = getChineseYearMonthList(cfg)[0]
    market_list = []

    for catg in catglist:
        lst = [catg, ym, cfg]
        # 取得BeautifulSoup Data
        BS_Obj = getBSobj_genFile(lst)
        # 取得市場的名稱
        market_list.append(getMarketNameFromBSObj(BS_Obj) + "公司")
    return dict(zip(catglist, market_list))

def ChineseYearMonToCE(ymval):
    yyymm = ymval.split("_")
    return str(int(yyymm[0]) + 1911) + "-" + str(yyymm[1]) + "-1"

# 取得Header Data
def getHeaderLine(cfg):
    catg = getConfigData(cfg, "stocktype")[0]   # 只要抓第一個就好
    ym = getChineseYearMonthList(cfg)[0]    # 只要抓第一個就好
    data_lst = [catg, ym, cfg]
    industy = getConfigData(cfg, "industygroup")[0] # 只要抓第一個就好
    BSobj = getBSobj_genFile(data_lst)
    TBobj = getTBobj_genFile(BSobj, data_lst, industy)

    headtext = []
    for head_line1 in TBobj.select("table > tr:nth-child(1) > th:nth-child(4)"):
        headtext.append("資料年月")
        for head_line2 in TBobj.select("table > tr:nth-child(2) > th"):
            # print(re.sub('<br\s*?>', ' ', head_line2.text))
            headtext.append(re.sub('<br\s*?>', ' ', head_line2.text))
        # print(head_line1.text)
        for head_list in [ head_line1.text, "上市/上櫃", "產業別", "BU" ]:
            headtext.append(head_list)
    return headtext


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
        shownname = None   
    return status, shownname

# 針對PSMC要計算L及M的當月revenue(計算LSPF的,Memory用扣的)
def splitPSMCRevenueByBU(list):
    revenueval = 0
    pwd_enc = "215_203_225_72_88_148_169_83_98_"
    pwd = dectry(pwd_enc)
    try:
        if list[1] == "6770":
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
                        return revenueval
                    except:
                        logger.exception("message")
                        return 0
        else:
            return 0    
    except:
        return 0

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

# 取得市場名名稱
def getMarketNameFromBSObj(bsobj):           
    market = bsobj.find("b")
    return market.text.split("公司")[0]

# 從DB的Company List取得現有的資料      
def getComplist_mssql():
    df_list = []
    pwd_enc = "211_211_212_72_168_196_229_85_94_217_153_"
    pwd = dectry(pwd_enc)
    try:
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
    except:
        return None

# 更新DB中Revenue的Data    
def updateRevenue_mssql(DataI, ymclist, cfg):
    pwd_enc = "211_211_212_72_168_196_229_85_94_217_153_"
    pwd = dectry(pwd_enc)
    up_db = getConfigData(cfg, "update_db")
    if up_db != None and DataI != []:
        # 先把進來的民國年月List轉換成DB用的西元年用
        ymlist = []
        for ym_c in ymclist:
            ym = ChineseYearMonToCE(ym_c)
            ymlist.append(ym)

        # 資料先做轉換 List to Tuple
        ym_tuple = [x for x in zip(*[iter(ymlist)])]
        ary_data = np.array(DataI)
        item_tuple = list(map(tuple, ary_data[:,[0, 14, 1, 15, 11]]))
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
def updateCompList_mssql(DataI, cfg):
    pwd_enc = "211_211_212_72_168_196_229_85_94_217_153_"
    pwd = dectry(pwd_enc)
    up_db = getConfigData(cfg, "update_db")
    if up_db != None:
        CData = []
        up_CData = []
        # 取得這次抓網站的資料List
        for l in DataI:
            CData.append([l[1], l[2], l[12], l[13]])
        # 取得公司的清單(先前已存在資料庫中)
        df_Complist = getComplist_mssql()
        # ************************************這段要再測過****
        if CData not in up_CData:
            chk, shown = checkCompExist(df_Complist, CData)
            if chk == "append":
                CData.append("")
                up_CData.append(CData)    
            if chk == "modify":
                CData.append(shown)
                data_company.append(CData)

        ary_data = np.array(data_company)
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
    else:
        logger.info("Config Without Update mopsStockCompanyInfo!!")
        return
        
# 寫資料到Excel
def writeExcel(DataH, DataI, cfgfile):
    # 判斷是否需要產生Excel File
    genxls = getConfigData(cfgfile, "update_xls")
    if genxls != None:
        if DataH != [] and DataI !=[]:
            # 存成檔案時的目錄
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
                df_imcome.to_excel(rf"{file_path}/Revenue.xlsx", index = False)
                logger.info(f"Create {file_path}/Revenue.xlsx Success!!")
                return print(f"Create Revenue.xlsx Success!!")
            except:
                logger.exception("message")
                return print(f"Create Revenue.xlsx Fail!!")
        else:
            logger.info("No Data to Create Excel File!")
            return print("Did not Collect Data!!")
    else:
        logger.info("Config Without Create Excel File!!")



# %%
logger = create_logger("./log")
logger.info("Start")

cfg_fname = "./config/config.json"
# cfg_fname = "D:\GitHub\Python\WebCrawler\config\config.json"

# 取得 sii / otc...的中文
dict_catg = getCategoryChinseseDesc(cfg_fname)

# 取得市場類別的清單
stockcatg = getConfigData(cfg_fname, "stocktype") # stockcatg = ["sii", "otc", "rotc", "pub"]

# 取得需要抓取的年月清單
ym_clist = getChineseYearMonthList(cfg_fname)

# 取得產業別的清單
industy = getConfigData(cfg_fname, "industygroup") # industy = ["半導體", "電子工業"]




# 取表頭資料
HeaderLine = getHeaderLine(cfg_fname)

ItemData = []
key_list = []

for catg in stockcatg:
    for period in ym_clist:
        data_lst = [catg, period, cfg_fname]

        # 取得BeautifulSoup Data
        BS_Obj = getBSobj_genFile(data_lst)

        # 取得市場的名稱
        market = getMarketNameFromBSObj(BS_Obj)        

        #轉西元年
        yyyymm = ChineseYearMonToCE(period)
        # 取table
        for ind in industy:
            TB_Obj = getTBobj_genFile(BS_Obj, data_lst, ind)

            # 有些產業在這個類別沒有
            if TB_Obj == None:
                continue

            logger.info(f"{period} {dict_catg[catg]} {ind} Start")

            # Get Item =>從第3個Row開始loop起(Row 3 以後是資料)
            for rows in TB_Obj.select("table > tr")[2:]:
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
                        collect = [yyyymm, StockID, StockName, int(CurrRevenue), int(LastRevenue), int(YoYRevenue), float(LastPercent), float(YoYPercent), int(CurrCount), int(LastCount), float(DiffPercent), Remark, market, ind]                        
                        # 遇到PSMC要拆BU
                        psmc_lspf_val = splitPSMCRevenueByBU(collect)
                        if psmc_lspf_val == 0:
                            collect.append("")
                            collect.append(int(CurrRevenue) * 1000)
                        else:
                            collect_tmp = collect.copy()
                            psmc_m_val = collect[3] - psmc_lspf_val
                            collect_tmp[3] = psmc_lspf_val
                            collect_tmp.append("L")
                            collect_tmp.append(int(psmc_lspf_val) * 1000)
                            ItemData.append(collect_tmp)
                            collect[3]  = psmc_m_val
                            collect.append("M")
                            collect.append(int(psmc_m_val) * 1000)
                        ItemData.append(collect)
                        key_list.append(key)
# %%
# 營收資料寫入資料庫中
updateRevenue_mssql(ItemData, ym_clist, cfg_fname)

# 公司清單寫入資料庫中
updateCompList_mssql(ItemData, cfg_fname)

# 產生Excel File
writeExcel(HeaderLine, ItemData, cfg_fname)
logger.info("Export Done!")

# %%
