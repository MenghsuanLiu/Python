# %%
import cv2
import numpy as np
import matplotlib.pyplot as plt


#1
#讀取圖片
image = cv2.imread("20191026_114737.jpg")
image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

# flip
flipped_image = cv2.flip(image_rgb, 1) # 水平翻轉

# Scale(cv.resize)
height, width = image_rgb.shape[:2]
scale_image = cv2.resize(image_rgb, (int(height * 0.5), int(width * 0.5)))

# Translate(平移矩陣,並使用cv2.warpAffine)
M = np.float32([[1,0,50],
                [0,1,50]])
translates_image = cv2.warpAffine(image_rgb, M, (width, height))

# 左上為原圖,右上Flip,左下Scale,右下Translate
plt.subplot(2,2,1)
plt.imshow(image_rgb)
plt.title("Original Image")

plt.subplot(2,2,2)
plt.imshow(flipped_image)
plt.title("Flip Image")

plt.subplot(2,2,3)
plt.imshow(scale_image)
plt.title("Scale Image")

plt.subplot(2,2,4)
plt.imshow(translates_image)
plt.title("Translate Image")



plt.tight_layout()
plt.axis("off")
plt.show()
# %%
