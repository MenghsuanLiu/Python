# %%
import pandas as pd
import numpy as np
import pymysql
from sklearn import datasets
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsClassifier
from tool import db
# %%
# DataSet
data_iris = datasets.load_iris()

X = pd.DataFrame(data_iris.data, columns = data_iris.feature_names)
y = data_iris.target
# DataCalean
# print(X_std.isna().sum())

# Feature Engineering
X_std = pd.DataFrame(StandardScaler().fit_transform(X.values), index = X.index, columns = X.columns )

# Data Split (Training data & Test data)
# test_size=0.2 : 測試用資料為 20%
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.2)
# X_train, X_test, y_train, y_test = train_test_split(X_std, y, test_size = 0.2)

# print(X_train.shape, y_train.shape)

# Define and train the KNN model
# n_neighbors=: 超參數 (hyperparameter)
clf = KNeighborsClassifier(n_neighbors = 3)

# 適配 (訓練)，迴歸/分類/降維...皆用 fit(x_train, y_train)
clf.fit(X_train, y_train)

# algorithm.score: 使用 test 資料 input，並根據結果評分
print(f'score={clf.score(X_test, y_test)}')

# 驗證答案
# print(' '.join(y_test.astype(str)))
# print(' '.join(clf.predict(X_test).astype(str)))

# result


# 查看預測的機率
# print(clf.predict_proba(X_test))  # 預測每個 x_test 機率
# %%
db_con = db.mySQLconn("stock")
limitime = "090500" 
raw_df = pd.read_sql(f"select * from dailyminsholc where TradeTime <= {limitime}", con = db_con)
rawday_df = pd.read_sql(f"select * from dailyholc", con = db_con)
rawday_df["Result"] = 0
rawday_df.loc[rawday_df.Close > rawday_df.Open, "Result"] = 1
rawday_df.loc[rawday_df.Close < rawday_df.Open, "Result"] = -1

stkDF_5min = raw_df.groupby(["StockID", "TradeDate"], sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()

stkDF_5min = stkDF_5min.merge(rawday_df.filter(items = ["StockID", "TradeDate", "Result"]), on = ["StockID", "TradeDate"], how = "left")

# %%
X = stkDF_5min.filter(items = ["Open", "High", "Low", "Close"])
y = stkDF_5min.filter(items = ["Result"])
X = pd.DataFrame(StandardScaler().fit_transform(X.values), index = X.index, columns = X.columns )
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.3)
# %%
clf = KNeighborsClassifier(n_neighbors = 3)
clf.fit(X_train, y_train)
print(f'score={clf.score(X_test, y_test)}')
# %%
import joblib
# %%
joblib.dump(clf, 'KNN_model')
# %%
loaded_model = joblib.load('KNN_model')
# %%
loaded_model.predict(np.array([[0, 0, 0, 0]]))
# %%
