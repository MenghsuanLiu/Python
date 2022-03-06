# %%
import tensorflow as tf

@tf.function
def flatten(tf1 = tf.Tensor, tf2 = tf.Tensor, tf3 = tf.Tensor) -> tuple:
    print("Eager execution:", tf.executing_eagerly())
    vtor1 = tf.reshape(tf1, (tf1.shape[0] * tf1.shape[1],))
    vtor2 = tf.reshape(tf2, (tf2.shape[0] * tf2.shape[1],))
    vtor3 = tf.reshape(tf3, (tf3.shape[0] * tf3.shape[1],))
    return vtor1, vtor2, vtor3
    # return tf.ragged.constant([vtor1.numpy().tolist(), vtor2.numpy().tolist(), vtor3.numpy().tolist()], dtype = tf.uint8)

print("Eager execution:", tf.executing_eagerly())
f1 = [[212, 39, 4], [0, 143, 84], [15, 77, 179]]
f2 = [[155, 57, 32], [61, 149, 25], [3, 19, 188]]
f3 = [[203, 41, 12], [56, 229, 43], [22, 68, 251]]

tf1 = tf.constant(f1, dtype = tf.uint8)
tf2 = tf.constant(f2, dtype = tf.uint8)
tf3 = tf.constant(f3, dtype = tf.uint8)

v1, v2, v3 = flatten(tf1, tf2, tf3)
almx = tf.ragged.constant([v1.numpy().tolist(), v2.numpy().tolist(), v3.numpy().tolist()], dtype = tf.uint8)
# almx = flatten(tf1, tf2, tf3)
altensor = almx.to_tensor()

print("#### The integrated Tensor (viewed as %s ndarray) ####" % str(altensor.numpy().shape), altensor.numpy(), sep="\n")
# %%
