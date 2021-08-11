# %%
import shioaji as sj
import pandas as pd
import time
import json
import os
from datetime import date

def getConfigData(file_path, datatype):
    try:
        with open(file_path, encoding="UTF-8") as f:
            jfile = json.load(f)
        val = jfile[datatype]    
        # val =  ({True: "", False: jfile[datatype]}[jfile[datatype] == "" | jfile[datatype] == "None"])
    except:
        val = ""
    return val

def connectToServer():
    # 登入帳號
    api = sj.Shioaji(backend = "http", simulation=False)
    with open("./config/login.json", "r") as f:
        login_cfg = json.loads(f.read())
    api.login(**login_cfg, contracts_timeout = 0)
    return api

def InsertCAData(api):
    api.activate_ca(
        ca_path = r"C:\ekey\551\J120156413\S\Sinopac.pfx",
        ca_passwd = "J120156413",
        person_id = "J120156413"
    )
    return

def getWatchingStockList(cfg_file):
    files = os.listdir(getConfigData(cfg_file, "filepath"))
    matching = [s for s in files if getConfigData(cfg_file, "resultname") in s]

    for file in matching:
        filefullpath = getConfigData(cfg_file, "filepath") + f"/{file}"
        break
    stk_df = pd.read_excel(filefullpath)
    stk_df = stk_df[stk_df["sgl_SMA"] > 0]
    return stk_df["StockID"].tolist()
    
# def StockDefaultAccount(id):



# %%
cfg_fname = r"./config/config.json"
newfile = getConfigData(cfg_fname, "filepath") + "/MinsData_" + date.today().strftime("%Y%m%d") + ".xlsx"
api = connectToServer()
# InsertCAData(api)
stk_list = getWatchingStockList(cfg_fname)
contracts = []
for stk in stk_list:
    contracts.append(api.Contracts.Stocks[stk])
# %%
first = True
for i in range(0,270):
    min_df = pd.DataFrame(api.snapshots(contracts)).filter(items = ["code", "ts", "open", "high", "low", "close", "volumn" ]).rename(columns = {"code": "StockID", "ts": "DateTime"})
    min_df.DateTime = pd.to_datetime(min_df.DateTime)
    if first == True:
        final_df = min_df
        first = False
    else:
        final_df = final_df.append(min_df)
    time.sleep(60)

final_df = final_df.sort_values(by = ["StockID", "DateTime"])
final_df.to_excel(newfile, index = False)
# %%
# api.snapshots?
# a = pd.read_csv("./data/test.csv")
# # a["ts_date"] = a.to_datetime(a["ts"], format = "%Y-%m-%d").dt.date
# a["ts_date"] = pd.to_datetime(a.ts).dt.date
# a["ts_time"] = pd.to_datetime(a.ts).dt.time
# # %%
# a = api.list_accounts().StockAccount
# # b = a[0]
# # df = pd.DataFrame(api.list_accounts())
# # for inf in api.list_accounts():
    
# # %%
# api.stock_account
# # %%
# api.set_default_account(api.list_accounts()[3])
# # %%
# api.activate_ca(
#     ca_path = r"C:\ekey\551\J120156413\S\Sinopac.pfx",
#     ca_passwd = "J120156413",
#     person_id = "J120156413",
# )
# # %%
# contract = api.Contracts.Stocks.TSE.TSE2330
# order = api.Order(price = 591, 
#                   quantity = 1, 
#                   action = "Buy", 
#                   price_type = "LMT", 
#                   order_type = "ROD", 
#                   order_lot = "Common", 
#                   account = api.stock_account
#                   )
# trade = api.place_order(contract, order)
# # %%

# %%
list(range(0,11)) + [17] + list(range(11,17)) + [18]
# %%
