"""
Original file is located at
    https://colab.research.google.com/drive/1Pm9poNxgiCXo2qplY-90K98iU8F_kUqW

!pip install mlxtend==0.20.0

資料來源：https://www.kaggle.com/competitions/house-prices-advanced-regression-techniques/overview

!git clone https://github.com/Wang-Jian-An/Feature_Selection.git
"""


# %%
import numpy as np
import pandas as pd

from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.model_selection import train_test_split
from sklearn.impute import KNNImputer

from xgboost import XGBRegressor

import warnings
warnings.filterwarnings("ignore")

raw_data = pd.read_csv("./Feature_Selection/train.csv")
raw_data.info()
# %%
# 把遺失值過多的欄位排除掉
raw_data = raw_data.dropna(axis = 1, thresh = int(round(raw_data.shape[0]*0.5)) )

# Define Features and Target
PK = "Id"
target = "SalePrice"
numerical_features = [i for i in raw_data.columns if i not in [PK, target] and raw_data[i].dtype != "object"]
classical_features = [i for i in raw_data.columns if i not in [PK, target] and raw_data[i].dtype == "object"]

# 切割成訓練、驗證與測試資料
xtrain, xtest, ytrain, ytest = train_test_split(raw_data[numerical_features+classical_features], raw_data[target], test_size = 0.2)

print(xtrain.shape, xtest.shape, ytrain.shape, ytest.shape)

def generate_one_hot_encoding_features(one_train_Series,
                                       one_test_Series):
    
    # 產生 One-Hot Encoding Object
    oneHotEncoding = OneHotEncoder(handle_unknown = "ignore")

    # 用訓練資料配適 One-Hot Encoding
    oneHotEncoding = oneHotEncoding.fit(one_train_Series.values.reshape((-1, 1)))

    # 產生 One-Hot Encoding 的資料型態
    oneHot_train_data = pd.DataFrame(oneHotEncoding.transform(one_train_Series.values.reshape((-1, 1))).toarray(), columns = oneHotEncoding.categories_[0].tolist() )
    oneHot_test_data = pd.DataFrame(oneHotEncoding.transform(one_test_Series.values.reshape((-1, 1))).toarray(), columns = oneHotEncoding.categories_[0].tolist() )

    return oneHot_train_data, oneHot_test_data

# 把類別資料轉成 One-Hot Encoding
OneHotEncoding_data = [generate_one_hot_encoding_features(one_train_Series = xtrain[one_column], one_test_Series = xtest[one_column]) for one_column in classical_features]

# 建立 One-Hot Encoding 後的訓練資料
preprocessed_xtrain = pd.concat([xtrain.reset_index(drop = True)] + [
    data[0] for data in OneHotEncoding_data
], axis = 1).drop(columns = classical_features)

# 建立 One-Hot Encoding 後的測試資料
preprocessed_xtest = pd.concat([xtest.reset_index(drop = True)]+[
    data[1] for data in OneHotEncoding_data
], axis = 1).drop(columns = classical_features)

print(preprocessed_xtrain.shape, preprocessed_xtest.shape)

# Imputation
KNNimputation = KNNImputer(weights = "distance")

# preprocessed_xtrain = KNNimputation.fit_transform(preprocessed_xtrain) # 輸出格式為 Array
# preprocessed_xtest = KNNimputation.transform(preprocessed_xtest) # 輸出格式為 Array

preprocessed_xtrain = pd.DataFrame(KNNimputation.fit_transform(preprocessed_xtrain), columns = preprocessed_xtrain.columns.tolist())
preprocessed_xtest = pd.DataFrame(KNNimputation.fit_transform(preprocessed_xtest), columns = preprocessed_xtest.columns.tolist())

preprocessed_xtrain

preprocessed_xtest.shape



"""# ANOVA"""

from scipy.stats import f_oneway

one_class_column = classical_features[0]

one_class_column

# 計算有幾個組別
unique_class = raw_data[one_class_column].unique()

unique_class

# 拆出五組連續變數
target1 = raw_data[raw_data[one_class_column] == unique_class[0]][target]
target2 = raw_data[raw_data[one_class_column] == unique_class[1]][target]
target3 = raw_data[raw_data[one_class_column] == unique_class[2]][target]
target4 = raw_data[raw_data[one_class_column] == unique_class[3]][target]
target5 = raw_data[raw_data[one_class_column] == unique_class[4]][target]

target_one_class = (target1, target2, target3, target4, target5)

f_oneway(target1, target2, target3, target4, target5)

f_oneway(*target_one_class)





# 判斷某個變數在類別變數之間是否有差異

def identify_difference_from_anova(data, column_name, target_name):
    
    # ANOVA
    f_statistics, f_pvalue = f_oneway(*tuple([data[data[column_name] == one_class][target_name] for one_class in data[column_name].unique()]) )
    
    if f_pvalue < 0.05:
        return column_name
    
significant_column = [identify_difference_from_anova(data = raw_data, column_name = one_column_name, target_name = target) for one_column_name in classical_features]

while None in significant_column:
    significant_column.remove(None)

significant_column

raw_data.corr()



"""# Exhaustive Feature Selection
評估指標參考連結：https://scikit-learn.org/stable/modules/model_evaluation.html#scoring-parameter 
"""

from mlxtend.feature_selection import ExhaustiveFeatureSelector

model = XGBRegressor()

# 建立特徵挑選物件
efs = ExhaustiveFeatureSelector(model,
                 min_features = 10,
                 max_features = 11,
                 scoring = "neg_mean_squared_error",
                 cv = 0)

# 開始執行特徵挑選
efs.fit(preprocessed_xtrain, ytrain)

# 輸出最好的特徵組合
efs.best_feature_names_



"""# Sequential Forward Selection

程式碼參考連結：http://rasbt.github.io/mlxtend/user_guide/feature_selection/SequentialFeatureSelector/#overview    
評估指標參考連結：https://scikit-learn.org/stable/modules/model_evaluation.html#scoring-parameter
"""

# from sklearn.feature_selection import SequentialFeatureSelector
from mlxtend.feature_selection import SequentialFeatureSelector

model = XGBRegressor()

# 建立特徵挑選物件
sfs = SequentialFeatureSelector(model, 
                 k_features = 10,
                 forward = True,
                 floating = False,
                 cv = 0)

# 開始執行特徵挑選
sfs.fit(preprocessed_xtrain, ytrain)

# 輸出每一輪特徵挑選狀況
sfs.subsets_

# 輸出被選入的特徵
sfs.k_feature_names_





"""# Sequential Backward Selection"""

# from sklearn.feature_selection import SequentialFeatureSelector
from mlxtend.feature_selection import SequentialFeatureSelector

model = XGBRegressor()

# 建立特徵挑選物件
sbs = SequentialFeatureSelector(model,
                 k_features = 200,
                 forward = False,
                 floating = False,
                 cv = 0)

# 開始執行特徵挑選
sbs.fit(preprocessed_xtrain, ytrain)

# 輸出特徵挑選過程

# 輸出被選入的特徵



"""# Sequential Floating Forward Selection"""

from mlxtend.feature_selection import SequentialFeatureSelector

model = XGBRegressor()

# 建立特徵挑選物件
sffs = SequentialFeatureSelector(estimator = model,
                  k_features = 50,
                  scoring = "neg_mean_squared_error",
                  cv = 0,
                  floating = True,
                  forward = True)

# 開始執行特徵挑選
sffs.fit(preprocessed_xtrain, ytrain)

# 輸出特徵挑選過程
sffs.subsets_

# 輸出被選入的特徵
sffs.k_feature_names_



"""# Sequential Floating Backward Selection"""

from mlxtend.feature_selection import SequentialFeatureSelector

model = XGBRegressor()

# 建立特徵挑選物件
sfbs = SequentialFeatureSelector(estimator = model,
                 k_features = 50,
                 floating = True,
                 cv = 0,
                 forward = False)

# 開始執行特徵挑選
sfbs.fit(preprocessed_xtrain, ytrain)

# 輸出被挑選到的特徵
sfbs.k_feature_names_



"""# Recursive Feature Elimination"""

from sklearn.feature_selection import RFE

model = XGBRegressor()

# 建立 RFE 物件
rfe = RFE(estimator = model, 
      n_features_to_select = 200,
      step = 5)

# 執行 RFE
rfe.fit(preprocessed_xtrain, ytrain)

# 輸出被選入的特徵
select_index = rfe.get_feature_names_out()
# print(select_index)

# 想知道特徵名稱
select_index = [eval(i[1:]) for i in select_index]

# 特徵名稱
print( np.array(preprocessed_xtrain.columns)[select_index] )







"""# Recursive Feature Elimination with Cross-Validation"""

from sklearn.feature_selection import RFECV

model = XGBRegressor()

# 建立 RFECV 物件
rfecv = RFECV(estimator = model,
        min_features_to_select = 200,
        step = 5,
        cv = 5,
        scoring = "neg_mean_squared_error",
        verbose = 1)

# 執行 RFECV
rfecv.fit(preprocessed_xtrain, ytrain)

rfecv.get_feature_names_out()

rfecv.cv_results_





