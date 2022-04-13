# %%
import tensorflow as tf
import sys
import random
from mnist import MNIST
from Library.p307_001_mnistData import imageRendering


if __name__ == "__main__":
    imgID = random.randint(0, 10001)
    testdata_path = "./Data/mnist_dataset"
    model_path = "./Model/handwriting_models.yyy"

    testdata = MNIST(testdata_path, return_type = "numpy")

    test_imgs, test_labs = testdata.load_testing()

    modelS = tf.keras.models.load_model(model_path)

    test_img = tf.constant([test_imgs[imgID].tolist()], dtype = tf.float64)

    testResult = modelS.predict(x = test_img)

    print(testResult)
    print(MNIST.display(test_imgs[imgID].tolist()))

    preditValue = tf.argmax(testResult[0])

    print(f"PreditValue is: {preditValue}, with probability: {testResult[0][preditValue]}")

    imageRendering(test_imgs[imgID], test_labs[imgID])
    sys.exit(0)
# %%
