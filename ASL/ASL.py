# %%
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Flatten, Conv2D, MaxPooling2D, Activation, Dropout
from tensorflow.keras.losses import sparse_categorical_crossentropy
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import tensorflow_hub as hub
import numpy as np
import matplotlib.pyplot as plt
# %%
# load_model = tf.keras.models.load_model("./Python/ASL/h5/asl_model.h5", custom_objects={"KerasLayer":hub.KerasLayer})
load_model = tf.keras.models.load_model("./h5/asl_model.h5", custom_objects={"KerasLayer":hub.KerasLayer})
print(load_model.summary())


# %%
img_size = 224
batch_size = 32
test_path = "./asl_alphabet_test/asl_alphabet_test"
augment_test_data = ImageDataGenerator(rescale=1./255)
# test_dataset = augment_test_data.flow_from_directory(test_path,  classes=['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K',
#                                                                'L', 'M', 'N',
#                                                                'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y',
#                                                                'Z', 'space', 'del', 'nothing'],
#                                                                target_size=(img_size, img_size), batch_size=batch_size)
test_dataset = augment_test_data.flow_from_directory(test_path, target_size=(img_size, img_size), batch_size=batch_size)
# %%
print("\n Model Evaluation: ")
load_model.evaluate(test_dataset)
# %%
for data in test_dataset:
    predictions = load_model(data)
    print(predictions)
# %%
