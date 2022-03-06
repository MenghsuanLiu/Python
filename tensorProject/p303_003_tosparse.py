# %%
from tkinter.messagebox import NO
from turtle import shape
import numpy as np
import tensorflow as tf

sp = [[0, 0, 9, 0], [0, 1, 0, 0], [5, 0, 9, 0], [8, 0, 0, 6]]
spArray = np.array(sp, dtype = np.uint8)
spTensor = tf.sparse.from_dense(spArray)

for idx in spTensor.indices:
    loc = idx.numpy().tolist()
    print(f"value in location({loc[0]}, {loc[1]}) is {sp[loc[0]][loc[1]]}")
# %%
import numpy as np
import tensorflow as tf

x = tf.Variable(1, dtype = tf.float64, shape = tf.TensorShape(None))
y = tf.Variable(2, dtype = tf.float64, shape = tf.TensorShape(None))

print("x = ", x.read_value())
print("y = ", y.read_value())
print("x + y = ", x.assign_add(y))
print("x = ", x.read_value())
print("x = ", x.assign([3, 4]))



# print(x.read_value())
# x.assign([3, 4])
# print(x)
# y.assign([1, 2])
# x.assign_sub(y)
# print(x.numpy().tolist())

# %%
