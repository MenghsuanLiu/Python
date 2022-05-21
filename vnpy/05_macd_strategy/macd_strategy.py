from vnpy_ctastrategy import (
    CtaTemplate,
    StopOrder,
    TickData,
    BarData,
    TradeData,
    OrderData,
    BarGenerator,
    ArrayManager,
)
from datetime import time


class MACDStrategy(CtaTemplate):

    author = "vnpy course"

    # 定義參數
    fast_period = 12
    slow_period = 26
    signal_period = 9
    fixed_size = 1
    sl_ratio = 0.02

    # 定義變數
    macd_value0 = 0
    macd_value1 = 0
    signal_value0 = 0
    signal_value1 = 0

    intra_trade_high = 0
    intra_trade_low = 0

    long_sl = 0
    short_sl = 0

    parameters = [
        "fast_period",
        "slow_period",
        "signal_period",
        "fixed_size",
        "sl_ratio"
    ]

    variables = [
        "macd_value0",
        "macd_value1",
        "signal_value0",
        "signal_value1",
        "intra_trade_high",
        "intra_trade_low",
        "long_sl",
        "short_sl"
    ]

    def __init__(self, cta_engine, strategy_name, vt_symbol, setting):
        """"""
        super().__init__(cta_engine, strategy_name, vt_symbol, setting)

        self.bg = BarGenerator(self.on_bar, 15, self.on_15min_bar)
        self.am = ArrayManager()
        self.day_start = time(9, 30)
        self.day_end = time(16, 0)

    def on_init(self):
        """
        Callback when strategy is inited.
        """

        self.write_log("策略初始化")
        self.load_bar(10)

    def on_start(self):
        """
        Callback when strategy is started.
        """
        self.write_log("策略启动")

    def on_stop(self):
        """
        Callback when strategy is stopped.
        """
        self.write_log("策略停止")

    def on_tick(self, tick: TickData):
        """
        Callback of new tick data update.
        """
        self.bg.update_tick(tick)

    def on_bar(self, bar: BarData):
        """
        Callback of new bar data update.
        """

        if not self.day_start <= bar.datetime.time() < self.day_end:
            return

        self.bg.update_bar(bar)
        
    def on_15min_bar(self, bar: BarData):

        self.cancel_all()

        am = self.am
        am.update_bar(bar)
        if not am.inited:
            return

        # 計算技術指標
        macd, signal, hist = am.macd(self.fast_period,
                                     self.slow_period,
                                     self.signal_period,
                                     array=True)

        self.macd_value0 = macd[-1]
        self.macd_value1 = macd[-2]
        self.signal_value0 = signal[-1]
        self.signal_value1 = signal[-2]

        cross_over = self.macd_value0 > self.signal_value0 and self.macd_value1 <= self.signal_value1
        cross_below = self.macd_value0 < self.signal_value0 and self.macd_value1 >= self.signal_value1

        if self.pos == 0:

            if cross_over:
                self.buy(bar.close_price * 1.01, self.fixed_size)

            elif cross_below:
                self.short(bar.close_price * 0.99, self.fixed_size)

            self.intra_trade_high = bar.high_price
            self.intra_trade_low = bar.low_price

        elif self.pos > 0:

            self.intra_trade_high = max(self.intra_trade_high, bar.high_price)

            self.long_sl = self.intra_trade_high * (1 - self.sl_ratio)
            self.sell(self.long_sl, abs(self.pos), stop=True)

        elif self.pos < 0:

            self.intra_trade_low = min(self.intra_trade_low, bar.low_price)

            self.short_sl = self.intra_trade_low * (1 + self.sl_ratio)
            self.cover(self.short_sl, abs(self.pos), stop=True)

        self.put_event()
        
    def on_order(self, order: OrderData):
        """
        Callback of new order data update.
        """
        pass

    def on_trade(self, trade: TradeData):
        """
        Callback of new trade data update.
        """
        self.put_event()

    def on_stop_order(self, stop_order: StopOrder):
        """
        Callback of stop order update.
        """
        pass