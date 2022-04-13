# %%
from Library.p307_001_mnistData import dataProvisioning, imageRendering
from mnist import MNIST
import sys

if __name__ == "__main__":
    dataset_path = "./Data/mnist_dataset"

    X_train, y_train, X_test, y_test = dataProvisioning(dataset_path)

    print("X_train.shape = ", X_train.numpy().shape)
    print("y_train.shape = ", y_train.numpy().shape)
    print("X_test.shape = ", X_test.numpy().shape)
    print("y_test.shape = ", y_test.numpy().shape)

    train_maxcount = y_train.numpy().shape[0]

    select_input = int(input(f"Select the number of image you want to see: (Range from 0 to {train_maxcount - 1}) "))
    
    select_imgmap = X_train.numpy()[select_input]
    select_value = y_train.numpy()[select_input]

    print(f"The number of image you selected is: {select_value}({select_input})")
    print(MNIST.display(select_imgmap))
    imageRendering(select_imgmap, select_value)
    sys.exit(0)
# %%
import tensorflow as tf
y_true = tf.constant([0, 0], dtype = tf.float64)
y_pred = tf.constant([[1, 0],[0, 1]], dtype = tf.float64)
print(tf.keras.metrics.sparse_categorical_crossentropy(y_true, y_pred))
print(tf.keras.metrics.sparse_categorical_accuracy(y_true, y_pred))
# %%
