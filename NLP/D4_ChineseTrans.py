# %%
from opencc import OpenCC
text1=u"我去过清华大学和交通大学，打印机、光盘、内存。"
text2=u"我去過清華大學和交通大學，印表機、光碟、記憶體。"

openCC = OpenCC('s2t')   
line = openCC.convert(text1) 
print("      "+text1)
print("s2t  :"+line)
line =openCC.set_conversion('s2twp')
line = openCC.convert(text1)
print("s2twp:"+line)

line =openCC.set_conversion('t2s')
line = openCC.convert(text2) 
print("      "+text2)
print("t2s  :"+line)
line =openCC.set_conversion('tw2sp')
line = openCC.convert(text2)
print("tw2sp:"+line)
# %%
import jieba
text1="我去過清華大學和交通大學。"
test2="小明來到了航研大廈"
seg_list = jieba.cut(text1, cut_all=True, HMM=False)
print("Full Mode: " + "/ ".join(seg_list))


seg_list = jieba.cut(text1, cut_all=False, HMM=True)
print("Default Mode: " + "/ ".join(seg_list))  # 默认模式

print(", ".join(jieba.cut(test2, HMM=True)))
print(", ".join(jieba.cut(test2, HMM=False)))
print(", ".join(jieba.cut(test2)))
print(", ".join(jieba.cut_for_search(test2) ))

# %%
import sys
from os import path
import jieba
import jieba.analyse
d = path.dirname(__file__)
if (sys.version_info > (3, 0)):
	text = open(path.join(d, "./Data/test.txt"), "r", encoding = "utf-8").read()
else:
	text = open(path.join(d, "./Data/test.txt"),'r').read()

text=text.replace('\n', '')
jieba.analyse.set_stop_words("./Data/stop_words.txt")
print('/'.join(jieba.cut(text)))
print("====================")
jieba.load_userdict(path.join(d, "./Data/userdict.txt"))
dic={}
for ele in jieba.cut(text):
    if ele not in dic:
        dic[ele]=1
    else:
        dic[ele]=dic[ele]+1

for w in sorted(dic, key=dic.get, reverse=True):
    print("%s  %i " % (w, dic[w]))
# %%
import sys
import jieba
import jieba.analyse
import urllib.request as httplib

try:
    url = "https://tw.news.yahoo.com/"
    req = httplib.Request(url)
    reponse = httplib.urlopen(req)
    if reponse.code==200:
        contents=reponse.read().decode(reponse.headers.get_content_charset())
except:
    print("error")

#print(",".join(jieba.analyse.extract_tags(contents, topK=1000)))
jieba.analyse.set_stop_words("./Data/stop_words.txt")
#print(",".join(jieba.analyse.extract_tags(contents, topK=1000)))

dic = {}
keywords = jieba.analyse.extract_tags(contents, topK = 40, withWeight=True, allowPOS=())
#keywords = jieba.analyse.extract_tags(contents, topK=100, withWeight=True, allowPOS=('ns', 'n', 'vn', 'v'))
for item in keywords:
    print("  %s   TF=%f , IDF=%f  topK=%f" % (item[0], item[1], len(keywords)*item[1], item[1]*len(keywords)*item[1]))      # 分別為關鍵詞和相應的權重
        

print("="*40)
words =jieba.posseg.cut(contents)
for word, flag in words:
    if flag=="ns" or flag=="n" or flag=='vn' or flag=='n':
        if word not in dic:
            dic[word] = 1
        else:
            dic[word] = dic[word] + 1
for w in sorted(dic, key=dic.get, reverse=True):
    if dic[w]>1:
        print("%s  %i " % (w, dic[w]))

# %%
