# %%
import tensorflow as tf
import sys
from Library.p307_001_mnistData import default_dim, dataProvisioning



if __name__ == "__main__":
    # model
    modelS = tf.keras.Sequential()
    # inputLayer
    iLayer = tf.keras.layers.Input(shape = (default_dim * default_dim, ), dtype = tf.float64)
    ## iLayer = tf.keras.layers.Input(tensor = X_train)

    # hiddenLayer
    hLayer = tf.keras.layers.Dense(units = 128, activation = tf.nn.relu)

    # outputLayer
    oLayer = tf.keras.layers.Dense(units = 10, activation = tf.nn.softmax)

    # dropoutLayer
    dLayer = tf.keras.layers.Dropout(rate = 0.2)


    # Create Model 
    modelS.add(iLayer)
    modelS.add(hLayer)
    modelS.add(dLayer)
    modelS.add(oLayer)

    default_learningrate = 0.001
    default_epoch = 5
    datapath = "./Data/mnist_dataset"

    opt = tf.keras.optimizers.Adam(learning_rate = default_learningrate)

    modelS.compile(optimizer = opt, loss = "sparse_categorical_crossentropy", metrics = ["mean_squared_error","sparse_categorical_accuracy"])

    X_train, y_train, X_test, y_test = dataProvisioning(datapath)

    modelS.fit(X_train, y_train, epochs = default_epoch, batch_size = 32)

    eval = modelS.evaluate(X_test, y_test, verbose = 2)
    print("The Metrics name ++> ", modelS.metrics_names)
    print("The Metrics value --> ", eval)

    modelS.weights
    modelS.save("./Model/handwriting_models.yyy")
# %%
