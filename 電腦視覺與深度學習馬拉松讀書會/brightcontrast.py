# %%
import cv2
import numpy as np
import matplotlib.pyplot as plt


#1
#讀取圖片
image = cv2.imread("20191026_114737.jpg")
image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

# 調整亮度
M = np.ones(image.shape, dtype="uint8") * 75
bright_image = cv2.add(image_rgb, M)

# 調整對比度
# 增加對比,可將每個pixel *上一個大於1的數字
contrast_image = cv2.convertScaleAbs(image, alpha=1.5, beta=0)

# 串連三張圖
image_concatenated = np.hstack((image_rgb, bright_image, contrast_image))


# 顥示串連後的結果
plt.imshow(image_concatenated)
plt.axis("off")
plt.show()
# %%
