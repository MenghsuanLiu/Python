# %%
import tensorflow as tf

@tf.function
def myNorm(input: tf.Tensor) -> tf.Tensor:
    print("Eager mode:", tf.executing_eagerly())
    return tf.math.sqrt(tf.math.reduce_sum(tf.math.square(input))) # 平方和开根号

temp = tf.constant([29, 28, 34, 31, 25, 29, 32, 31, 24, 33, 25, 31, 26, 30], dtype = tf.float32)
sale = tf.constant([77, 62, 93, 84, 59, 64, 80, 75, 58, 91, 51, 73, 65, 84], dtype = tf.float32)

temp_norm = tf.norm(temp)
sale_norm = tf.norm(sale)

temp_normalized = tf.clip_by_norm(temp, clip_norm=1.0)
sale_normalized = tf.clip_by_norm(sale, clip_norm=1.0)

print("The L2-norm of temperature data:", temp_normalized.numpy())
print("\nThe L2-norm of sales data:", sale_normalized.numpy())

print("The norm of temperature data(MyNorm):", myNorm(temp).numpy())
print("The norm of temperature data:", temp_norm.numpy())

print("The norm of temperature data(MyNorm):", myNorm(sale).numpy())
print("The norm of temperature data:", sale_norm.numpy())

# %%
import tensorflow as tf
A = tf.constant([[-1, 1, 2], [3, -1, 1], [-1, 3, 4]], dtype = tf.float32)
A_inverse = tf.linalg.inv(A)
I = tf.linalg.matmul(A, A_inverse)
print(A_inverse)
print(tf.cast(I, dtype=tf.uint8))
# %%
