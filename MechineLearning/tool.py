# %%
import pymysql
import pandas as pd
# %%
class db:
    def mySQLconn(dbname):
        db_usr = "root"
        db_pwd = "670325"
        return pymysql.connect(host = "localhost", user = db_usr, passwd = db_pwd, database = dbname)

    def readDataFromDBtoDF(tbfullname):
        db_con = db.mySQLconn(tbfullname.split(".")[0], "read")
        return pd.read_sql(f"SELECT * FROM {tbfullname}", con = db_con) 