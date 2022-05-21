import pandas as pd
from vnpy_ctastrategy.backtesting import BacktestingEngine
from vnpy.trader.optimize import OptimizationSetting

from datetime import datetime
from sma2_strategy import SMA2Strategy

if __name__ == '__main__':

    engine = BacktestingEngine()
    engine.set_parameters(
        vt_symbol='AAPL-USD-STK.SMART',
        interval="1m",
        start=datetime(2021, 1, 1),
        end=datetime(2022, 4, 1),
        rate=0.005,
        slippage=0,
        size=1,
        pricetick=0.01,
        capital=100_000,
    )

    engine.add_strategy(SMA2Strategy, {})
    # engine.load_data()
    # engine.run_backtesting()
    # df = engine.calculate_result()
    # engine.calculate_statistics()
    # engine.show_chart()

    target = 'total_return'

    setting = OptimizationSetting()
    setting.set_target(target)
    setting.add_parameter("fast_window", 5, 20, 1)
    setting.add_parameter("slow_window", 20, 60, 5)
    setting.add_parameter("fixed_size", 500)

    # result = engine.run_ga_optimization(setting)
    result = engine.run_bf_optimization(setting)

    df = pd.DataFrame(result, columns=['parameter', target, 'statistics'])
    df.to_csv('opt.csv')
