import tensorflow as tf


@tf.function
def linearCalcuation(a: tf.Variable, x: tf.Tensor, b: tf.Variable) -> tf.Tensor:
    """linearCalculation : Calculate the linear equation y = a * x + b"""
#    print("Eager in linearCalculation:", tf.executing_eagerly())    
    return tf.math.add(tf.math.multiply(a, x), b)

@tf.function
def lossCalculation(x_observation: tf.Tensor, y_observation: tf.Tensor, a: tf.Variable, b: tf.Variable) -> tf.Tensor:
    """lossCalculation : evaluate the loss/err from predict value to observed value."""
#    print("The shape info: ", x_observation.shape, y_observation.shape, a.shape, b.shape)
    y_perdiction = linearCalcuation(a, x_observation, b)
#    print("The predicted y:\n", y_prediction)    
    diff_square = tf.math.square(tf.math.subtract(y_observation, y_perdiction))
#    diff_squared = tf.math.reduce_sum(diff_squared) 
    
#    print("The squared residual values element-wise:\n", diff_squared)
#    print("The squared sum of residuals:\t", diff_squared)
#    print("Eager in lossCalculation:", tf.executing_eagerly())    
    return tf.math.reduce_mean(diff_square)