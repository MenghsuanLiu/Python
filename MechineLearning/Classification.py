# %%
import pandas as pd
import numpy as np
import pymysql
from datetime import datetime, timedelta
from sklearn import datasets
from sklearn import preprocessing
from sklearn import neighbors
from sklearn import linear_model
from sklearn import tree
from sklearn import ensemble
from sklearn import svm
from sklearn import metrics

from sklearn.model_selection import train_test_split
from tool import db


def getFirstMinsOHLCData(mins):
    db_con = db.mySQLconn("stock")
    endtime = (datetime.strptime("090000", "%H%M%S") + timedelta(minutes = mins)).strftime("%H%M%S")
    # 取得開盤前n分鐘的HOLC資料
    raw_df = pd.read_sql(f"select * from dailyminsholc where TradeTime <= {endtime}", con = db_con)
    
    # 取得每日收盤的狀況(1=漲, 0=平盤, -1=跌)
    rawday_df = pd.read_sql(f"select * from dailyholc", con = db_con)
    rawday_df["Result"] = 0
    rawday_df.loc[rawday_df.Close > rawday_df.Open, "Result"] = 1
    rawday_df.loc[rawday_df.Close < rawday_df.Open, "Result"] = -1
    DF_nMins = raw_df.groupby(["StockID", "TradeDate"], sort=True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()
    DF_nMins["WeekDay"] = pd.to_datetime(DF_nMins["TradeDate"], format = "%Y-%m-%d").dt.dayofweek
    DF_nMins = DF_nMins.merge(rawday_df.filter(items = ["StockID", "TradeDate", "Result"]), on = ["StockID", "TradeDate"], how = "left")
    return DF_nMins

def DataNormalize(data, method = "StandardScaler"):
    if method.lower() == "standardscaler":
        scaler = preprocessing.StandardScaler().fit(data)
    if method.lower() == "minmaxscaler":
        scaler = preprocessing.MinMaxScaler().fit(data)    
    if method.lower() == "maxabsscaler":
        scaler = preprocessing.MaxAbsScaler().fit(data)
    if method.lower() == "robustscaler":    
        scaler = preprocessing.RobustScaler().fit(data)
    if method.lower() == "powertransformer":
        scaler = preprocessing.PowerTransformer(method = "yeo-johnson", standardize = True).fit(data)
    return scaler.transform(data)


# %%
m_scaler = ["StandardScaler", "MinMaxScaler", "MaxAbsScaler", "RobustScaler", "PowerTransformer"]
DFstk = getFirstMinsOHLCData(5)
X = DFstk.filter(items = ["Open", "High", "Low", "Close", "WeekDay"])
y = DFstk.filter(items = ["Result"])

# from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
# lda = LinearDiscriminantAnalysis(n_components=2)#將資料縮減成兩個維度
# X_lda = lda.fit_transform(X, y)
# lda.explained_variance_ratio_
# %%
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.2)
for normal in m_scaler:
    X_train = DataNormalize(X_train, normal)
    X_test = DataNormalize(X_test, normal)
    # # KNN
    # clf = neighbors.KNeighborsClassifier(n_neighbors = 3)
    # clf.fit(X_train, y_train.values.ravel())
    # print(f"KNN Score={clf.score(X_test, y_test)}({normal})")
    
    #[GOOD] LogisticRegression
    clf = linear_model.LogisticRegression(solver = "liblinear")
    clf = clf.fit(X_train, y_train.values.ravel())
    print(f"Logistic Score={clf.score(X_test, y_test)}({normal})")
    
    # # DecisionTree
    # clf = tree.DecisionTreeClassifier()
    # clf = clf.fit(X_train, y_train.values.ravel())
    # y_test_predicted = clf.predict(X_test)
    # accuracy = metrics.accuracy_score(y_test, y_test_predicted)
    # print(f"DecisionTree Accuracy = {accuracy}({normal})")


    # SVM
    # clf = svm.SVC(kernel = "linear")
    # clf = clf.fit(X_train, y_train.values.ravel())
    # print(f"SVM Score={clf.score(X_test, y_test)}({normal})")
    # RandomForest
    # clf = ensemble.RandomForestClassifier(n_estimators = 100)
    # clf = clf.fit(X_train, y_train.values.ravel())
    # y_test_predicted = clf.predict(X_test)
    # accuracy = metrics.accuracy_score(y_test, y_test_predicted)
    # print(f"RandomForest = {accuracy}({normal})")

# # %%
# # DataSet
# data_iris = datasets.load_iris()

# X = pd.DataFrame(data_iris.data, columns = data_iris.feature_names)
# y = data_iris.target
# # DataCalean
# # print(X_std.isna().sum())

# # Feature Engineering
# X_std = pd.DataFrame(StandardScaler().fit_transform(X.values), index = X.index, columns = X.columns )

# # Data Split (Training data & Test data)
# # test_size=0.2 : 測試用資料為 20%
# X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.2)
# # X_train, X_test, y_train, y_test = train_test_split(X_std, y, test_size = 0.2)

# # print(X_train.shape, y_train.shape)

# # Define and train the KNN model
# # n_neighbors=: 超參數 (hyperparameter)
# clf = KNeighborsClassifier(n_neighbors = 3)

# # 適配 (訓練)，迴歸/分類/降維...皆用 fit(x_train, y_train)
# clf.fit(X_train, y_train)

# # algorithm.score: 使用 test 資料 input，並根據結果評分
# print(f'score={clf.score(X_test, y_test)}')

# # 驗證答案
# # print(' '.join(y_test.astype(str)))
# # print(' '.join(clf.predict(X_test).astype(str)))

# # result




# # %%
# import joblib
# # %%
# joblib.dump(clf, 'KNN_model')
# # %%
# loaded_model = joblib.load('KNN_model')
# # %%
# loaded_model.predict(np.array([[0, 0, 0, 0]]))
# # %%

# %%
