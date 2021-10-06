# %%
from backtesting import Backtest, Strategy 
from backtesting.lib import crossover
from backtesting.test import SMA 
import talib
import pandas as pd
from util import con, cfg, db, file


class OneMA(Strategy): 
    
    n1 = 60  #預設的均線參數
    
    def init(self): #初始化會用到的參數和指標，告知要如何計算
        self.sma1 = self.I(SMA, self.data.Close, self.n1) 

    def next(self): #回測的時候每一根K棒出現什麼狀況要觸發進出場
        #如果收盤價>sma1(也就是60ma)，而且目前沒有多單部位
        if (self.data.Close > self.sma1) and (not self.position.is_long) :
            self.buy()#做多
        #如果收盤價<sma1(也就是60ma)
        elif (self.data.Close < self.sma1):
            self.position.close()#部位出場
                                 #如果要做空就用self.sell()


cfg_file = "./config/config.json"
stk = '2330'
db_con = db.mySQLconn("stock", "read")
df = pd.read_sql(f"SELECT * FROM stock.dailyholc WHERE StockID = {stk}" , con = db_con).drop(columns = ["modifytime", "StockID"]).rename(columns = {"TradeDate": "Date"})
df.index = df["Date"]

# %%
#輸入回測的條件，df是上一篇台積電日K資料，OneMA是寫好的策略，初始資金10000，交易成本0.2%
bt = Backtest(df, OneMA, cash = 10000, commission = 0.002)

#將跑完回測得到的數據放到stats
stats = bt.run()
stats                              
# %%
bt.plot(superimpose = False)
# %%
stats = bt.optimize(n1 = range(2, 241, 1),maximize = 'Equity Final [$]')
stats
# %%
stats = bt.optimize(n1 = range(2, 241, 1), maximize = 'Win Rate [%]')
stats
# %%
