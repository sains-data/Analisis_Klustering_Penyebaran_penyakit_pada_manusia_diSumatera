"""
Export Results Script - Penyakit Sumatera Utara
Fungsi: Export hasil clustering ke PostgreSQL dan format lainnya
"""

import os
import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum as spark_sum, avg, max as spark_max, desc

def create_spark_session():
    """Membuat Spark Session dengan PostgreSQL driver"""
    spark = SparkSession.builder \
        .appName("PenyakitSumut-ExportResults") \
        .config("spark.jars.packages", "org.postgresql:postgresql:42.2.18") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("WARN")
    return spark

def read_clustering_results(spark):
    """Membaca hasil clustering dari Parquet"""
    try:
        parquet_path = "/data/parquet/clustering_results.parquet"
        df = spark.read.parquet(parquet_path)
        print(f"✅ Berhasil membaca hasil clustering dari: {parquet_path}")
        print(f"📊 Total baris: {df.count()}")
        return df
        
    except Exception as e:
        print(f"❌ Error membaca hasil clustering: {e}")
        sys.exit(1)

def read_original_data(spark):
    """Membaca data original untuk join dengan hasil clustering"""
    try:
        parquet_path = "/data/parquet/penyakit_clean.parquet"
        df = spark.read.parquet(parquet_path)
        print(f"✅ Berhasil membaca data original dari: {parquet_path}")
        return df
        
    except Exception as e:
        print(f"❌ Error membaca data original: {e}")
        sys.exit(1)

def populate_postgres_tables(spark, df_results, df_original):
    """Populate tabel PostgreSQL dengan data clustering dan master data"""
    print("\n=== POPULATING POSTGRESQL TABLES ===")
    
    # Database connection properties
    postgres_url = "jdbc:postgresql://postgres:5432/penyakit_db"
    properties = {
        "user": "postgres",
        "password": "password123",
        "driver": "org.postgresql.Driver"
    }
    
    try:
        # 1. Populate tabel kabupaten
        print("📝 Inserting data ke tabel kabupaten...")
        kabupaten_df = df_original.select("kabupaten_kota").distinct() \
            .withColumnRenamed("kabupaten_kota", "nama_kabupaten")
        
        kabupaten_df.write \
            .mode("overwrite") \
            .jdbc(url=postgres_url, table="kabupaten", properties=properties)
        print("✅ Tabel kabupaten berhasil diisi")
        
        # 2. Populate tabel penyakit
        print("📝 Inserting data ke tabel penyakit...")
        penyakit_list = [
            "AIDS Kasus Baru", "AIDS Kasus Kumulatif", "Campak Suspek",
            "DBD", "Diare", "HIV Kasus Baru", "HIV Kasus Kumulatif",
            "Kusta", "Malaria Suspek", "Pneumonia Balita", "TB Paru", "Tetanus"
        ]
        
        penyakit_df = spark.createDataFrame(
            [(i+1, penyakit) for i, penyakit in enumerate(penyakit_list)],
            ["id_penyakit", "nama_penyakit"]
        )
        
        penyakit_df.write \
            .mode("overwrite") \
            .jdbc(url=postgres_url, table="penyakit", properties=properties)
        print("✅ Tabel penyakit berhasil diisi")
        
        # 3. Populate tabel hasil_klaster
        print("📝 Inserting data ke tabel hasil_klaster...")
        
        cluster_df = df_results.select(
            col("kabupaten_kota").alias("kabupaten"),
            col("prediction").alias("cluster_id")
        )
        
        cluster_df.write \
            .mode("overwrite") \
            .jdbc(url=postgres_url, table="hasil_klaster", properties=properties)
        print("✅ Tabel hasil_klaster berhasil diisi")
        
    except Exception as e:
        print(f"❌ Error populating PostgreSQL tables: {e}")

def create_summary_reports(spark, df_results):
    """Membuat laporan summary clustering"""
    print("\n=== CREATING SUMMARY REPORTS ===")
    
    try:
        # 1. Cluster distribution
        cluster_summary = df_results.groupBy("prediction") \
            .count() \
            .orderBy("prediction") \
            .withColumnRenamed("prediction", "cluster_id") \
            .withColumnRenamed("count", "jumlah_kabupaten")
        
        print("📊 Distribusi Cluster:")
        cluster_summary.show()
        
        # 2. Detailed cluster analysis
        print("\n📋 Detail Kabupaten per Cluster:")
        for cluster_id in range(4):  # Assuming 4 clusters
            print(f"\n🏷️  CLUSTER {cluster_id}:")
            cluster_members = df_results.filter(col("prediction") == cluster_id) \
                .select("kabupaten_kota") \
                .orderBy("kabupaten_kota")
            cluster_members.show(truncate=False)
        
        # 3. Export summary to CSV
        summary_path = "/data/output/cluster_summary.csv"
        cluster_summary.coalesce(1).write \
            .mode("overwrite") \
            .option("header", "true") \
            .csv(summary_path)
        print(f"✅ Summary berhasil disimpan ke: {summary_path}")
        
        # 4. Export detailed results to CSV
        detailed_path = "/data/output/detailed_clustering_results.csv"
        df_results.select("kabupaten_kota", "prediction").coalesce(1).write \
            .mode("overwrite") \
            .option("header", "true") \
            .csv(detailed_path)
        print(f"✅ Detailed results berhasil disimpan ke: {detailed_path}")
        
    except Exception as e:
        print(f"❌ Error creating summary reports: {e}")

def verify_postgres_data(spark):
    """Verifikasi data di PostgreSQL"""
    print("\n=== VERIFYING POSTGRESQL DATA ===")
    
    postgres_url = "jdbc:postgresql://postgres:5432/penyakit_db"
    properties = {
        "user": "postgres",
        "password": "password123",
        "driver": "org.postgresql.Driver"
    }
    
    try:
        tables = ["kabupaten", "penyakit", "hasil_klaster"]
        
        for table in tables:
            df = spark.read.jdbc(url=postgres_url, table=table, properties=properties)
            count = df.count()
            print(f"📊 Tabel {table}: {count} records")
        
        # Show sample from hasil_klaster
        print("\n📋 Sample dari tabel hasil_klaster:")
        hasil_klaster = spark.read.jdbc(url=postgres_url, table="hasil_klaster", properties=properties)
        hasil_klaster.show(10, truncate=False)
        
    except Exception as e:
        print(f"❌ Error verifying PostgreSQL data: {e}")

def main():
    """Main function untuk export results"""
    print("📤 MEMULAI EXPORT RESULTS")
    print("=" * 50)
    
    # Create Spark session
    spark = create_spark_session()
    
    try:
        # Read clustering results
        df_results = read_clustering_results(spark)
        
        # Read original data
        df_original = read_original_data(spark)
        
        # Populate PostgreSQL tables
        populate_postgres_tables(spark, df_results, df_original)
        
        # Create summary reports
        create_summary_reports(spark, df_results)
        
        # Verify PostgreSQL data
        verify_postgres_data(spark)
        
        print("\n✅ EXPORT RESULTS SELESAI")
        
    except Exception as e:
        print(f"❌ Error dalam export results: {e}")
        sys.exit(1)
        
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
