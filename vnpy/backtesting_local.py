from vnpy_ctastrategy.backtesting import BacktestingEngine
from helpers import get_commission, get_minimum_tick
from macd_strategy import MACDStrategy
from datetime import datetime

import plotly.io as pio
pio.renderers.default = 'iframe'

engine = BacktestingEngine()
engine.set_parameters(
    vt_symbol='2883.LOCAL',
    interval='1m',
    start=datetime(2021, 1, 1),
    end=datetime(2022, 3, 1),
    rate=get_commission,
    slippage=get_minimum_tick,
    size=1000,
    pricetick=get_minimum_tick,
    capital=500_000
)

setting = {
    "fixed_size": 25,
    "sl_ratio": 0.04
}

engine.add_strategy(MACDStrategy, setting)
engine.load_data()
engine.run_backtesting()
df = engine.calculate_result()
engine.calculate_statistics()
engine.show_chart()

for trade in engine.get_all_trades():
    print(trade)
