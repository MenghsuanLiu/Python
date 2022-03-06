# %%
import sys, random
import numpy as np
import tensorflow as tf
import cv2


bmp = np.zeros(shape = (170, 170), dtype = np.uint8)

for w in range(0, bmp.shape[0]):
    for h in range(0, bmp.shape[1]):
        bmp[w, h] = random.randint(0, 255)

bmp_tensor = tf.constant(bmp)

pad_h = (200 - bmp.shape[0]) // 2   # 除2是因為上下
pad_w = (200 - bmp.shape[1]) // 2   # 除2是因為左右

resize_bmp_tensor = tf.pad(bmp_tensor, paddings = [[pad_h, pad_h], [pad_w, pad_w]], mode = "CONSTANT", constant_values = 255)   # 255是白色

cv2.imshow("newbmp view", resize_bmp_tensor.numpy())
cv2.waitKey()
cv2.destroyAllWindows()
sys.exit(0)
# %%
import tensorflow as tf
