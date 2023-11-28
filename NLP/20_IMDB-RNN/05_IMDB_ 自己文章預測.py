#!/usr/bin/env python
# -*- coding=utf-8 -*-
# 資料參考： https://keras.io/zh/examples/imdb_lstm/
__author__ = "柯博文老師 Powen Ko, www.powenko.com"


import tensorflow as tf
from tensorflow.keras.preprocessing import sequence
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Embedding
from tensorflow.keras.layers import LSTM
from tensorflow.keras.datasets import imdb

from tensorflow.keras.models import model_from_json


max_features = 20000
# cut texts after this number of words (among top max_features most common words)
# 在這個數量的單詞之後剪切文本（在 top max_features 最常見的單詞中）
maxlen = 80
batch_size = 32


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

def StringToInt(word_index,maxlen,str1):
    list1 = str1.split()
    i = 0
    while i < len(list1):
        word1 = list1[i]
        key1 =word_index.get(word1, 2)
        list1[i] = key1
        i = i + 1

    # 將每個資料整理為同一個長度
    list2=[list1]
    list2 = sequence.pad_sequences(list2, maxlen=maxlen)

    return list2

str1="I love this movie so much"
maxlen = 80
print(str1)
list2=StringToInt(word_index,maxlen,str1)
print(list2)



# 讀取模型架構
json_file = open('model.json', 'r')
loaded_model_json = json_file.read()
json_file.close()
model = tf.keras.models.model_from_json (loaded_model_json)
# 讀取模型權重
model.load_weights("model.h5")

model.compile(loss='binary_crossentropy',
              optimizer='adam',
              metrics=['accuracy'])
#測試

print('Train...')
model.fit(x_train, y_train,
          batch_size=batch_size,
          epochs=15,
          validation_data=(x_test, y_test))
score, acc = model.evaluate(x_test, y_test,
                            batch_size=batch_size)
print('Test score:', score)
print('Test accuracy:', acc)


predict = model.predict(x_test)
print("Ans:",np.argmax(predict[0]))



