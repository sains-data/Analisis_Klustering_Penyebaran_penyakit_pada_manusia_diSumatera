# 🧠📊 Clustering Penyakit di Sumatera Utara dengan Big Data

Sistem ini mengimplementasikan pipeline end-to-end untuk menganalisis dan mengelompokkan wilayah kabupaten/kota di Sumatera Utara berdasarkan pola penyakit menggunakan teknologi Big Data. Arsitektur yang digunakan mengacu pada pendekatan **Medallion Architecture (Bronze → Silver → Gold)** dengan dukungan Spark, Hive, dan alat visualisasi canggih.

## 📌 Tujuan Proyek

- Mengelompokkan wilayah berdasarkan pola penyakit menggunakan **KMeans Clustering**
- Menganalisis **dominan penyakit** di tiap cluster
- Menyediakan **dashboard interaktif** berbasis peta untuk membantu pengambilan kebijakan Dinas Kesehatan

---


## 🚀 Fitur Utama

- **Clustering** dengan Spark MLlib (KMeans)
- **Data Lake** berbasis HDFS dengan skema Bronze-Silver-Gold
- **Visualisasi Spasial**: Tableau, Power BI
- **ETL Terjadwal** menggunakan Apache Airflow
- **Integrasi BI Tools** dengan Hive dan Parquet

---

## 🗂 Arsitektur Sistem

## 🔧 Layer Medallion

| Layer  | Path HDFS       | Format    | Fungsi Utama                |
| ------ | --------------- | --------- | --------------------------- |
| Bronze | `/data/bronze/` | CSV, JSON | Penyimpanan mentah          |
| Silver | `/data/silver/` | Parquet   | Data bersih & terstruktur   |
| Gold   | `/data/gold/`   | Parquet   | Hasil analitik & clustering |

## Struktur proyek
sumut_clustering_pipeline/
├── dags/
│   └── cluster_penyakit_sumut.py
├── scripts/
│   ├── ingest.py
│   ├── etl_cleaning.py
│   ├── clustering_kmeans.py
│   └── export_to_parquet.py
├── configs/
│   └── airflow.cfg
└── data/
    └── bronze/penyakit_sumut.csv
## ⚙️ Teknologi yang Digunakan

### 📊 Machine Learning & ETL
- Apache Spark (MLlib: KMeans)

### 🗃️ Penyimpanan & Query
- HDFS (Data Lake)


### 🗕️ Orkestrasi
- Apache Airflow


### 📊 Visualisasi
- Tableau / Power BI
- Kepler.gl (paling ringan untuk spasial)


## 🧪 ETL & Clustering

### 🔹 Ingest Data (Bronze Layer)

```python
df_raw = spark.read.csv("hdfs://data/bronze/penyakit_sumut.csv", header=True, inferSchema=True)
df_raw.write.mode("overwrite").parquet("hdfs://data/silver/penyakit_cleaned")
```

### 🔸 Cleaning & Transformasi (Silver Layer)

```python
df_clean = df_raw.dropna()
df_pivot = df_clean.groupBy("Kabupaten_Kota").pivot("Jenis_Penyakit").sum("Jumlah_Kasus")
df_pivot = df_pivot.fillna(0)
df_pivot.write.mode("overwrite").parquet("hdfs://data/silver/penyakit_vector")
```

### 🟡 Clustering KMeans (Gold Layer)

```python
from pyspark.ml.clustering import KMeans
from pyspark.ml.feature import VectorAssembler

assembler = VectorAssembler(inputCols=df_pivot.columns[1:], outputCol="features")
df_vector = assembler.transform(df_pivot)

kmeans = KMeans(k=4, seed=42)
model = kmeans.fit(df_vector)
result = model.transform(df_vector)
result.write.mode("overwrite").parquet("hdfs://data/gold/clustering_result")
```

---

## 📊 Integrasi BI Tools

| Tool         | Integrasi                   | Cocok Untuk              |
|--------------|-----------------------------|--------------------------|
| Superset ✅   | Query ke Hive               | Ringan & open-source     |
| Tableau      | Import Parquet/CSV          | Visualisasi peta interaktif |
| Power BI     | ODBC ke Hive atau CSV lokal | User Windows friendly    |
| Kepler.gl    | Upload CSV + koordinat      | Peta cepat tanpa install |

### 🔗 Contoh Integrasi Superset (Hive)

```sql
SELECT * FROM penyakit_cluster;
```

---

## 🐳 Deployment (Docker)

### Struktur Folder

```
sumut_clustering_pipeline/
├── dags/
│   └── cluster_penyakit_sumut.py
├── scripts/
│   ├── ingest.py
│   ├── etl_cleaning.py
│   ├── clustering_kmeans.py
│   └── export_to_parquet.py
├── configs/
│   └── airflow.cfg
└── data/
    └── bronze/penyakit_sumut.csv
```

### Docker Compose (Ringkasan Layanan)

- **Hadoop Cluster** (HDFS, YARN)
- **Apache Hive** + Metastore (MySQL/PostgreSQL)
- **Apache Spark**
- **Apache Superset**
- **Airflow**

---

## 🔎 Testing

| Jenis Uji         | Tujuan                                           | Status |
|-------------------|--------------------------------------------------|--------|
| Unit Test         | Test script Spark ETL                            | ✅     |
| Integration Test  | Ingest → Spark → Hive                            | ✅     |
| Data Quality Test | Cek null, format, duplikat                       | ✅     |
| End-to-End Test   | Dari CSV hingga dashboard Superset               | ✅     |

---

## 📊 Analytics

- **Segmentasi Wilayah**: Spark MLlib - KMeans
- **Dominasi Penyakit**: PCA, Feature Importance

```python
# Contoh evaluasi klaster
from pyspark.ml.evaluation import ClusteringEvaluator

evaluator = ClusteringEvaluator()
silhouette = evaluator.evaluate(result)
print(f"Silhouette Score: {silhouette}")
```

---

## 📂 Dataset

| Kolom           | Tipe     | Deskripsi                               |
|------------------|----------|------------------------------------------|
| kabupaten_kota   | String   | Wilayah administratif                   |
| jenis_penyakit   | String   | Jenis penyakit (DBD, ISPA, HIV, dll.)   |
| jumlah_kasus     | Integer  | Jumlah kasus per penyakit               |
| tahun            | Integer  | Tahun pengamatan (2022)                 |

---

## 🌍 Visualisasi Spasial (Kepler.gl)

- Export hasil clustering ke CSV:
```python
result.write.mode("overwrite").csv("data/export/cluster_result.csv", header=True)
```
- Buka di: https://kepler.gl
- Format:
```csv
kabupaten_kota,cluster_id,latitude,longitude
Medan,2,3.5897,98.6722
...
```

---

## 📆 Repositori Portofolio

🔗 https://github.com/sains-data/TugasBesarABD

---

## 👥 Kontributor
1. Jihan Putri Yani (121450161)
2. Rendra Eka Prayoga (122450112)
3. Rahma Neliyana (122450036)
4. Uliano Wilyam Purba (122450098)
---

## 📜 Lisensi

MIT License – bebas digunakan dan dikembangkan untuk kepentingan edukatif dan instansi pemerintahan.

---



