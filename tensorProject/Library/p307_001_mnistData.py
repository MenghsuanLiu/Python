# %%
from mnist import MNIST
from typing import Tuple, NoReturn
import numpy as np
import tensorflow as tf

default_dim = 28

def dataProvisioning(dataset_path : str) -> Tuple[tf.Tensor]:
    mndata = MNIST(path = dataset_path, mode = "vanilla", return_type = "numpy",  gz = False)
    # X => image, y => label
    X_train, y_train = mndata.load_training()
    X_test, y_test = mndata.load_testing()
    
    X_train = tf.constant(X_train, dtype = tf.float64)
    y_train = tf.constant(y_train, dtype = tf.float64)
    X_test = tf.constant(X_test, dtype = tf.float64)
    y_test = tf.constant(y_test, dtype = tf.float64)
    
    return X_train, y_train, X_test, y_test

def imageRendering(imageRow : np.ndarray, value : int) -> NoReturn:
    t = imageRow.shape

    if len(t) != 1 or t[0] != default_dim * default_dim:
        raise None
    img_numpy = np.ndarray(shape = (default_dim, default_dim), dtype = np.uint8, buffer = np.array(imageRow, dtype = np.uint8))

    import cv2
    cv2.imshow("The number %d" % (value), img_numpy)
    k = cv2.waitKey()
    cv2.destroyAllWindows()
    return None
# %%
