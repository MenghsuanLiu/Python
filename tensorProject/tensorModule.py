# %%
import tensorflow as tf
import numpy as np
import matplotlib as plt
import matplotlib.pyplot as myplot

# %%
if __name__ == "__main__":
    print(np.__version__)
    print(plt.__version__)
    print(tf.__version__)

    x = [1, 2, 3, 4, 5]
    y = [1, 4, 9, 16, 25]

    myplot.plot(x, y)
    myplot.show()

    del plt, myplot, np, tf
# %%
import numpy as np
# array_01 = np.ndarray(shape=(3, 4, 5))
# array_02 = np.ndarray(shape=(3, 4, 5), dtype=int)
# array_03 = np.ndarray(shape=(2, 2, 2), dtype=int, buffer=np.array([1, 3, 5, 7, 9, 11]))
# array_04 = np.ndarray(shape=(2, 2, 2), dtype=int, buffer=np.array([1, 3, 5, 7, 9, 11, 13, 15,
# 17, 19]))
# array_05 = np.ndarray(shape=(2, 2, 2), dtype=int, buffer=np.array([1, 3, 5, 7, 9, 11, 13, 15,
# 17, 19]), offset=1 * np.int_().itemsize)
# array_06 = np.ndarray(shape=(2, 2, 2), dtype=int, buffer=np.array([1, 3, 5, 7, 9, 11, 13, 15,
# 17, 19]), order='F')
array_07 = np.ndarray(shape=(2, 2, 2), dtype=np.uint64, buffer=np.array([1, 3, 5, 7, 9, 11,
13, 15, 17, 19], dtype=np.uint64), order='C')
# %%
