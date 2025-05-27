from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("IngestData").getOrCreate()

# Baca file dari path relatif dalam container
df = spark.read.csv("C:\PROYEK ABD\Jumlah Kasus Penyakit Menurut Kabupaten_Kota dan Jenis Penyakit di Provinsi Sumatera Utara, 2020 (1).csv"docker cp scripts/ingest.py spark-master:/opt/workspace/scripts/
docker cp data/bronze spark-master:/opt/workspace/data/
, header=True, inferSchema=True)

# Simpan ke HDFS dalam format Parquet (Silver Layer)
df.write.mode("overwrite").parquet("hdfs://namenode:9000/data/silver/penyakit_cleaned")

