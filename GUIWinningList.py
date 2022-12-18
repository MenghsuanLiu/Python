# %%
import requests
import pandas as pd
from datetime import date
from dateutil.relativedelta import relativedelta

# 計算年月值(網頁參數)baseday=>基準日, step=>-1往前一個單位
def calYearMonthWhichIsEven(baseday: date = date.today(), step: int = 0)-> None:
    
    caldate = baseday + relativedelta(months = step)
    if(int(caldate.month) % 2) == 0:
        return str(caldate.year - 1911)+str(caldate.month)
    else:
        return False



if __name__ == "__main__":
    ym = calYearMonthWhichIsEven(step = -1)
    if not ym:
        print("Exit Program!!")
        exit()

    para_win = {"version": "0.2", "action": "QryWinningList", "invTerm": ym, "appID": "EINV7201706312375", "UUID": "https://github.com/jasonlamkk/OpenUDID.Net"}
    url_win = "https://api.einvoice.nat.gov.tw/PB2CAPIVAN/invapp/InvApp"
    head = {"Content-Type": "application/x-www-form-urlencoded"}
    # r = requests.post(url, data=para, headers=head)
    r = requests.post(url_win, headers = head, params = para_win)
    df = pd.json_normalize(r.json(), max_level=1)
    print(r.url)



# df = pd.read_json(r.content)
# print(df)
# %%
