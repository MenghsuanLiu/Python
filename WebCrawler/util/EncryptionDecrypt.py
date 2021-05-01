# 加密
def enctry(s):
    k = "djq%5cu#-jeq15abg$z9_i#_w=$o88m!*alpbedlbat8cr74sd"
    encry_str = ""
    for i,j in zip(s,k):
        # i為字元，j為祕鑰字元
        temp = str(ord(i)+ord(j))+"_" # 加密字元 = 字元的Unicode碼 + 祕鑰的Unicode碼
        encry_str = encry_str + temp
    return encry_str

# 解密
def dectry(p):
    k = "djq%5cu#-jeq15abg$z9_i#_w=$o88m!*alpbedlbat8cr74sd"
    dec_str = ""
    for i,j in zip(p.split("_")[:-1],k):
        # i 為加密字元，j為祕鑰字元
        temp = chr(int(i) - ord(j)) # 解密字元 = (加密Unicode碼字元 - 祕鑰字元的Unicode碼)的單位元組字元
        dec_str = dec_str+temp
    return dec_str


# data = "sap##1405"
# print("原始資料為：",data)
# enc_str = enctry(data)
# print("加密資料為：",enc_str)
# dec_str = dectry(enc_str)
# print("解密資料為：",dec_str)