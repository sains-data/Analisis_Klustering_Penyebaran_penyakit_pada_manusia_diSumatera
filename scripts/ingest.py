from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("IngestData").getOrCreate()

# Baca CSV
df = spark.read.option("header", True).option("inferSchema", True).csv("file:///scripts/data/bronze/penyakit_sumut.csv")

# Cetak semua nama kolom untuk tahu urutannya
print("Kolom asli:", df.columns)

# Rename semua kolom agar bersih
df = df.toDF(
    "Kabupaten_Kota",
    "Jenis_Penyakit",
    "Jumlah Kasus",
    "Tahun"  # tambahkan sesuai jumlah kolom sebenarnya
)

df.write.mode("overwrite").parquet("hdfs://namenode:8020/data/silver/penyakit_cleaned")
