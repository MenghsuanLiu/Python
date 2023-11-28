#!/usr/bin/env python
# -*- coding=utf-8 -*-
# 資料參考： https://keras.io/zh/examples/imdb_lstm/
# __author__ = "柯博文老師 Powen Ko, www.powenko.com"
# %%
import tensorflow as tf
from tensorflow.keras.preprocessing import sequence
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Embedding
from tensorflow.keras.layers import LSTM
from tensorflow.keras.datasets import imdb

max_features = 20000
# cut texts after this number of words (among top max_features most common words)
# 在這個數量的單詞之後剪切文本（在 top max_features 最常見的單詞中）
maxlen = 80
batch_size = 32

print('Loading data...')
(x_train, y_train), (x_test, y_test) = imdb.load_data(num_words = max_features)
print(len(x_train), 'train sequences')
print(len(x_test), 'test sequences')
print(y_train[:30])
print(x_train[0],x_train[1])
print("長度:",len(x_train[0]),len(x_train[1]))

# 將每個資料整理為同一個長度
print('Pad sequences (samples x time)')
x_train = sequence.pad_sequences(x_train, maxlen=maxlen)
x_test = sequence.pad_sequences(x_test, maxlen=maxlen)
print('x_train shape:', x_train.shape)
print('x_test shape:', x_test.shape)
print("長度:",len(x_train[0]),len(x_train[1]))

# %%
