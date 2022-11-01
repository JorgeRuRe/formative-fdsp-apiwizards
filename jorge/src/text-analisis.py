# Author: Jorge Ruiz Reyes
# Maintainers: JRR
# Fundamentals of SDS - Python (week 2, long assingment)
# ===========================================================


# libraries  ---------------------------------------------------------------
import pandas as pd 
import pyarrow

cols_to_keep = ["CreationDate", "Title", "Tags"]


stack_df = pd.read_feather("notebook/sample.feather")
stack_df.info()


stack_df = (stack_df
 [cols_to_keep]
 .explode("Tags")
 )


stack_df.reset_index().to_feather("jorge/output/text_data.feather")
stack_df.to_csv("jorge/output/text_data.csv")

