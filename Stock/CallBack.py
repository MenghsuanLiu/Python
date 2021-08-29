# %%
import time
import pandas as pd
import os


from util import connect as con
from util import config as cfg
from shioaji import TickSTKv1, Exchange

def getAccountDF(api):
    df = pd.DataFrame(api.list_accounts())
    column_names = []
    for i in range(0, 6):
        a = str(df.head(1).values[0][i]).replace("(", "").replace(r"'", "").split(",")[0]
        column_names.append(a)
    df.columns = column_names
    # for c in column_names:
    #     df[c] = str(df[c]).replace(")", "").replace(r"'", "").split(",")[1]
    return df

def getAttentionStock(cfg_file):
    files = os.listdir(cfg.getConfigValue(cfg_file, "filepath"))
    matching = [s for s in files if cfg.getConfigValue(cfg_file, "resultname") in s]

    for file in matching:
        filefullpath = cfg.getConfigValue(cfg_file, "filepath") + f"/{file}"
        break
    stk_df = pd.read_excel(filefullpath)
    # 邏輯: 前一交易日成交價 > 60MA & 10MA,且成交量 >= 5000張 
    stk_df = stk_df.loc[(stk_df["sgl_SMA"] > 0) & (stk_df["Volume"] >= 5000)]
    return stk_df

def SubscribeAndUnsubscribe(api, STKDF, s_u):
    if s_u == "s":
        for stk in STKDF.StockID.head(1).to_list():    
            contract = api.Contracts.Stocks[stk]
            api.quote.subscribe(contract, quote_type = "tick", version = "v1")
            time.sleep(0.5)
    if s_u == "u":
        for stk in STKDF.StockID.head(1).to_list():    
            contract = api.Contracts.Stocks[stk]
            api.quote.unsubscribe(contract, quote_type = "tick", version = "v1")
            time.sleep(0.5)
    return


cfg_fname = "./config/config.json"
api = con.connectToServer(cfg.getConfigValue(cfg_fname, "login"))

# %%
Quote_List = []
@api.on_tick_stk_v1()
def quote_callback(exchange: Exchange, tick: TickSTKv1):
    try:
       Quote_List.append({**tick})
    except:
        quit()
    # Quote_List.append({**tick})
    # print(f"Exchange: {exchange}, Tick: {tick}")

# @api.quote.on_quote
# def quote_callback(topic: str, quote: dict):
#     Quote_List.append(quote)
    # print(f"Topic: {topic}, Quote: {quote}")
    # return quote


# contract = api.Contracts.Stocks["2383"]
# api.quote.unsubscribe(contract, quote_type = "tick", version = "v1")
# 取得前一交易日的關注清單
stk_data = getAttentionStock(cfg_fname)
# 訂閱報價
SubscribeAndUnsubscribe(api, stk_data, "s")
# %%
SubscribeAndUnsubscribe(api, stk_data, "u")
# %%
while True:    
    if time.strftime("%H%M%S", time.localtime()) == "133005":
        # 取消訂閱報價
        SubscribeAndUnsubscribe(api, stk_data, "u")
        df = pd.DataFrame(Quote_List)
        df.to_csv("./data/realtimeTick.csv", encoding =  "utf_8_sig", index = False)
        
        break



# %%

# import shioaji as sj

# api = sj.Shioaji(simulation=True)
# accounts = api.login("PAPIUSER01", "2222", contracts_timeout=10000)

# contract = api.Contracts.Stocks.TSE.TSE2890
# order = api.Order(
#     price=14,
#     quantity=1,
#     action=sj.constant.Action.Sell,
#     price_type=sj.constant.StockPriceType.LMT,
#     order_type=sj.constant.TFTOrderType.ROD,
#     first_sell=sj.constant.StockFirstSell.Yes,
#     account=api.stock_account
# )
# trade = api.place_order(contract, order)

# %%

# api.get_account_margin
# api.list_positions(api.stock_account)
# 現在使用的帳戶
# api.stock_account
# 顥示所有的帳戶
# api.list_accounts()
# 更改預設帳戶
# api.set_default_account(api.list_accounts()[-1])
# matches = [x for x in api.list_accounts() if x == "StockAccount"]
# for a in api.list_accounts():
#     print(a)
# df = getAccountDF(api)
# api.activate_ca(
#         ca_path = r"C:\ekey\551\J120156413\S\Sinopac.pfx",
#         ca_passwd = "J120156413",
#         person_id = "J120156413"
#     )
# api.list_trades()
# str(df["person_id"])

# stock = api.Contracts.Stocks["2002"]
# order = api.Order(
#     price=37, 
#     quantity=1, 
#     action="Buy", 
#     price_type="LMT", 
#     order_type="ROD", 
#     order_lot="Common", 
#     account=api.stock_account
# )
# api.place_order(stock, order)
# api.update_status(api.stock_account)
# 查庫存
# df = pd.DataFrame(api.list_positions(api.stock_account))


# %%
