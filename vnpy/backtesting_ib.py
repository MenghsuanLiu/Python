from vnpy_ctastrategy.backtesting import BacktestingEngine
from datetime import datetime
from sma_strategy import SMAStrategy

import plotly.io as pio
pio.renderers.default = 'iframe'

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

setting = {
    'fast_period': 5,
    'slow_period': 20,
    'fixed_size': 500,
}

engine.add_strategy(SMAStrategy, setting)
engine.load_data()
engine.run_backtesting()
df = engine.calculate_result()
engine.calculate_statistics()
engine.show_chart()

