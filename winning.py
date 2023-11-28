# %%
import requests
import pandas as pd
import numpy as np
import time
import logging
from datetime import date
from dateutil.relativedelta import relativedelta
import pyrfc as rfc
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
    # Log的相闗設定
    yyyymmdd = date.today().strftime("%Y%m%d")
    logging.basicConfig(filename = f".\GUI_WinningList_{yyyymmdd}.log", level = logging.DEBUG, 
                        format='%(asctime)s %(levelname)s %(name)s %(message)s')
    logger = logging.getLogger(__name__)

    sapconn = ["PSMCERP", "SAP#MAX0", "172.16.6.232", "00", "800"]
    # sapconn = ["MISSD", "test2018", "172.20.97.81", "00", "300"]
    map_dict = {"super": "T", "spc": "S", "first": "1", "second": "2", "third": "3", "fourth": "4", "fifth": "5", "sixth": "6"}
    setp_val = -1
    wait = 0


    # 取得中獎號的期號(YYYMM => YYY為民國年 MM是偶數)
    ym = calYearMonthWhichIsEven(step = setp_val, ce = False)
    # ym出來時是False就不往下走了
    if not ym:
        print("Exit Program!!")
        exit()
    yyyy, mm = calYearMonthWhichIsEven(step = setp_val)
    
    conn = rfc.Connection(user = sapconn[0], passwd = sapconn[1], ashost = sapconn[2], sysnr = sapconn[3], client = sapconn[4])
    chk_exist = bool(conn.call("ZRFC_GET_GUI_WINNING_LIST", I_GGJAH = yyyy, I_GMONA = mm).get("E_EXIST"))
    conn.close()
    if chk_exist:
        print("資料己存在!!!")
        exit()
    # 連線參數
    head = {"Content-Type": "application/x-www-form-urlencoded"}  
    para_win = {"version": "0.2", "action": "QryWinningList", "invTerm": ym, "appID": "EINV7201706312375", "UUID": "https://github.com/jasonlamkk/OpenUDID.Net"}
    # para_win = {"version": "0.2", "action": "qryLoveCode", "qKey": "88432", "appID": "EINV7201706312375", "UUID": "https://github.com/jasonlamkk/OpenUDID.Net"}
    url_win = "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp"
    # url_win = "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/loveCodeapp/qryLoveCode"

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
            wait += 10
            print(f"下次執行時間為{wait}秒後~~~")
            time.sleep(wait)
            continue

    print(df_update)
    conn = rfc.Connection(user = sapconn[0], passwd = sapconn[1], ashost = sapconn[2], sysnr = sapconn[3], client = sapconn[4])
    result = conn.call("ZRFC_GET_GUI_WINNING_LIST", I_GGJAH = yyyy, I_GMONA = mm, T_DATA = df_update.to_dict("records"))
    print(result)
    conn.close()
# %%
