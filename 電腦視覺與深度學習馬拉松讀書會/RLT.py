# %%
import cv2
import numpy as np
import matplotlib.pyplot as plt


#1
#讀取圖片
image = cv2.imread("20191026_114737.jpg")

# 建一個空白圖像
image = np.zeros((500,500,3), dtype="uint8")

# 畫一個長方型
cv2.rectangle(image, (100,100), (300,200), (0,255,0), -1)

# 繪製一個圓型
cv2.circle(image, (400, 400), 50, (255,0,0), -1)

# 直線
cv2.line(image, (0,0), (500,500), (0,0,255), 5)

# 顯示
plt.imshow(image)
plt.axis("off")
plt.show()