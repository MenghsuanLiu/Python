# %%
import tensorflow as tf
import pandas as pd
from p304_005_linearmodel import lossCalculation

X_orig = [[29], [28], [34], [31], [25], [29], [32], [31], [24], [33], [25], [31], [26], [30]]
y_orig = [77, 62, 93, 84, 59, 64, 80, 75, 58, 91, 51, 73, 65, 84]

X_max = 50
X_min = -50
normed_max = 1.0

X_flatten = list(pd.DataFrame(X_orig)[0])

X_flatten.append(X_max)
X_flatten.append(X_min)

X_l2norm = tf.norm(tf.constant(X_flatten, dtype = tf.float64)).numpy()
y_l2norm = tf.norm(tf.constant(y_orig, dtype = tf.float64)).numpy()

print("Norm of X =", X_l2norm, ", y =", y_l2norm)

X = tf.constant(tf.clip_by_norm(tf.constant(X_flatten, dtype = tf.float64), clip_norm = normed_max).numpy()[:-2], dtype = tf.float64)
y = tf.clip_by_norm(tf.constant(y_orig, dtype = tf.float64), clip_norm = normed_max)

print("X =", X)
print("y =", y)

EPOCHS = 5000
LEARNING_RATE = 0.3

a = tf.Variable(initial_value = 2.0, dtype = tf.float64, trainable = True, synchronization = tf.VariableSynchronization.AUTO)
b = tf.Variable(initial_value = 1.0, dtype = tf.float64, trainable = True, synchronization = tf.VariableSynchronization.AUTO)

loss_his = []
a_his = [a.numpy()]
b_his = [b.numpy()]

for epo in range(EPOCHS):
    with tf.GradientTape() as tape:
        loss = lossCalculation(X, y, a, b)
    
    if len(loss_his) >= 1 and loss > loss_his[-1]:
        print("Halting: loss =", loss, ">", loss_his[-1])
        break
    else:
        if epo == 0 :
            loss_his.append(loss)
        loss_his.append(loss)
            
    delta_a, delta_b = tape.gradient(loss, [a, b])
    a.assign_sub(LEARNING_RATE * delta_a)
    b.assign_sub(LEARNING_RATE * delta_b)
        
    a_his.append(a.numpy())
    b_his.append(b.numpy())
        
    print("## Epoch", epo, ": loss =", loss.numpy(), ", delta_a =", delta_a.numpy(), ", delta_b =", delta_b.numpy(), ", new_a =", a.numpy(), ", new_b =", b.numpy())
# %%

for X_test in (40, 5, 15):
    X_normed = (X_test * normed_max) / X_l2norm
    y_normed = (b.numpy() + a.numpy() * X_normed)

    y_test = (y_normed * y_l2norm) / normed_max
    print(f"My Prediction: in case temp = {X_test}, The Sale = {y_test}")
# %%
import matplotlib.pyplot as plt

fig_a = plt.figure()


ax = fig_a.add_subplot()
ax.plot(range(EPOCHS + 1), loss_his, label = "Loss", color = "#FF0000")
ax.plot(range(EPOCHS + 1), a_his, label = "A", color = "#00FF00")
ax.plot(range(EPOCHS + 1), b_his, label = "B", color = "#0000FF")
ax.legend(loc = "best")
plt.show()

fig_b = plt.figure()
bx = fig_b.add_subplot()
bx.scatter(X.numpy(), y.numpy(), label = "observation", color = "#0000FF")
bx.plot(X.numpy(), tf.math.add(tf.math.multiply(X, a), b), label = "regression", color = "#FF0000")
bx.legend(loc = "best")
plt.show()

# %%
