# %%
import tensorflow as tf
import numpy as np
import matplotlib as plt
import matplotlib.pyplot as myplot


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
