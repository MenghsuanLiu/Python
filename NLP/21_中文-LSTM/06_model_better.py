#!/usr/bin/env python
# -*- coding=utf-8 -*-
# 資料參考： https://hackmd.io/@PR2kjoVmQFqNCTuwMivDww/ByKb7Z0AE
__author__ = "柯博文老師 Powen Ko, www.powenko.com"
# pip install https://github.com/APCLab/jieba-tw/archive/master.zip


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
print(len(train),len(test),len(labels_train),len(labels_test))
"""
步驟五：取得及設定停用詞
上網搜尋停用詞，取得對於訓練資料無意義的用詞與符號，存成txt檔，接著讀取文字檔內容，並將各個停用詞以斷行符號\n分割，取得stopWordslist：
"""


stopWords=[]
with open('stopWord.csv', 'r', encoding='utf8') as f:
    stopWords = f.read().split('\n')
stopWords.append('\n')
print(stopWords)

"""
步驟六：使用結巴(jieba)中文分詞
由於中文不像英文一個一個單字都是分開的，因此要使用一些工具，來協助斷詞，我選擇使用結巴(jieba)，它是一個開源的中文斷詞套件，可以將所有的評論分詞，例如：

我今天很快樂

這句話經過結巴斷詞後便會被分成

['我','今天','很','快樂']

接著再使用前面設定的stopWords，將一些無意義的斷詞移除，如下：
"""



import jieba
sentence=[]
sentence_test=[]

import jieba.analyse
jieba.analyse.set_stop_words("stopWord.csv")
#透過jieba分詞工具，分別處理train和test資料
for content in train:
    _sentence=list(jieba.cut(content, cut_all=True))
    sentence.append(_sentence)
for content in test:
    _sentence=list(jieba.cut(content, cut_all=True))
    sentence_test.append(_sentence)

remainderWords2 = []
remainderWords_test = []

#將斷詞分別從train和test資料中移除
for content in sentence:
    remainderWords2.append(list(filter(lambda a: a not in stopWords, content)))
for content in sentence_test:
    remainderWords_test.append(list(filter(lambda a: a not in stopWords, content)))

print(train[:2])
print(remainderWords2[:2])




"""
步驟七：建立token字典
使用Tokenizer建立大小為3000的字典，接著透過fit_on_texts()方法將訓練的留言資料中，依照文字出現次數排序，而前3000個常出現的單字將會列入token字典中。

"""
from tensorflow.keras.preprocessing.text import Tokenizer
token = Tokenizer(num_words=3000)
token.fit_on_texts(remainderWords2)


#建立完成字典後，透過word_index屬性將其內容列印，便可以查看到3000最常出現的單字，其順序是依照單字出現次數的多寡排序：


print(token.word_index)

"""
步驟八：建立數字list
接著，透過token的texts_to_sequences()方法將訓練及測試資料轉換為數字list。
"""
x_train_seq = token.texts_to_sequences(remainderWords2)
x_test_seq = token.texts_to_sequences(remainderWords_test)
"""
例如第一句評論

['超级', '美味', '神速']

對應到字典便會轉換為

[44, 288, 338]

表示超級這個詞彙對應到字典的第44個排序。
"""

print(x_train_seq)

"""
此外，由於keras只接受長度一樣的list輸入，因此必須使用sequence的pad_sequences()方法，將序列後的訓練及測試資料長度限制在50，表示當list長度超過50時，會自動切斷多出來的內容，反之list長度小於50時便會自動補0，直到長度為50。
"""

import tensorflow as tf
from tensorflow.keras.preprocessing import sequence
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Embedding, Dropout, Activation,Flatten
from tensorflow.keras.layers import LSTM



print(len(x_train_seq),len(x_test_seq) )
x_train = sequence.pad_sequences(x_train_seq, maxlen=50)
x_test = sequence.pad_sequences(x_test_seq, maxlen=50)

print(len(x_train),len(x_test) )
print(x_train)
"""
例如第100筆資料有5個字詞，那剩下的便會補上45個0。


三、建立模型
開始建立MLP模型前需要先引入相關的模組，如下：
"""
"""
接著開始建立模型，其中參數的設定就是一直try and error，找出可以得得最高精確率的設定。

加入Embedding層，並設定output_dim輸出維度為128，而input_dim輸入維度則是與前面設定的字典大小相同為3000，input_length也與前面設定序列長度相同50。
轉換為Flatten平坦層，表示會有3000 * 128
個神經元。
加入隱藏層，並設定神經元為256個，其中激活函數設定為relu，表示資料會捨去負數，並介於0到無限大區間。
加入輸出層，並設定輸出為2個神經元，並定義激活函數為sigmoid表示資料為0或1。
"""
model = Sequential()

model.add(Embedding(output_dim=128, input_dim=3000, input_length=50))

model.add(LSTM(128, dropout=0.2, recurrent_dropout=0.2))
model.add(Dropout(0.2))

model.add(Flatten())

model.add(Dense(units=256, activation='relu'))
model.add(Dropout(0.2))

model.add(Dense(units=2, activation='sigmoid'))
model.summary()

"""
列出模型摘要：


四、開始訓練模型
建立完MLP模型後，便可以透過model.compile()
設定訓練模型的方式，最後以model.fit()
開始訓練。
"""
model.compile(loss='binary_crossentropy',
              optimizer='adam',
              metrics=['accuracy'])

train_history = model.fit(x_train,
                          labels_train,
                          batch_size=100,
                          epochs=10,
                          validation_split=0.2)
"""
執行後便會開始訓練模型，並一一列出每次週期的訓練結果，如下：


五、情緒分析預測結果
將test測試的資料加入模型評估結果，並取得模型正確率。
"""
scores = model.evaluate(x_test, labels_test)

"""
scores[1]
預測結果：


透過predict_classes()
方法取得test資料的預測結果，並且轉為一維陣列，接著建立一個方法查看預測結果是否正確。
"""
predict = model.predict_classes(x_test)
print(np.argmax(model.predict(x_test), axis=-1))


def display_test_Sentiment(i):
    print(test[i])
    print('原始結果:', labels_test[i])
    print('預測結果:', predict[i])

"""
呼叫display_test_Sentiment()
並傳入要查看的資料編號。
"""
display_test_Sentiment(0)


path="/content/drive/MyDrive"
path=""
#保存模型架構
with open(path+"model.json", "w") as json_file:
   json_file.write(model.to_json())
#保存模型權重
model.save_weights(path+"model.h5")




import matplotlib.pyplot as plt


def show_train_history(train_acc, test_acc):
    plt.plot(train_history.history[train_acc])
    plt.plot(train_history.history[test_acc])
    plt.title('Train History')
    plt.ylabel('Accuracy')
    plt.xlabel('Epoch')
    plt.legend(['train', 'test'], loc='upper left')
    plt.show()

show_train_history('accuracy','val_accuracy')





"""
因此，接下來便要開始嘗試提高準確度並且改善Overfitting的問題。

六、提升準確率
步驟一：去除重複字
除了一般的停用字，在各評論當中也會有出現一些對於判斷正負面評論較無意義的詞彙，因此接下來我們就要找出這些詞，並手動加入停用字當中囉！

首先，一樣要經過jieba分詞，並先去除一般的停用字，而我們將資料分為所有的訓練評論資料、正面與負面評論三種，在後面會比較好比對哪些是較無意義的詞彙，如下：

from collections import Counter
segments=[]
segments_postive=[]
segments_negative=[]

#全部訓練資料分詞
for content in train:
    _sentence=list(jieba.cut(content, cut_all=True))
    segments+=_sentence
#正面評論分詞
for content in train_postive:
    _sentence=list(jieba.cut(content, cut_all=True))
    segments_postive+=_sentence
#負面評論分詞
for content in train_negative:
    _sentence=list(jieba.cut(content, cut_all=True))
    segments_negative+=_sentence

#去除訓練、正面與負面評論的停用詞
remainderWords = list(filter(lambda a: a not in stopWords, segments))
remainderWords_postive = list(filter(lambda a: a not in stopWords, segments_postive))
remainderWords_negative = list(filter(lambda a: a not in stopWords, segments_negative))
#排序並計算三種資料的詞彙出現次數：

sorted(Counter(remainderWords).items(), key=lambda x:x[1], reverse=True)
sorted(Counter(remainderWords_postive).items(), key=lambda x:x[1], reverse=True)
sorted(Counter(remainderWords_negative).items(), key=lambda x:x[1], reverse=True)
#查看結果，我將像送、餐、吃較無意義的詞拿掉，且像餅、卷正負面評論比例差不多的字也拿掉，像是小時或不錯這種比例懸殊詞的便留下。

from wordcloud import WordCloud
from matplotlib import pyplot as plt
#記得要加上字型檔，否則會出現錯誤
wordcloud = WordCloud(font_path="Microsoft JhengHei.ttf")
wordcloud.generate_from_frequencies(frequencies=Counter(remainderWords))
plt.figure(figsize=(15,15))
plt.imshow(wordcloud, interpolation="bilinear")
plt.axis("off")
plt.show()
"""