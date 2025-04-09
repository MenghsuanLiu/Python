# %%
import requests
import pandas as pd
import numpy as np
import time
from datetime import date
from dateutil.relativedelta import relativedelta
# import sys
# import traceback
import logging
# import pyrfc as rfc
# 
# %%
# 計算年月值(網頁參數)baseday=>基準日, step=>-1往前一個單位
def calYearMonthWhichIsEven(baseday: date = date.today(), step: int = 0, ce: bool = True)-> None:
    
    caldate = baseday + relativedelta(months = step)
    if(int(caldate.month) % 2) == 0:
        if ce:
            if caldate.month < 10:
                return str(caldate.year), "0" + str(caldate.month)
            else:
                return str(caldate.year), str(caldate.month)

        else:    
            if caldate.month < 10:
                return str(caldate.year - 1911) + "0" + str(caldate.month)
            else:
                return str(caldate.year - 1911) + str(caldate.month)
    else:
        return False


if __name__ == "__main__":
    logging.basicConfig(filename = 'D:\\GUIwin.log', level = logging.DEBUG, 
                        format='%(asctime)s %(levelname)s %(name)s %(message)s')
    logger = logging.getLogger(__name__)
    map_dict = {"super": "T", "spc": "S", "first": "1", "second": "2", "third": "3", "fourth": "4", "fifth": "5", "sixth": "6"}
    setp_val = -1
    wait = 0


    # 取得中獎號的期號(YYYMM => YYY為民國年 MM是偶數)
    ym = calYearMonthWhichIsEven(step = setp_val, ce = False)
    yyyy, mm = calYearMonthWhichIsEven(step = setp_val)
    if not ym:
        print("Exit Program!!")
        exit()
    
    # conn = rfc.Connection(user = "MISSD", passwd = "test2018", ashost = "172.20.97.81", sysnr = "00", client = "300")
    # chk_exist = bool(conn.call("ZRFC_GET_GUI_WINNING_LIST", I_GGJAH = yyyy, I_GMONA = mm).get("E_EXIST"))
    # if chk_exist:
    #     print("資料己存在!!!")
    #     conn.close()
    #     exit()

    # 連線參數
    head = {"Content-Type": "application/x-www-form-urlencoded"}  
    para_win = {"version": "0.2", "action": "QryWinningList", "invTerm": ym, "appID": "EINV7201706312375", "UUID": "https://github.com/jasonlamkk/OpenUDID.Net"}
    url_win = "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp"
# %%
    while True:
        try:
            r = requests.post( url_win, headers = head, params = para_win )
            if int(r.json().get("code")) != 200:
                print(r.json().get("msg"))
                exit()

            df = pd.json_normalize(r.json(), max_level=1)
            df_prize = df.filter(regex="PrizeNo").replace("", np.nan).T.rename({0: "PIZNO"},axis = 1).dropna().rename_axis("pizname").reset_index()
            df_amt = df.filter(regex = "Amt").T.rename({0: "PZAMT"}, axis = 1).astype({"PZAMT": int}).rename_axis("pizname").reset_index()
            df_prize["PRTYP"] = df_prize["pizname"].str.split("Prize", expand = True)[0].map(map_dict)
            # 如果有增開六獎就在ADDON欄位給值
            df_prize["ADDON"] = df_prize["pizname"].str.split("Prize", expand = True)[0].map({"sixth": "X"})
            df_amt["PRTYP"] = df_amt["pizname"].str.split("Prize", expand = True)[0].map(map_dict)
            # 用頭獎做出另外五組,同時取獎號後幾碼(二獎=>7碼...六獎=>3碼)
            df_update = pd.DataFrame()
            for i in range(2,7):
                a = df_prize[df_prize["PRTYP"] == str(1)].replace("1", str(i))
                a.PIZNO = a.PIZNO.str.slice(i - 1, 8)
                df_update = pd.concat([df_update, a], ignore_index = True)
            # 和原來的特獎~一獎(增開六獎)組在一起
            df_update = pd.concat([df_update, df_prize], ignore_index = True).replace(np.nan, "")
            # 串出各獎金額
            df_update = df_update.merge(df_amt, on = "PRTYP", how = "left")
            df_update = df_update.drop(list(df_update.filter(regex = "pizname")), axis=1).sort_values(by = "PRTYP").reset_index(drop=True)
            df_update = df_update.astype(str)
            break
        except Exception as e:
            logger.error(e)
            # error_class = e.__class__.__name__ #取得錯誤類型
            # detail = e.args[0] #取得詳細內容
            # cl, exc, tb = sys.exc_info() #取得Call Stack
            # lastCallStack = traceback.extract_tb(tb)[-1] #取得Call Stack的最後一筆資料
            # fileName = lastCallStack[0] #取得發生的檔案名稱
            # lineNum = lastCallStack[1] #取得發生的行號
            # funcName = lastCallStack[2] #取得發生的函數名稱
            # errMsg = "File \"{}\", line {}, in {}: [{}] {}".format(fileName, lineNum, funcName, error_class, detail)
            
            wait += 10
            print(f"下次執行時間為{wait}秒後~~~")
            time.sleep(wait)
            continue

    print(df_update)
    
    # result = conn.call("ZRFC_GET_GUI_WINNING_LIST", I_GGJAH = yyyy, I_GMONA = mm, T_DATA = df_update.to_dict("records"))
    # print(result)
    # conn.close()
