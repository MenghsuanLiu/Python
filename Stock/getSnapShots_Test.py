# %%
import shioaji as sj
import pandas as pd
import time
import json

def connectToServer():
    # 登入帳號
    api = sj.Shioaji(backend = "http", simulation=False)
    with open("./config/login.json", "r") as f:
        login_cfg = json.loads(f.read())
    api.login(**login_cfg)
    return api


# %%
api = connectToServer()
contracts = [api.Contracts.Stocks['2330']]
snapshots = api.snapshots(contracts)


first = True
for i in range(0,270):
    a = pd.DataFrame(snapshots)
    
    if first == True:
        df = a
        first = False
    else:
        df = df.append(a)
    time.sleep(60)

df.to_csv("./data/test.csv")