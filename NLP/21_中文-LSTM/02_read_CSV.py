#!/usr/bin/env python
# -*- coding=utf-8 -*-
# 資料參考： https://hackmd.io/@PR2kjoVmQFqNCTuwMivDww/ByKb7Z0AE
__author__ = "柯博文老師 Powen Ko, www.powenko.com"



import os
import urllib.request

url="https://raw.githubusercontent.com/SophonPlus/ChineseNlpCorpus/master/datasets/waimai_10k/waimai_10k.csv"
#設定儲存的檔案路徑及名稱
filepath="waimai_10k.csv"
# 判斷檔案是否存在，若不存在才下載
if not os.path.isfile(filepath):
    # 下載檔案
    result=urllib.request.urlretrieve(url,filepath)
    print('downloaded:',result)




"""
步驟二：查看資料
載完資料後，便可以查看資料筆數：
"""
import pandas as pd
pd_all = pd.read_csv('waimai_10k.csv')

print('評論數目（全部）：%d' % pd_all.shape[0])
print('評論數目（正面）：%d' % pd_all[pd_all.label==1].shape[0])
print('評論數目（負面）：%d' % pd_all[pd_all.label==0].shape[0])


"""
二、資料預處理
接著，我們開始將資料從csv檔中取出，並進行資料的預處理。

步驟一：讀取csv檔案
建立read_files()方法，取得資料：
"""

import csv
import numpy as np
def read_files():
    path = 'waimai_10k.csv'
    label = []
    all_texts = []
    all_label = []
    #取得review資料
    with open(path, newline='') as csvfile_train:
        reader = csv.DictReader(csvfile_train)
        content = [row['review'] for row in reader]
        all_texts+=content
    #取得label資料
    with open(path, newline='') as csvfile_label:
        reader = csv.DictReader(csvfile_label)
        tag = [row['label'] for row in reader]
        label+=tag
    #將label list的值轉為int格式
    all_label = list(map(int, label))
    return all_texts,all_label

# 呼叫read_files()方法，取得訓練資料train與label標籤：

train,label=read_files()
print(train[3999])
print(label[3999])
print(train[4000])
print(label[4000])



"""
步驟二：打亂資料順序
從前面查看資料時，可以知道正面的評論為4000筆，負面的評論為7987筆，兩個資料量懸殊，因此我們要平均資料量，將負面的評論只取4000筆：
"""
train = train[:8000]
label = label[:8000]


# 由於資料都是依照正負評論順序排列，為了讓資料自然一點，我們要將資料的順序打亂，如下：

import random
x_shuffle=train
y_shuffle=label
z_shuffle = list(zip(x_shuffle, y_shuffle))

random.shuffle(z_shuffle)

x_train, y_label = zip(*z_shuffle)
print(label[:10])
print(y_label[:10])

"""
步驟三：label序列化
為了要符合訓練模型的格式，我們需要將label資料序列化，如下：

"""
import tensorflow as tf
y_label = tf.keras.utils.to_categorical(y_label, 2)

"""
查看序列化的結果，[0 1]代表1正面評論，[1 0]代表0負面評論：


步驟四：將資料分割為訓練資料與測試資料
由於原始資料沒有提供測試的資料，因此我們必須自己將資料切分，8成的資料(6400)為訓練資料，2成的資料(1600)為測試資料，如下：

"""
NUM_TRAIN = int(8000 * 0.8)
train, test = x_train[:NUM_TRAIN], x_train[NUM_TRAIN:]
labels_train, labels_test = y_label[:NUM_TRAIN], y_label[NUM_TRAIN:]

"""
步驟五：取得及設定停用詞
上網搜尋停用詞，取得對於訓練資料無意義的用詞與符號，存成txt檔，接著讀取文字檔內容，並將各個停用詞以斷行符號\n分割，取得stopWordslist：
"""


stopWords=[]
with open('stopWord.csv', 'r', encoding='utf8') as f:
    stopWords = f.read().split('\n')
stopWords.append('\n')
print(stopWords)
