# %%
import tensorflow as tf


def calculate_beta1(X: tf.Tensor, Y: tf.Tensor) -> float:
    if len(X) != len(Y):
        return None
    n = len(X)
    v1 = n * tf.math.reduce_sum(tf.math.square(X)).numpy()
    v2 = tf.math.reduce_sum(X).numpy() ** 2
    v3 = n * tf.math.reduce_sum(tf.math.multiply(X, Y)).numpy()
    v4 = tf.math.reduce_sum(X).numpy() * tf.math.reduce_sum(Y).numpy()
    # 參考 304_pythonTensorflowLibraries_20220119.pdf P37 Beta1公式
    return (v3 - v4) / (v1 - v2)


def calculate_beta0(X: tf.Tensor, Y: tf.Tensor) -> float:
    if len(X) != len(Y):
        return None
    n = len(X)

    beta1 = calculate_beta1(X, Y)
    y_avg = tf.math.reduce_mean(Y).numpy() / n
    x_avg = tf.math.reduce_mean(X).numpy() / n
    return y_avg - ( beta1 * x_avg )



X_org = [[29], [28], [34], [31], [25], [29], [32], [31], [24], [33], [25], [31], [26], [30]]
y_org = [77, 62, 93, 84, 59, 64, 80, 75, 58, 91, 51, 73, 65, 84]

X_flatten = []
for items in X_org :
    X_flatten.append(items[0])

X = tf.constant(X_flatten, dtype = tf.float32)
y = tf.constant(y_org, dtype = tf.float32)

b1 = calculate_beta1(X, y)
b0 = calculate_beta0(X, y)

print("b0 = ", b0)
print("b1 = ", b1)


for X_test in (40, 5, 15):
    y_test = int(b0 + b1 * X_test)
    print(f"My Predication: in case Temp: {X_test}, Sales = {y_test}")
# %%
import tensorflow as tf

def calculate_beta1(X : tf.Tensor, y : tf.Tensor) -> float:
    """
    Calculate b1.
    """
    if len(X) != len(y) :
        return None
    
    n = len(X)
    
    v1 = n * tf.reduce_sum(tf.square(X)).numpy()
    v2 = tf.reduce_sum(X).numpy() ** 2
    v3 = n * tf.reduce_sum(tf.multiply(X, y)).numpy()
    v4 = tf.reduce_sum(X).numpy() * tf.reduce_sum(y).numpy()
    
    return (v3 - v4) / (v1 - v2)

def calculate_beta0(X : tf.Tensor, y : tf.Tensor) -> float:
    """
    Calculate b0.
    """
    if len(X) != len(y) :
        return None
    
    n = len(X)
    
    beta1 = calculate_beta1(X, y)
    y_average = tf.reduce_sum(y).numpy() / n
    X_average = tf.reduce_sum(X).numpy() / n

    return y_average - (beta1 * X_average)

if __name__ == '__main__':
    
    X_orig = [[29], [28], [34], [31], [25], [29], [32], [31], [24], [33], [25], [31], [26], [30]]
    y_orig = [77, 62, 93, 84, 59, 64, 80, 75, 58, 91, 51, 73, 65, 84]
    
    #
    #    Preprocessing of X:    Flatten to one-dimensional list and do normalization
    #
    X_flatten = []
    for items in X_orig :
        X_flatten.append(items[0])
        
        
    X = tf.constant(X_flatten, dtype=tf.float32)
    y = tf.constant(y_orig, dtype=tf.float32)
    
    b1 = calculate_beta1(X, y)
    b0 = calculate_beta0(X, y)
    
    print("b0 = ", b0)
    print("b1 = ", b1)
    
    
    for X_test in (40, 5, 15) :
        y_test = int(b0 + b1 * X_test)
        
        print("My prediction: in case temp = %d, the sales = %d." % (X_test, y_test))
# %%
