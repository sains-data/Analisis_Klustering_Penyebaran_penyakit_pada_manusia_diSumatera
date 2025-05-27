from pyspark.sql import SparkSession
from pyspark.ml.clustering import KMeans
from pyspark.ml.feature import VectorAssembler

spark = SparkSession.builder.appName("KMeansClustering").getOrCreate()

df_pivot = spark.read.parquet("hdfs://namenode:9000/data/silver/penyakit_vector")
feature_cols = df_pivot.columns[1:]  # exclude Kabupaten_Kota

assembler = VectorAssembler(inputCols=feature_cols, outputCol="features")
df_vector = assembler.transform(df_pivot)

kmeans = KMeans(k=4, seed=123)
model = kmeans.fit(df_vector)
result = model.transform(df_vector)

result.write.mode("overwrite").parquet("hdfs://namenode:9000/data/gold/clustering_result")

