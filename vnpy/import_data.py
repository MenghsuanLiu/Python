from vnpy.trader.database import get_database
from vnpy.trader.object import (
    BarData,
    Exchange,
    Interval
)

import pandas as pd
import pytz
import datetime

TW_TZ = pytz.timezone("Asia/Taipei")

if __name__ == '__main__':

    symbol = '2883'

    df = pd.read_csv(f'{symbol}.csv', parse_dates=['ts'])

    bar_data = []

    if df is not None:
        for index, row in df.iterrows():
            bar = BarData(
                symbol=symbol,
                exchange=Exchange.LOCAL,
                datetime=TW_TZ.localize(row['ts'].to_pydatetime()) - datetime.timedelta(minutes=1),
                interval=Interval.MINUTE,
                volume=row['Volume'],
                open_price=row['Open'],
                high_price=row['High'],
                low_price=row['Low'],
                close_price=row['Close'],
                gateway_name='Sinopac'
            )

            bar_data.append(bar)

        database = get_database()
        database.save_bar_data(bar_data)
        print(f'股票代號:{symbol}｜{bar_data[0].datetime}-{bar_data[-1].datetime} 歷史數據匯入成功，總共{len(bar_data)}筆資料')