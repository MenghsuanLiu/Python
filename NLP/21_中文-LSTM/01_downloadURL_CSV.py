#!/usr/bin/env python
# -*- coding=utf-8 -*-
# 資料參考： https://hackmd.io/@PR2kjoVmQFqNCTuwMivDww/ByKb7Z0AE
__author__ = "柯博文老師 Powen Ko, www.powenko.com"



import os
import urllib.request

url="https://raw.githubusercontent.com/SophonPlus/ChineseNlpCorpus/master/datasets/waimai_10k/waimai_10k.csv"
#設定儲存的檔案路徑及名稱
filepath="waimai_10k.csv"
# 判斷檔案是否存在，若不存在才下載
if not os.path.isfile(filepath):
    # 下載檔案
    result=urllib.request.urlretrieve(url,filepath)
    print('downloaded:',result)

