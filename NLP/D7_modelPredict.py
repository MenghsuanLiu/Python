# %%
import tensorflow as tf
import numpy as np
from tensorflow.keras import models
from tensorflow.keras.models import model_from_json


# 讀取模型架構
json_file = open("./Model/chinese_model.json", 'r')
loaded_model_json = json_file.read()
json_file.close()
model = model_from_json(loaded_model_json)
# 讀取模型權重
model.load_weights("./Model/chinese_model.h5")


model.compile(
    optimizer=tf.keras.optimizers.Adam(),
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
    metrics=['accuracy'],
)



# %%
import tensorflow as tf

# 假设我们有一个词汇表大小为10，每个单词表示为一个整数
vocab_size = 10
embedding_dim = 4  # 嵌入向量的维度

# 创建嵌入层
embedding_layer = tf.keras.layers.Embedding(input_dim = vocab_size, output_dim = embedding_dim)

# 输入数据，这里假设我们有一个句子，其中的每个单词用整数表示
input_data = tf.constant([1, 2, 3, 1, 5], dtype=tf.int32)

# 使用嵌入层将整数转换为嵌入向量
embedded_data = embedding_layer(input_data)

# 打印结果
print("原始输入数据：", input_data)
print("嵌入后的数据：\n", embedded_data)
# %%
import numpy as np

# 假設詞彙表大小為N，嵌入維度為d
N = 10
d = 4

# 創建隨機嵌入矩陣
embedding_matrix = np.random.rand(N, d)

# 假設輸入單詞的整數表示是i
i = 3

# 獲取輸入單詞的嵌入向量
embedding_vector = embedding_matrix[i]

print("嵌入向量：", embedding_vector)
# %%
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Embedding, Flatten, Dense

# 假設我們有一個字典大小為10，每個詞彙的嵌入維度為4
vocab_size = 10
embedding_dim = 4

# 建立模型
model = Sequential()
model.add(Embedding(input_dim=vocab_size, output_dim=embedding_dim, input_length=3))  # 嵌入層
model.add(Flatten())  # 平坦化層
model.add(Dense(units=5, activation='relu'))  # 全連接層
model.add(Dense(units=2, activation='sigmoid'))  # 輸出層

# 編譯模型
model.compile(optimizer='adam',
            loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
            metrics=['accuracy'])

# 創建假訓練資料（3筆）
X_train = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9]])
y_train = np.array([0, 1, 1])

# 訓練模型
model.fit(X_train, y_train, epochs=10, batch_size=1)

# 顯示模型結構
model.summary()

# 進行預測
X_pred = np.array([[1, 2, 3], [4, 5, 6]])
predictions = model.predict(X_pred)

print("預測結果：", predictions)

# %%
# 獲取嵌入層的權重
embedding_weights = model.layers[0].get_weights()[0]
print("嵌入層權重：")
print(embedding_weights)

# 獲取全連接層的權重和偏差
dense_weights = model.layers[2].get_weights()[0]
dense_bias = model.layers[2].get_weights()[1]
print("全連接層權重：")
print(dense_weights)
print("全連接層偏差：")
print(dense_bias)
# %%
