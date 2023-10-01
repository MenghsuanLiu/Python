# %%
import cv2
import numpy as np
import matplotlib.pyplot as plt


#1
#讀取圖片
image = cv2.imread("20191026_114737.jpg")
image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

# 2.對HSV的Color space 再去做Historgam equalization
image_hsv = cv2.cvtColor(image_rgb, cv2.COLOR_BGR2HSV)
image_hsv[:,:,2] = cv2.equalizeHist(image_hsv[:,:,2])
image_hsv_equalize = cv2.cvtColor(image_hsv, cv2.COLOR_HSV2RGB)

# 3.對RGB Color Space進行Historgam equalization
image_r, image_g, image_b = cv2.split(image_rgb)
image_r_equalize = cv2.equalizeHist(image_r)
image_g_equalize = cv2.equalizeHist(image_g)
image_b_equalize = cv2.equalizeHist(image_b)
image_rgb_equalize = cv2.merge((image_r_equalize, image_r_equalize, image_b_equalize))

# 串聯三張圖
image_concatenated = np.hstack((image_rgb, image_hsv_equalize, image_rgb_equalize))


# 顥示串連後的結果
plt.imshow(image_concatenated)
plt.axis("off")
plt.show()
# %%
