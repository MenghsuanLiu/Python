# %%
import tensorflow as tf
import sys
from Library.p307_001_mnistData import default_dim, dataProvisioning



if __name__ == "__main__":
    default_dim_shape = (default_dim, default_dim, 1)

    # model
    modelS = tf.keras.Sequential()
    # inputLayer
    iLayer = tf.keras.layers.Input(shape = default_dim_shape, dtype = tf.float64)
    ## iLayer = tf.keras.layers.Input(tensor = X_train)

    # convLayer1
    cLayer1 = tf.keras.layers.Conv2D(filters = 32, kernel_size = (3, 3), activation = tf.nn.relu)
    pLayer1 = tf.keras.layers.MaxPooling2D(pool_size = (2, 2))

    # convLayer2
    cLayer2 = tf.keras.layers.Conv2D(filters = 48, kernel_size = (3, 3), activation = tf.nn.relu)
    pLayer2 = tf.keras.layers.MaxPooling2D(pool_size = (2, 2))

    # convDropoutLayer
    convdLayer = tf.keras.layers.Dropout(rate = 0.5) 

    # flattenLayer
    fLayer = tf.keras.layers.Flatten()

    # hiddenLayer
    hLayer = tf.keras.layers.Dense(units = 128, activation = tf.nn.relu)

    # outputLayer
    oLayer = tf.keras.layers.Dense(units = 10, activation = tf.nn.softmax)

    # dropoutLayer
    dLayer = tf.keras.layers.Dropout(rate = 0.2)


    # Create Model 
    modelS.add(iLayer)
    
    modelS.add(cLayer1)
    modelS.add(pLayer1)
    modelS.add(cLayer2)
    modelS.add(pLayer2)
    modelS.add(convdLayer)
    modelS.add(fLayer)

    modelS.add(hLayer)
    modelS.add(dLayer)
    modelS.add(oLayer)

    default_learningrate = 0.001
    default_epoch = 5
    datapath = "./Data/mnist_dataset"

    opt = tf.keras.optimizers.Adam(learning_rate = default_learningrate)

    modelS.compile(optimizer = opt, loss = "sparse_categorical_crossentropy", metrics = ["mean_squared_error","sparse_categorical_accuracy"])

    X_train, y_train, X_test, y_test = dataProvisioning(datapath)

    train_images = tf.reshape(X_train, shape = (X_train.shape[0],) + default_dim_shape)
    test_images = tf.reshape(X_test, shape = (X_test.shape[0],) + default_dim_shape)

    tensorboard_callback = tf.keras.callbacks.TensorBoard(log_dir = "./Log", histogram_freq = 1, update_freq = "batch")
# %%
    modelS.fit(train_images, y_train, epochs = default_epoch, callbacks = [tensorboard_callback] )

    eval = modelS.evaluate(test_images, y_test, verbose = 2)
    print("The Metrics name ++> ", modelS.metrics_names)
    print("The Metrics value --> ", eval)
    modelS.summary()
    print(modelS.weights)

    sys.exit(0)
    # modelS.weights
    # modelS.save("./Model/handwriting_models.yyy")
# %%
