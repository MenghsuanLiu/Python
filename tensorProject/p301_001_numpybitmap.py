# %%
import numpy as np

if __name__ == "__main__":
    tmp_array = np.ndarray(shape = (600, 600), dtype = int)
    print(tmp_array)
    print("占用記憶體空間:",tmp_array.nbytes)
    print("每個項目佔用多少記憶體空間:",tmp_array.nbytes // (tmp_array.shape[0] * tmp_array.shape[1]))
# %%
    import numpy as np
    matrix_tmp = [[1, 3, 5], [2, 4, 6],[7, 8, 9]]
    array_tmp = np.array(matrix_tmp, dtype = np.uint64)
    my_partial = array_tmp[0:array_tmp.shape[0]:2, 0:array_tmp.shape[0]:2]


    print(matrix_tmp)
    print(array_tmp)
    print(array_tmp.shape)
    print(my_partial)
    print(my_partial.tolist())
# %%
    import numpy as np
    t = np.random.rand(2, 3, 4, 5)

    for i in range(0, t.shape[0]):
        for j in range(0, t.shape[1]):
            t[i, j] *= 100
    t.astype(int)
# %%
    import numpy as np
    tmp_bitmap = np.zeros(shape = (600, 600), dtype = int)
    tmp_bitmap = np.ones(shape = (600, 600), dtype = int)

    print(tmp_bitmap)
# %%
    import numpy as np
    import random
    import cv2
    
    tmp_array = np.ndarray(shape = (600, 600), dtype = np.uint8)

    for w in range(0, tmp_array.shape[0]):
        for h in range(0, tmp_array.shape[1]):
            tmp_array[w, h] = random.randint(0, 255)

    tmp_array_T = tmp_array.transpose()

    print(tmp_array)
    print(tmp_array_T)
    cv2.imshow("tmpview", tmp_array)
    cv2.waitKey(0)
    cv2.destroyAllWindows()
    # print("占用記憶體空間:",tmp_array.nbytes)
    # print("每個項目佔用多少記憶體空間:",tmp_array.nbytes // (tmp_array.shape[0] * tmp_array.shape[1]))
# %%
    import numpy as np

    np.random.rand(600, 600)
# %%
