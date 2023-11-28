#!/usr/bin/env python
# -*- coding=utf-8 -*-
# 資料參考： https://keras.io/zh/examples/imdb_lstm/
# __author__ = "柯博文老師 Powen Ko, www.powenko.com"


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
(x_train, y_train), (x_test, y_test) = imdb.load_data(num_words=max_features)
print(len(x_train), 'train sequences')
print(len(x_test), 'test sequences')
print(y_train[:30])
print(x_train[0],x_train[1])
print("長度:",len(x_train[0]),len(x_train[1]))


"""
將整數轉換回單詞
了解如何將整數轉換回文本可能很有用。 在這裡，我們將創建一個輔助函數來查詢包含整數到字符串映射的字典對象：
"""

# A dictionary mapping words to an integer index
# 將單詞映射到整數索引的字典
word_index = imdb.get_word_index()

# The first indices are reserved
# 第一個索引被保留
word_index = {k:(v+3) for k,v in word_index.items()}
word_index["<PAD>"] = 0
word_index["<START>"] = 1
word_index["<UNK>"] = 2  # unknown
word_index["<UNUSED>"] = 3

reverse_word_index = dict([(value, key) for (key, value) in word_index.items()])

def decode_review(text):
    return ' '.join([reverse_word_index.get(i, '?') for i in text])

print(decode_review(x_train[0]))