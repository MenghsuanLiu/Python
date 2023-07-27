# Python
Python Practice


# 開設虛擬環境
python -m venv <path>\<folder> 
Ex: python -m venv D:\Python_venv\310_venv

# 關閉虛擬環境
deactivate

# 升級虛擬環境內的 python
python -m venv --upgrade myEnv

# 安裝的套件寫到txt
pip freeze > <path>\<filename>
Ex: pip freeze > D:\Python_venv\requirements.txt

# 安裝txt內的套件
pip install -r <path>\<filename>
Ex: pip install -r requirements.txt

# 比較所有的套件是否為最新版
pip list --outdated

# 更新所有套件到最新版
pip freeze | %{$_.split('==')[0]} | %{pip install --upgrade $_}
