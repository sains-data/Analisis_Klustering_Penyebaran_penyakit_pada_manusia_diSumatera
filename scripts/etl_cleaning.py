from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("ETLCleaning").getOrCreate()

df_raw = spark.read.parquet("hdfs://namenode:9000/data/silver/penyakit_cleaned")
df_clean = df_raw.dropna().withColumnRenamed("Jumlah Kasus", "jumlah_kasus")
df_pivot = df_clean.groupBy("Kabupaten_Kota").pivot("Jenis_Penyakit").sum("jumlah_kasus").fillna(0)

df_pivot.write.mode("overwrite").parquet("hdfs://namenode:9000/data/silver/penyakit_vector")

