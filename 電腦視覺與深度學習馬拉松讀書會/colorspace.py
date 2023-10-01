# %%
import cv2
import matplotlib.pyplot as plt

#1
#讀取圖片
image = cv2.imread("20191026_114737.jpg")

#2. 將圖片從BGR轉換成RGB
img_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB) #使用cvtCOLOR函數來將默認BGR轉成RGB

#3. 將圖片從RGB轉換LAB
img_lab = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2LAB) #使用cvtCOLOR函數來將RGB轉成LAB

#4. 將圖片從RGB轉換HSV

img_hsv = cv2.cvtColor(img_rgb, cv2.COLOR_RGB2HSV) #使使用cvtCOLOR函數來將RGB轉成HSV

#5. 顯示原始圖片和轉換後的圖像
plt.figure(figsize = (10,10))

#顯示RGB
plt.subplot(1,3,1)
plt.imshow(img_rgb)
plt.title("RGB Image")

#顯示LAB

# %%
