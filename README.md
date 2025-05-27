# 🧠📊 Clustering Penyakit di Sumatera Utara dengan Big Data

Sistem ini mengimplementasikan pipeline end-to-end untuk menganalisis dan mengelompokkan wilayah kabupaten/kota di Sumatera Utara berdasarkan pola penyakit menggunakan teknologi Big Data. Arsitektur yang digunakan mengacu pada pendekatan **Medallion Architecture (Bronze → Silver → Gold)** dengan dukungan Spark, Hive, dan alat visualisasi canggih.

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




