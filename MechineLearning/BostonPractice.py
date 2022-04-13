# %%
# from sklearn import datasets
import sklearn.datasets
import pandas as pd
import numpy as np
import scipy
import matplotlib.pyplot as plt

if __name__ == '__main__':
    # BostonDataSet = sklearn.datasets.load_boston()  
    # BostonDF = pd.DataFrame(data = BostonDataSet.data, columns = BostonDataSet.feature_names)
    # BostonDF["SalePrice"] = BostonDataSet.target

    # scipy.stats.skew(BostonDF.SalePrice)
    # scipy.stats.skew(np.log1p(BostonDF.SalePrice))

    # plt.hist(np.log1p(BostonDF.SalePrice))
    # plt.hist(BostonDF.SalePrice)


    BostonDataSetTrain = pd.read_csv("./Data/BostonHousePriceTrain.csv")
    BostonDataSetTest = pd.read_csv("./Data/BostonHousePriceTest.csv")


# %%
