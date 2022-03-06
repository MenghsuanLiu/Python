# %%
import tensorflow as tf

p = tf.Variable(2.0, dtype = tf.float64, trainable = True, synchronization = tf.VariableSynchronization.AUTO)
q = tf.Variable(3.0, dtype = tf.float64, trainable = True, synchronization = tf.VariableSynchronization.AUTO)

with tf.GradientTape( persistent = True) as tape:
    y = 2 * p * p + 3 * p * q + 4 * q * q

dy_dp = tape.gradient(y, p)
dy_dq = tape.gradient(y, q)
dy_all = tape.gradient(y, [p, q])
dy_bll = tape.gradient(y, [q, p])

print(dy_dp.numpy())
print(dy_dq.numpy())
print(dy_all)
print(dy_bll)
# %%
