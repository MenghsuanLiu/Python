# %%
from sklearn import datasets
import pandas as pd

X, y = datasets.load_iris(return_X_y=True)

print('The shape of X: ', X.shape, ' The shape of y: ', y.shape)

X_df = pd.DataFrame(X)
X_df.describe()


datasets.load_iris().feature_names
datasets.load_iris().target_names
X = datasets.load_iris().data
y = datasets.load_iris().target
# %%
