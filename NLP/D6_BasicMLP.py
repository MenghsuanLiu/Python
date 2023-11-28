# %%
import tensorflow as tf
import numpy as np

x1 = np.random.random((500,1))
x2 = np.random.random((500,1))+1
x_train = np.concatenate((x1, x2))

y1 = np.zeros((500,), dtype = int)
y2 = np.ones((500,), dtype = int)
y_train = np.concatenate((y1, y2))

model = tf.keras.models.Sequential([
    tf.keras.layers.Dense(10, activation = tf.nn.relu, input_dim=1),
    tf.keras.layers.Dense(10, activation = tf.nn.relu),
    tf.keras.layers.Dense(2, activation = tf.nn.softmax)
])
# %%
model.compile(  optimizer='adam',
                loss = 'sparse_categorical_crossentropy',
                metrics=['accuracy'])

model.fit(x_train, y_train,
            epochs = 20,
            batch_size = 128)
# %%
#測試
x_test=np.array([[0.22],[0.31],[1.22],[1.33]])
y_test=np.array([0,0,1,1])

score = model.evaluate(x_test, y_test, batch_size=128)
print("score:",score)

predict = model.predict(x_test)
print("predict:",predict)
print("Ans:",np.argmax(predict[0]),np.argmax(predict[1]),np.argmax(predict[2]),np.argmax(predict[3]))

# predict2 = model.predict_classes(x_test)
predict2 = model.predict(x_test)
predict2 = np.argmax(predict2,axis=1)

print("predict_classes:",predict2)
print("y_test",y_test[:])
# %%
import tensorflow as tf
import numpy as np
def CreateDatasets(high,iNum,iArraySize):
    x_train = np.random.random((iNum, iArraySize)) * float(high)
    y_train = ((x_train[:iNum,0]+x_train[:iNum,1])/2).astype(int)     # 取整數
    return x_train, y_train,tf.keras.utils.to_categorical(y_train, num_classes=(high))
category=10
dim=2
x_train,y_train,y_train2=CreateDatasets(category,1000*10,dim) # 修改這裡


# 建立模型
model = tf.keras.models.Sequential()
model.add(tf.keras.layers.Dense(units=10*100,
    activation=tf.nn.relu,
    input_dim=dim))
model.add(tf.keras.layers.Dense(units=10*100,
    activation=tf.nn.relu ))
model.add(tf.keras.layers.Dense(units=10*100,
    activation=tf.nn.relu ))
model.add(tf.keras.layers.Dense(units=10*100,
    activation=tf.nn.relu ))
model.add(tf.keras.layers.Dense(units=category,
    activation=tf.nn.softmax ))
model.compile(optimizer='adam',
    loss=tf.keras.losses.categorical_crossentropy,
    metrics=['accuracy'])
model.fit(x_train, y_train2,
          epochs=20*100,
          batch_size=128*100)

#測試
x_test,y_test,y_test2=CreateDatasets(category,10,dim)
score = model.evaluate(x_test, y_test2, batch_size=128)
print("score:",score)

predict = model.predict(x_test)
#print("predict:",predict)
print("Ans:",np.argmax(predict[0]),np.argmax(predict[1]),np.argmax(predict[2]),np.argmax(predict[3]))

predict2 = model.predict(x_test)
predict2 = np.argmax(predict2,axis=1)

print("predict_classes:",predict2)
print("y_test",y_test[:])

# %%
from sklearn import datasets
from sklearn.model_selection import train_test_split
import tensorflow as tf
import numpy as np


iris = datasets.load_iris()

category=3
dim=4
x_train , x_test , y_train , y_test = train_test_split(iris.data,iris.target,test_size=0.2)
y_train2=tf.keras.utils.to_categorical(y_train, num_classes=(category))
y_test2=tf.keras.utils.to_categorical(y_test, num_classes=(category))

print("x_train[:4]",x_train[:4])
print("y_train[:4]",y_train[:4])
print("y_train2[:4]",y_train2[:4])

# 建立模型
model = tf.keras.models.Sequential()
model.add(tf.keras.layers.Dense(units=10,
    activation=tf.nn.relu,
    input_dim=dim))
model.add(tf.keras.layers.Dense(units=10,
    activation=tf.nn.relu ))
model.add(tf.keras.layers.Dense(units=category,
    activation=tf.nn.softmax ))
model.compile(optimizer='adam',
    loss=tf.keras.losses.categorical_crossentropy,
    metrics=['accuracy'])

#
model.compile(optimizer=tf.keras.optimizers.SGD(lr=0.01, clipnorm=1.),
    loss=tf.keras.losses.categorical_crossentropy,
    metrics=['accuracy'])


history = model.fit(x_train, y_train2,
                    epochs = 200,
                    batch_size = 128)

#測試
score = model.evaluate(x_test, y_test2, batch_size=128)
print("score:",score)

predict = model.predict(x_test)
print("Ans:",np.argmax(predict[0]),np.argmax(predict[1]),np.argmax(predict[2]),np.argmax(predict[3]))
# %%
from sklearn import datasets
from sklearn.model_selection import train_test_split
import tensorflow as tf
import numpy as np
from sklearn import preprocessing

wine = datasets.load_wine()
minmaxscaler = preprocessing.MinMaxScaler()
win_new = minmaxscaler.fit(wine.data)
category = 3
dim = 13
x_train , x_test , y_train , y_test = train_test_split(win_new, wine.target, test_size=0.1)
y_train2=tf.keras.utils.to_categorical(y_train, num_classes=(category))
y_test2=tf.keras.utils.to_categorical(y_test, num_classes=(category))

# %%

# print("x_train[:4]",x_train[:4])
# print("y_train[:4]",y_train[:4])
# print("y_train2[:4]",y_train2[:4])

# 建立模型
model = tf.keras.models.Sequential()
model.add(tf.keras.layers.Dense(units=30,
    activation=tf.nn.relu,
    input_dim=dim))
model.add(tf.keras.layers.Dense(units=30,
    activation=tf.nn.relu ))
model.add(tf.keras.layers.Dense(units=category,
    activation=tf.nn.softmax ))
model.compile(optimizer='adam',
    loss=tf.keras.losses.categorical_crossentropy,
    metrics=['accuracy'])

#
# model.compile(optimizer=tf.keras.optimizers.SGD(lr=0.01, clipnorm=1.),
#     loss=tf.keras.losses.categorical_crossentropy,
#     metrics=['accuracy'])


history = model.fit(x_train, y_train2,
                    epochs = 2000,
                    batch_size = 9)

#測試
score = model.evaluate(x_test, y_test2, batch_size=128)
print("score:",score)

predict = model.predict(x_test)
print("Ans:",np.argmax(predict[0]),np.argmax(predict[1]),np.argmax(predict[2]),np.argmax(predict[3]))
# %%
#from sklearn import datasets
from sklearn.model_selection import train_test_split
import tensorflow as tf
import numpy as np



import xlrd
# import xlwt

read=xlrd.open_workbook('./Data/weather.xls')
data=read.sheets()[0]
print(data.nrows)
print(data.ncols)

t1 = data.col_values(11)[1:]    # "Humidity9am"#
t1 = np.array(t1).astype(float)  # list array  to numpy
len=t1.shape[0]
X=np.reshape(t1, (len,1))
X=np.append(X,np.reshape(np.array(data.col_values(12)[1:]).astype(float) ,  (len,1)), axis=1) # Humidity3pm
X=np.append(X,np.reshape(np.array(data.col_values(4)[1:]).astype(float),  (len,1)), axis=1)   # Sunshine
X=np.append(X,np.reshape(np.array(data.col_values(9)[1:]).astype(float),  (len,1)), axis=1)   # WindSpeed9am
X=np.append(X,np.reshape(np.array(data.col_values(10)[1:]).astype(float),  (len,1)), axis=1)  # WindSpeed3pm
X=np.append(X,np.reshape(np.array(data.col_values(15)[1:]).astype(float),  (len,1)), axis=1)  # Cloud9am
X=np.append(X,np.reshape(np.array(data.col_values(16)[1:]).astype(float),  (len,1)), axis=1)  # Cloud3pm
# %%

t1 = data.col_values(23)[1:]    # "Label"
Y = np.array(t1).astype(int)  # list array  to numpy
#len=t1.shape[0]
#Y=np.reshape(Y, (1,len))

category=2
dim=X.shape[1]
x_train , x_test , y_train , y_test = train_test_split(X,Y,test_size=0.05)
y_train2=tf.keras.utils.to_categorical(y_train, num_classes=(category))
y_test2=tf.keras.utils.to_categorical(y_test, num_classes=(category))

print("x_train[:4]",x_train[:4])
print("y_train[:4]",y_train[:4])
print("y_train2[:4]",y_train2[:4])

# 建立模型
model = tf.keras.models.Sequential()
model.add(tf.keras.layers.Dense(units=200,
    activation=tf.nn.relu,
    input_dim=dim))
model.add(tf.keras.layers.Dense(units=200,
    activation=tf.nn.relu ))
model.add(tf.keras.layers.Dense(units=200,
    activation=tf.nn.relu ))
model.add(tf.keras.layers.Dense(units=200,
    activation=tf.nn.relu ))
model.add(tf.keras.layers.Dense(units=category,
    activation=tf.nn.softmax ))
model.compile(optimizer='adam',
    loss=tf.keras.losses.categorical_crossentropy,
    metrics=['accuracy'])
model.fit(x_train, y_train2, epochs=10000, batch_size=64)

#測試
model.summary()

score = model.evaluate(x_test, y_test2)
print("score:",score)

predict = model.predict(x_test)
print("Ans:",np.argmax(predict[0]),np.argmax(predict[1]),np.argmax(predict[2]),np.argmax(predict[3]))

predict2 = model.predict_classes(x_test)
print("predict_classes:",predict2)
print("y_test",y_test[:])


# %%
