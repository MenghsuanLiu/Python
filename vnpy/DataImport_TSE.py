# %%

from datetime import date, timedelta
from Util.utility import connect as con, file, database as db

if __name__ == '__main__':
    stk = "2330"
    start_date = str(date.today() - timedelta(days = 365))
    fname = f"./Data/{stk}.csv"
    api = con().ServerConnectLogin( user = "chris")
    stkDF = con(api).getKbarData(stkid = stk, sdate = start_date, edate = str(date.today()))

    # file.GeneratorFromDF(genDF = stkDF, fname = fname, ftype = "csv")
    db.importDataToVnpyDB(df = stkDF, stkid = stk)

    api.logout()
# %%
