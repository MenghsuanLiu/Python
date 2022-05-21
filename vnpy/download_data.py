import shioaji as sj
import pandas as pd
import time

if __name__ == '__main__':

    # Login Shioaji
    # https://sinotrade.github.io/tutor/login/#login-shioaji

    api = sj.Shioaji()
    api.login(
        person_id="YOUR_ID",
        passwd="YOUR_PASSWORD",
        contracts_cb=lambda security_type: print(f"{repr(security_type)} fetch done."))

    time.sleep(5)

    symbol = '2883'
    start_date = '2020-12-01'
    end_date = '2022-03-02'

    # KBar Data
    # https://sinotrade.github.io/tutor/market_data/historical/#kbar-data

    kbars = api.kbars(api.Contracts.Stocks[symbol], start=start_date, end=end_date)
    df = pd.DataFrame({**kbars})
    df.ts = pd.to_datetime(df.ts)

    df.to_csv(f'{symbol}.csv')

    print(f'==={symbol} 歷史數據下載完成===')
    api.logout()








