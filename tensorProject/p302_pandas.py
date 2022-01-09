# %%
from datetime import datetime
import pandas as pd
import numpy as np
from pandas.core.indexes.base import Index

myseries_01 = pd.Series([1, 3, 5, 7, 9])
myseries_02 = pd.Series(dict(name = "Me", age = 44))
myseries_03 = pd.Series(np.array([7.1, 7.2, 7.3, 7.4], dtype = np.float64))
myseries_04 = pd.Series(dict(name = "Me", age = 44), index = ["FAKENAME", "FAKEAGE"])
myseries_05 = pd.Series(np.array([7.1, 7.2, 7.3, 7.4], dtype = np.float64), index = ["first", "second", "third", "fourth"])
# myseries_06 = pd.Series(dict(name="Me", age=44), dtype=np.uint8)
myseries_07 = pd.Series(np.array([7.1, 7.2, 7.3, 7.4], dtype = np.float64), index = ["p", "q", "r", "s"], name = "Test row")
# %%
import pandas as pd
import numpy as np

# pd.Series(dict(first=100, second=44, third=None)).to_numpy(dtype = np.uint8, na_value = 0)

mytable_06 = pd.DataFrame(data = dict(sno = range(0, 5), sname = ('me', 'you', 'him', 'some','other'), age = np.array([10, 30, 50, 90, 70], dtype = np.uint8)), index=['first', 'second', 'third','fourth', 'fifth'])

print(f"這表格有幾欄幾列: {mytable_06.shape}")
print(f"所有同學的名字: {mytable_06.sname.to_list()}")
print(f"第四位同學的年齡: {mytable_06.iat[3, 2]}")
print(f"班上年紀最大是幾歲呢: {mytable_06.age.max()}")
print(f"有沒有同學年齡是 120 歲: {120 in mytable_06.age}")
print(f"找出最後一筆資料的索引名稱: {mytable_06.index[-1]}")
print(f"最後一筆資料的內容: {mytable_06.iloc[-1].to_dict()}")

mytable_06 = mytable_06.append(pd.DataFrame(data = [[5, "else", 110]], index = ["sixth"], columns = ["sno", "sname", "age"]))
# %%
