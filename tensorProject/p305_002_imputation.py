# %%
import pandas as pd
import statistics

if __name__ == "__main__":
    targetEngGrade = 85
    filepath = ".\Data\student_grades.csv"

    sDF = pd.read_csv(filepath, header = 0)
    print(sDF)

    eng_list = sDF["english"].to_list()
    eng_list.remove(targetEngGrade)
    print("## Imputation of English grade is", statistics.mean(eng_list), "##")
# %%

import tensorflow as tf
y_true = tf.constant([[1,0],[1,0]], dtype = tf.float64)
y_pred = tf.constant([[1,0],[0,1]], dtype = tf.float64)
print(tf.keras.metrics.binary_crossentropy(y_true, y_pred))
# %%
