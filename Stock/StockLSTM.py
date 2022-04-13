# %%
import pandas as pd
import tensorflow as tf
import numpy as np
from sklearn.preprocessing import MinMaxScaler

# from util.util import connect as con

# api = con().ServerConnectLogin( user = "chris")

# stockDF = pd.DataFrame({**api.kbars(api.Contracts.Stocks["2330"], start = "2000-01-01", end = date.today().strftime("%Y-%m-%d"))})
# stockDF["TradeDate"] = pd.to_datetime(stockDF.ts).dt.strftime("%Y-%m-%d")

# stockDF = stockDF.groupby(["TradeDate"], sort = True).agg({"Open": "first", "High": max, "Low": min, "Close": "last", "Volume": sum}).reset_index()

stockDF = pd.read_csv("data/2330.csv").replace(0, np.nan).drop(columns = ["Adj Close"]).dropna()
stockDF["CR"] = (stockDF.Close - stockDF.Close.shift(1, axis = 0))/stockDF.Close.shift(1, axis = 0) * 100
stockDF["CR"] = stockDF.CR.replace(np.nan, 0)
# 將日期設為index
stockDF.set_index("Date", inplace = True)
# stockDF = stockDF.round(2)
# stockDF.CR.plot()


tranDF = stockDF.iloc[:int(stockDF.shape[0] * 0.8), 0:5]
testDF = stockDF.iloc[int(stockDF.shape[0] * 0.8):, 0:5]

# normalized
tranDFnorm = (tranDF - tranDF.min())/(tranDF.max() - tranDF.min())
testDFnorm = (testDF - testDF.min())/(testDF.max() - testDF.min())
# %%


# 正規化
scaler = MinMaxScaler()
norm_data = pd.DataFrame(scaler.fit_transform(stockDF), columns = stockDF.columns, index = stockDF.index)

feq = 30
colname = list(stockDF.drop("CR", axis = 1).columns)
X = []
y = []
indexes = []
norm_data_x = norm_data[colname]
for i in range(0, len(norm_data) - feq): 
  X.append(norm_data_x.iloc[i:i + feq].values) 
  y.append(norm_data.CR.iloc[i + feq - 1]) # 現有資料+feq 天的Y
  indexes.append(norm_data.index[i + feq - 1]) # Y的日期

X = np.array(X)
y = np.array(y)



n_steps = 30 
n_features = 5

modelS = tf.keras.Sequential()
LSTM_Layer = tf.keras.layers.LSTM(units = 50, activation = tf.nn.relu, return_sequences = False, input_shape = (n_steps, n_features))

# outputLayer
out_Layer = tf.keras.layers.Dense(units = 1, activation = "linear")



modelS.add(LSTM_Layer)
modelS.add(out_Layer)
modelS.compile(optimizer = 'adam', loss = 'mse' , metrics=['mse','mape'])
history = modelS.fit(X, y, batch_size = 100, epochs = 20)


# %%


tranSet = stockDF.iloc[:int(stockDF.shape[0] * 0.8) , 0:5].values
testSet = stockDF.iloc[int(stockDF.shape[0] * 0.8):, 0:5].values

# normalize the data
tf_train_data = tf.clip_by_norm(tf.constant(tranSet, dtype = tf.float32))
# tf_test_data = tf.clip_by_norm(tf.constant(testSet, dtype = tf.float32))

# %%
