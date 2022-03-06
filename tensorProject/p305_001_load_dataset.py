# %%
import tensorflow as tf
import pandas as pd

(X_train, y_train), (X_test, y_test) = tf.keras.datasets.boston_housing.load_data(path = "boston_housing.npz", test_split = 0.3, seed = 119)

print(type(X_train), X_train.shape)
print(type(X_test), X_test.shape)
print(type(y_train), y_train.shape)
print(type(y_test), y_test.shape)


# col1_X_train = X_train[:, 0]

iTensor_Xtrain = tf.linalg.matrix_transpose(tf.constant([X_train[::,0], X_train[::,7]], dtype = tf.float64))
iTensor_Xtest = tf.linalg.matrix_transpose(tf.constant([X_test[::,0], X_test[::,7]], dtype = tf.float64))
print("## training data set with shape = ", iTensor_Xtrain.shape, "##")
# print(iTensor_Xtrain.numpy())

print("## testing data set with shape = ", iTensor_Xtest.shape, "##")
# print(iTensor_Xtest.numpy())

oTensor_ytrain = tf.constant(y_train, dtype=tf.float64)
oTensor_ytest = tf.constant(y_test, dtype=tf.float64)

print("## training tag set of y with shape = ", oTensor_ytrain.shape, "##")
# print(oTensor_ytrain.numpy())

print("## test tag set of y with shape = ", oTensor_ytest.shape, "##")
# print(oTensor_ytest.numpy())
# %%
