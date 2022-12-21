# %%
import requests
import pandas as pd
import numpy as np
import time
from datetime import date
from dateutil.relativedelta import relativedelta
import pyrfc as rfc


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
    map_dict = {"super": "T", "spc": "S", "first": "1", "second": "2", "third": "3", "fourth": "4", "fifth": "5", "sixth": "6"}
    setp_val = -4


    # 取得中獎號的期號(YYYMM => YYY為民國年 MM是偶數)
    ym = calYearMonthWhichIsEven(step = setp_val, ce = False)
    yyyy, mm = calYearMonthWhichIsEven(step = setp_val)
    if not ym:
        print("Exit Program!!")
        exit()
    
    conn = rfc.Connection(user = "MISSD", passwd = "test2018", ashost = "172.20.97.81", sysnr = "00", client = "300")
    chk_exist = bool(conn.call("ZRFC_GET_GUI_WINNING_LIST", I_GGJAH = yyyy, I_GMONA = mm).get("E_EXIST"))
    if chk_exist:
        print("資料己存在!!!")
        conn.close()
        exit()

    # 連線參數
    head = {"Content-Type": "application/x-www-form-urlencoded"}  
    para_win = {"version": "0.2", "action": "QryWinningList", "invTerm": ym, "appID": "EINV7201706312375", "UUID": "https://github.com/jasonlamkk/OpenUDID.Net"}
    url_win = "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp"

    # try:
    r = requests.post( url_win, headers = head, params = para_win )
    if int(r.json().get("code")) != 200:
        print(r.json().get("msg"))
        exit()

    time.sleep(5)
    df = pd.json_normalize(r.json(), max_level=1)
    # df = df.drop(df.filter(regex="timeStamp").columns, axis = 1)

    df_prize_o = df.filter(regex="PrizeNo").replace("", np.nan).T.rename({0: "PIZNO"},axis = 1).dropna().rename_axis("pizname").reset_index()
    df_amt = df.filter(regex = "Amt").T.rename({0: "PZAMT"}, axis = 1).astype({"PZAMT": int}).rename_axis("pizname").reset_index()
    df_prize_o["PRTYP"] = df_prize_o["pizname"].str.split("Prize", expand = True)[0].map(map_dict)
    df_amt["PRTYP"] = df_amt["pizname"].str.split("Prize", expand = True)[0].map(map_dict)
    # 用頭獎做出另外五組
    df_prize = pd.DataFrame()
    for i in range(2,7):
        a = df_prize_o[df_prize_o.pizname.str.match("first")]
        a["PRTYP"] = str(i)
        a["PIZNO"] = a["PIZNO"].str.slice(i - 1, 8)
        df_prize = df_prize.append(a)
    df_prize = df_prize.append(df_prize_o).reset_index(drop=True)
    df_prize = df_prize.merge(df_amt, on = "PRTYP", how = "left")
    df_prize = df_prize.drop(list(df_prize.filter(regex = "pizname")), axis=1).sort_values(by = "PRTYP").reset_index(drop=True)
    df_prize = df_prize.rename_axis("RECOD").reset_index()
    df_prize["GGJAH"] = yyyy
    df_prize["GMONA"] = mm
    df_prize["WAERK"] = "TWD"
    df_prize["RECOD"] = df_prize.RECOD.astype(str)
    df_prize["PZAMT"] = df_prize.PZAMT.astype(str)
 





    
    # a = [{"GGJAH": "2022", "GMONA": "08", "RECOD": "1", "PRTYP": "T", "PIZNO": "11174120", "PZAMT": "10000000", "WAERK": "TWD"},
    #      {"GGJAH": "2022", "GMONA": "08", "RECOD": "2", "PRTYP": "S", "PIZNO": "59276913", "PZAMT": "2000000", "WAERK": "TWD"}]
    result = conn.call("ZRFC_GET_GUI_WINNING_LIST", I_GGJAH = yyyy, I_GMONA = mm, T_DATA = df_prize.to_dict("records"))
    print(result)
    conn.close()


    
    


    
 
#     # 
#     # df = pd.json_normalize(r.json(), max_level=1)
#     # df = df.drop(df.filter(regex="timeStamp").columns, axis = 1)
#     # print(r.url)

# # %%

#     conn = rfc.Connection(user = "MISSD", passwd = "test2018", ashost = "172.20.97.81", sysnr = "00", client = "300")
#     result = conn.call("STFC_CONNECTION", REQUTEXT = "AAAA")

#     conn.close()
#     print(result)
# %%
