# %%
import tensorflow as tf
import numpy as np

v1 = tf.constant(100)
v2 = tf.constant(100.1)
v3 = tf.constant("Hello, world")
v4 = tf.constant(np.array([[1, 2, 3], [4, 5, 6]]))
v5 = tf.constant(np.array([[1, 2, 3], [4, 5, 6]]), dtype = tf.float64)
v6 = tf.constant(100.1, shape = (2, 3, 4))
# v7 = tf.constant(100.1, dtype = tf.string)
# v8 = tf.constant(np.array([[1, 2, 3], [4, 5, 6]]), shape = (5, 5, 5))
v6_array = v6.numpy()
v6_array.tolist()
# %%
import tensorflow as tf
rt1 = tf.ragged.constant(pylist = [[1, 2, 3, 4], [5, 6], [7, 8, 9, 10]], dtype = tf.float16)
# rt2 = tf.ragged.constant(pylist = [[1, 2, [3], 4], [5, [6]], [7, 8, [9, 10]]], dtype = tf.float16)
rt1_list = rt1.to_list()
rt1_tensor = rt1.to_tensor(default_value = -1, shape = (rt1.bounding_shape()[0] + 1, rt1.bounding_shape()[1] + 1))
# %%


# %%
# Reshape
import tensorflow as tf
l1 = [[212, 39, 4], [0, 143, 84], [15, 77, 179]]
l2 = [[155, 57, 32], [61, 149, 25], [3, 19, 188]]
l3 = [[203, 41, 12], [56, 229, 43], [22, 68, 251]]

tf1 = tf.constant(l1, dtype = tf.uint8)
tf2 = tf.constant(l2, dtype = tf.uint8)
tf3 = tf.constant(l3, dtype = tf.uint8)

rstf1 = tf.reshape(tf1, shape = (tf1.shape[0] * tf1.shape[1],))
rstf2 = tf.reshape(tf2, shape = (tf2.shape[0] * tf2.shape[1],))
rstf3 = tf.reshape(tf3, shape = (tf3.shape[0] * tf3.shape[1],))

allrt = tf.ragged.constant(pylist = [rstf1.numpy().tolist(), rstf2.numpy().tolist(), rstf3.numpy().tolist()], dtype = tf.uint8)

tf_all = allrt.to_tensor()

print("#### The integrated Tensor (viewed as %s ndarray) ####" % str(tf_all.numpy().shape), tf_all.numpy(), sep="\n")

# %%
# 工廠方法
import tensorflow as tf
rsplit_rt1 = tf.RaggedTensor.from_row_splits(values=[3, 1, 4, 1, 5, 9, 2, 6], row_splits=[0, 4, 4, 7, 8, 8])
# 運算子

r1 = tf.ragged.constant([[10, 30, 50], [20, 40], [60, 70, 80, 90, 100]], dtype = tf.int8)
r2 = tf.ragged.constant([[1, 3, 5], [2, 4], [6, 7, 8, 9, 10]], dtype = tf.int8)
r3 = tf.constant(10, dtype = tf.int8)

print(r1 * 5) # [[50, -106, -6], [100, -56], [44, 94, -112, -62, -12]]因為給Type是int8,會overflow
print(r1 + r2)
print(r1 // r3)
print(r3 / r1)




# %%
