# %%
import requests
from bs4 import BeautifulSoup

req = requests.get("http://www.powenko.com/wordpress/")
print(req.text.encode("utf-8"))
soup=BeautifulSoup(req.text.encode("utf-8"), "html.parser")
print(soup.title)
print(soup.title.string)
print(soup.p)
print(soup.a)
print(soup.find_all("a"))

# %%
import requests
from bs4 import BeautifulSoup

text1="""
<head>
    <title>柯博文老師</title>
</head>
<body>
    <p class="title"><b>The test</b></p>
    <a class="redcolor" href="http://powenko.com/1.html" id="link1">test1</a>
    <a class="bluecolor" href="http://powenko.com/2.html" id="link2">test2</a>
    <a class="redcolor" id="link3" href="http://powenko.com/3.html" id="link3">test3</a>
</body>
"""
soup=BeautifulSoup(text1, "html.parser")
print(soup.title)
print(soup.title.name)
print(soup.title.string)
print(soup.title.parent.name)
print(soup.p)
print(soup.p['class'])
print(soup.a)
print(soup.find_all('a'))
for link in soup.find_all('a'):
	print(link.get('href'))
print(soup.select('a'))
print(soup.select('.redcolor'))   # class="redcolor"
print(soup.select('#link3'))     # id="link3"
for link in soup.select('a'):
	print(link.string)
	
print(soup.select(".bluecolor")[0].get("href"))
print(soup.select(".bluecolor")[0].string)
# %%

import requests
from bs4 import BeautifulSoup

req=requests.get("http://www.powenko.com/wordpress")
soup=BeautifulSoup(req.text.encode('utf-8'), "html.parser")
largefeaturepowenA2=soup.select('.largefeaturepowenA2')
largefeature0=largefeaturepowenA2[0]
for area in largefeature0.select('.area'):	
    # print(area.select('a')[1].text)
    t1=area.select('a')
    print(area.select('a')[1].contents[0])
# %%
from bs4 import BeautifulSoup
import sys
import urllib.request as httplib  # 3.x
import json
#  SSL  處理，  https    SSSSSS 就需要加上以下2行
import ssl
ssl._create_default_https_context = ssl._create_unverified_context    # 因.urlopen發生問題，將ssl憑證排除



#url="https://www.twse.com.tw/exchangeReport/MI_INDEX?response=json&date=20220426&type=24&_=1650961244346"
url="https://www.twse.com.tw/rwd/zh/afterTrading/MI_INDEX?response=json&_=1698561579028"

req = httplib.Request( url, data=None,  # 連線
    headers={'User-Agent':"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36"}
)
reponse = httplib.urlopen(req)               # 開啟連線動作
if reponse.code==200:                        # 當連線正常時
    contents = reponse.read()                  # 讀取網頁內容
    contents = contents.decode("utf-8")        # 轉換編碼為 utf-8
    print(contents)




######### 字串 換成  JSON 的 Dict
data1= json.loads(contents)
print(data1)
print(data1["tables"])
print(data1["tables"][6])
print(data1["tables"][6]["data"])
t2=data1["tables"][6]["data"]
print(t2)
for row in t2:
    print("成交統計:", row[0], "成交金額(元)	:",  row[1], "成交股數(股):",  row[2]," 成交筆數",row[3])
"""
print("代號:",data1["data1"][0][0],"公司名稱:",data1["data1"][0][1],"收盤價:",data1["data1"][0][8])
for row in  data1["data1"]:
    print("代號:", row[0], "公司名稱:",  row[1], "收盤價:",  row[2])
"""
# %%
from selenium import webdriver    # pip3 install selenium
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
import sys

# option = webdriver.ChromeOptions()

driver = webdriver.Chrome()

driver.get('http://www.python.org')

assert "Python" in driver.title
elem = driver.find_element(By.ID, "id-search-field")
elem.clear()
elem.send_keys("Chris")
elem.send_keys(Keys.RETURN)
assert "No results found." not in driver.page_source
# driver.close()
# %%
