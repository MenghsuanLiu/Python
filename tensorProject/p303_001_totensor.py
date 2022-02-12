import pandas as pd
import tensorflow as tf

zillowDF = pd.read_csv("Data/zillow.csv", index_col = 0, header = 0)
zillowDF.columns = [c.strip().replace("\"", "") for c in zillowDF.columns]
print("#### All columns ####\n", zillowDF.columns)
zillowDF.Zip = pd.Categorical(zillowDF.Zip).codes
print("\n#### The translated DataFrame ####\n", zillowDF)
# zillowDF[" \"Zip\""] = pd.Categorical(zillowDF[" \"Zip\""]).codes
inp = tf.constant(zillowDF.values, dtype = tf.uint32)
print("\n#### The translated tf.Tensor ####\n", inp)
inp_center = inp[len(inp) // 2]
print("\n#### The centroid of tf.Tensor (%r) ####\n" % (type(inp_center)), inp_center)
    
print("\n#### The translated multidimensional list ####\n", inp.numpy().tolist())
# type(inp_center)
# inp.numpy().tolist()

# TensorArray

TArray = tf.TensorArray(dtype = tf.uint32, size = 0, dynamic_size = True, clear_after_read = False)
# 把inp放入TArray
TAimport = TArray.unstack(inp)
print("\n#### The size of tensorArray: ", TAimport.size().numpy())

newTS = tf.constant([9999, 5, 7, 0, 2099, 500000], dtype = tf.uint32)
totalTArray = TAimport.write(int(TAimport.size().numpy()), newTS)
print("\n#### The inserted tf.Tensor ####\n", totalTArray.stack())