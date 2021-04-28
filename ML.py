# %%
import numpy as np
from sklearn.svm import SVR
import matplotlib.pyplot as plt

X = np.sort(5 * np.random.rand(40, 1), axis = 0)
X
# %%
y = np.sin(X).ravel()
y[::5] += 3 * (0.5 - np.random.rand(8))
y
# %%
# svr_rbf = SVR( kernel = "rbf", C = 100, gamma = 0.1, epsilon =)