from vnpy_scripttrader import init_cli_trading
from vnpy_ib.ib_gateway import IbGateway
from vnpy.trader.database import get_database
from vnpy.trader.object import HistoryRequest, Interval, Exchange

from datetime import datetime
import pandas as pd
import time


def download_ib_data(symbol, exchange, start, end):

    req = HistoryRequest(
        symbol=symbol,
        exchange=Exchange(exchange),
        interval=Interval.MINUTE,
        start=datetime.strptime(start, '%Y-%m-%d'),
        end=datetime.strptime(end, '%Y-%m-%d')
    )

    bar_data = engine.main_engine.query_history(req, 'IB')

    if not bar_data:
        print(f'下載總數據量為:{len(bar_data)}')
        return

    database = get_database()
    database.save_bar_data(bar_data)

    print(f'{start}-{end}下載成功，總共{len(bar_data)}筆資料')


if __name__ == '__main__':

    # 連線設定
    setting = {
        "TWS地址": "127.0.0.1",
        "TWS端口": 4002,
        "客户号": 2,   # 每個連線為一個獨立的客戶號，IB API支援32個同時連線
        "交易账户": 1
    }

    # 連線到伺服器
    engine = init_cli_trading([IbGateway])
    engine.connect_gateway(setting, 'IB')

    time.sleep(5)

    symbols = ['AAPL', 'AMZN', 'TSLA']
    exchange = 'SMART'
    # interval = '1m'
    start_date = '2021-1-1'
    end_date = '2022-4-21'

    dates = pd.date_range(start_date, end_date, freq='QS')

    for s in symbols:

        symbol = f'{s}-USD-STK'
        print(f'===開始下載{symbol}歷史數據===')

        for i in range(len(dates)):

            if dates[i] == dates[-1]:
                start = str(dates[i].date())
                end = end_date
            else:
                start = str(dates[i].date())
                end = str(dates[i + 1].date())

            download_ib_data(symbol, exchange, start, end)

    print(f'===歷史數據下載完成===')

