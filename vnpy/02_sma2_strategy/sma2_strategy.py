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


class SMA2Strategy(CtaTemplate):

    author = "vnpy course"

    # 定義參數
    fast_window = 5
    slow_window = 20
    fixed_size = 1

    # 定義變數
    fast_ma0 = 0
    fast_ma1 = 0
    slow_ma0 = 0
    slow_ma1 = 0

    parameters = ["fast_window", "slow_window", "fixed_size"]
    variables = ["fast_ma0", "fast_ma1", "slow_ma0", "slow_ma1"]

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
        self.write_log("策略啟動")
        self.put_event()

    def on_stop(self):
        """
        Callback when strategy is stopped.
        """
        self.write_log("策略停止")
        self.put_event()

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

        # print('15m', bar.datetime, bar.close_price)

        self.cancel_all()

        am = self.am
        am.update_bar(bar)
        if not am.inited:
            return

        # 計算技術指標
        fast_ma = am.sma(self.fast_window, array=True)
        self.fast_ma0 = fast_ma[-1]
        self.fast_ma1 = fast_ma[-2]

        slow_ma = am.sma(self.slow_window, array=True)
        self.slow_ma0 = slow_ma[-1]
        self.slow_ma1 = slow_ma[-2]

        # 判斷均線交叉
        cross_over = self.fast_ma0 > self.slow_ma0 and self.fast_ma1 <= self.slow_ma1
        cross_below = self.fast_ma0 < self.slow_ma0 and self.fast_ma1 >= self.slow_ma1

        if cross_over:

            if self.pos == 0:
                self.buy(bar.close_price * 1.01, self.fixed_size)
            elif self.pos < 0:
                self.cover(bar.close_price * 1.01, self.fixed_size)

        elif cross_below:

            if self.pos == 0:
                self.short(bar.close_price * 0.99, self.fixed_size)
            elif self.pos > 0:
                self.sell(bar.close_price * 0.99, self.fixed_size)

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
