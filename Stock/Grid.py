# %%
import numpy as np

#預設值
BiasUpper = 2.0
UpperPosition = 0.3
BiasLower = 0.5
LowerPosition = 0.7
BiasPeriod = 20

list_Grid_range = [np.arange(1.0, 2.1, 0.1), np.arange(UpperPosition, UpperPosition + 0.1, 0.1), np.arange(0.1, 1.0, 0.1), np.arange(LowerPosition, LowerPosition + 0.1, 0.1), np.arange(BiasPeriod, BiasPeriod + 5, 5)]
# %%
