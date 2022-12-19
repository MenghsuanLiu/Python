# %%
import requests
import pandas as pd
import numpy as np
from datetime import date
from dateutil.relativedelta import relativedelta
import pyrfc as rfc


# 計算年月值(網頁參數)baseday=>基準日, step=>-1往前一個單位
def calYearMonthWhichIsEven(baseday: date = date.today(), step: int = 0)-> None:
    
    caldate = baseday + relativedelta(months = step)
    if(int(caldate.month) % 2) == 0:
        if caldate.month < 10:
            return str(caldate.year - 1911) + "0" + str(caldate.month)
        else:
            return str(caldate.year - 1911) + str(caldate.month)
    else:
        return False



if __name__ == "__main__":
    # 取得中獎號的期號(YYYMM => YYY為民國年 MM是偶數)
    ym = calYearMonthWhichIsEven(step = -2)
    if not ym:
        print("Exit Program!!")
        exit()
    # 連線參數
    head = {"Content-Type": "application/x-www-form-urlencoded"}  
    para_win = {"version": "0.2", "action": "QryWinningList", "invTerm": ym, "appID": "EINV7201706312375", "UUID": "https://github.com/jasonlamkk/OpenUDID.Net"}
    url_win = "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp"
    
    try:
        r = requests.post(url_win, headers = head, params = para_win)
        if int(r.json().get("code")) != 200:
            print(r.json().get("msg"))
            exit()
        df = pd.json_normalize(r.json(), max_level=1)
        # df = df.drop(df.filter(regex="timeStamp").columns, axis = 1)

        df_prize = df.filter(regex="PrizeNo").replace("", np.nan).T.rename({0: "PINZO"},axis = 1).dropna().rename_axis("pizname").reset_index()
        df_amt = df.filter(regex = "Amt").T.rename({0: "PZAMT"}, axis = 1).astype({"PZAMT": int}).rename_axis("pizname").reset_index()
        df_prize["key"] = df_prize["pizname"].str.split("No", expand = True)[0]
    except:
        print("Error!")
        exit()

    # %%


    conn = rfc.Connection(user = "MISSD", passwd = "test2018", ashost = "172.20.97.81", sysnr = "00", client = "300")
    chk_exist = bool(conn.call("ZRFC_GET_GUI_WINNING_LIST", I_GGJAH = "2022", I_GMONA = "10").get("E_EXIST"))
    if chk_exist:
        print("資料己存在!!!")
        conn.close()
        exit()





    
    a = [{"GGJAH": "2022", "GMONA": "08", "RECOD": "1", "PRTYP": "T", "PINZO": "11174120", "PZAMT": "10000000", "WAERK": "TWD"},
         {"GGJAH": "2022", "GMONA": "08", "RECOD": "2", "PRTYP": "S", "PINZO": "59276913", "PZAMT": "2000000", "WAERK": "TWD"}]
    result = conn.call("ZRFC_GET_GUI_WINNING_LIST", I_GGJAH = "2022", I_GMONA = "10", T_DATA = a)
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
