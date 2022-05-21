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


class BBANDSStrategy(CtaTemplate):

    author = "vnpy course"

    # 定義參數
    boll_window = 20
    boll_dev = 2
    fixed_size = 1

    # 定義變數
    boll_up0 = 0
    boll_up1 = 0
    boll_down0 = 0
    boll_down1 = 0
    boll_mid = 0

    parameters = [
        "boll_window",
        "boll_dev",
        "fixed_size"
    ]
    variables = [
        "boll_up0",
        "boll_up1",
        "boll_down0",
        "boll_down1",
        "boll_mid"
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
        self.write_log("策略啟動")

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
        boll_up, boll_down = am.boll(self.boll_window, self.boll_dev, array=True)

        self.boll_up0 = boll_up[-1]
        self.boll_up1 = boll_up[-2]
        self.boll_down0 = boll_down[-1]
        self.boll_down1 = boll_down[-2]
        self.boll_mid = am.sma(self.boll_window)

        if self.pos == 0:
            if am.close[-1] > self.boll_up0 and am.close[-2] <= self.boll_up1:
                self.buy(bar.close_price * 1.01, self.fixed_size)
            elif am.close[-1] < self.boll_down0 and am.close[-2] >= self.boll_down1:
                self.short(bar.close_price * 0.99, self.fixed_size)

        elif self.pos > 0:
            if bar.close_price <= self.boll_mid:
                self.sell(bar.close_price * 0.99, abs(self.pos))

        elif self.pos < 0:
            if bar.close_price >= self.boll_mid:
                self.cover(bar.close_price * 1.01, abs(self.pos))

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