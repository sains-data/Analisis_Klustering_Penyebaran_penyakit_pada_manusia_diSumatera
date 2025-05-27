# Proyek Big Data: Klaster Penyakit di Sumatera Utara
## 1. Pendahuluan
### 1.1 Tujuan Dokumen

Dokumen ini bertujuan untuk merancang dan menjelaskan kebutuhan sistem dalam membangun pipeline analisis Big Data untuk mengelompokkan (klaster) kasus penyakit di Provinsi Sumatera Utara, berbasis arsitektur data warehouse dengan PostgreSQL dan pemrosesan data menggunakan Apache Spark.

### 1.2 Lingkup Sistem

Sistem ini akan melakukan proses ETL batch terhadap data tahunan penyakit dari file CSV, menyimpannya dalam skema relasional PostgreSQL, menjalankan transformasi dan klasterisasi dengan Spark MLlib, serta menghasilkan visualisasi berbasis Tableau dan Jupyter.

---

## 2. Deskripsi Umum

### 2.1 Perspektif Sistem

Sistem berjalan secara lokal atau dalam lingkungan container Docker. PostgreSQL berfungsi sebagai warehouse utama untuk menyimpan data bersih dan hasil analitik. Spark digunakan sebagai mesin ETL dan machine learning, sementara Tableau dan Jupyter digunakan untuk eksplorasi dan visualisasi data.

### 2.2 Fungsi Utama

* Ingest data mentah dari CSV ke PostgreSQL
* Transformasi dan pembersihan data dengan Spark
* Klasterisasi kabupaten/kota berdasarkan kemiripan penyakit
* Visualisasi hasil analisis dan tren penyakit

### 2.3 Karakteristik Pengguna

* **Analis Kesehatan**: Membaca hasil klaster dan menginterpretasi tren penyakit.
* **Data Engineer**: Menjaga pipeline ETL dan konsistensi data.
* **Pembuat Kebijakan**: Menggunakan hasil untuk intervensi kesehatan berbasis wilayah.

---

## 3. Spesifikasi Kebutuhan

### 3.1 Kebutuhan Fungsional

| No | Fitur             | Deskripsi                                                    | Prioritas |
| -- | ----------------- | ------------------------------------------------------------ | --------- |
| 1  | Ingest data       | Mengimpor data dari file CSV ke PostgreSQL                   | Tinggi    |
| 2  | Transformasi data | Membersihkan, menyusun ulang, dan pivot data penyakit        | Tinggi    |
| 3  | Klasterisasi      | Mengelompokkan wilayah berdasarkan jumlah dan jenis penyakit | Tinggi    |
| 4  | Penyimpanan hasil | Menyimpan hasil transformasi dan analitik ke PostgreSQL      | Tinggi    |
| 5  | Visualisasi       | Menyediakan output visual interaktif di Tableau dan Jupyter  | Tinggi    |
| 6  | Automasi          | Menjalankan semua proses ETL dan ML via skrip shell (`.sh`)  | Sedang    |

### 3.2 Kebutuhan Non-Fungsional

| No | Kebutuhan       | Keterangan                                                    | Prioritas |
| -- | --------------- | ------------------------------------------------------------- | --------- |
| 1  | Portabilitas    | Sistem dapat dijalankan di Docker environment                 | Tinggi    |
| 2  | Reproducibility | Pipeline ETL dapat dijalankan berulang dengan hasil konsisten | Tinggi    |
| 3  | Dokumentasi     | Semua script, tabel, dan proses terdokumentasi                | Tinggi    |
| 4  | Keamanan        | Variabel sensitif disimpan dalam `.env`                       | Tinggi    |
| 5  | Skalabilitas    | Dapat ditingkatkan ke Spark cluster (opsional)                | Sedang    |

---

## 4. Desain Sistem

### 4.1 Komponen Utama

* **CSV Input**: Dataset `Penyakit_Sumut.csv` dari Dinas Kesehatan
* **Apache Spark**: Proses ETL dan clustering
* **PostgreSQL**: Data warehouse penyimpanan data bersih dan hasil klaster
* **Jupyter Notebook**: Visualisasi dan eksplorasi manual
* **Tableau**: Visualisasi interaktif dan peta klaster
* **Bash Scripts (.sh)**: Otomatisasi ingestion, transformasi, ML, dan ekspor

### 4.2 Entity Relationship Diagram (ERD)

```
+------------------+
|   kabupaten      |
+------------------+
| id_kabupaten PK  |
| nama_kabupaten   |
+------------------+

+---------------------+
|   penyakit          |
+---------------------+
| id_penyakit PK      |
| nama_penyakit       |
+---------------------+

+-------------------------------+
|   kasus_penyakit              |
+-------------------------------+
| id_kasus PK                   |
| id_kabupaten FK               |
| id_penyakit FK                |
| jumlah_kasus                  |
| tahun                         |
+-------------------------------+
```

### 4.3 Skema Tabel PostgreSQL

```sql
CREATE TABLE kabupaten (
    id_kabupaten SERIAL PRIMARY KEY,
    nama_kabupaten VARCHAR(100)
);

CREATE TABLE penyakit (
    id_penyakit SERIAL PRIMARY KEY,
    nama_penyakit VARCHAR(100)
);

CREATE TABLE kasus_penyakit (
    id_kasus SERIAL PRIMARY KEY,
    id_kabupaten INTEGER REFERENCES kabupaten(id_kabupaten),
    id_penyakit INTEGER REFERENCES penyakit(id_penyakit),
    jumlah_kasus INTEGER,
    tahun INTEGER
);
```

### 4.4 Arsitektur End-to-End

```
                 +----------------+
                 |  Sumber Data   |
                 | (CSV Dinkes)   |
                 +--------+-------+
                          |
                     [ingest_data.sh]
                          |
                          v
                  +-------+--------+
                  | Apache Spark   |
                  | Ingest & Clean |
                  +-------+--------+
                          |
                   [etl_transform.sh]
                          |
                          v
              +-----------+-----------+
              | Spark MLlib (KMeans) |
              +-----------+-----------+
                          |
                  [run_clustering.sh]
                          |
                          v
                 +--------+--------+
                 | PostgreSQL DW   |
                 | (Hasil Klaster) |
                 +--------+--------+
                          |
                  [export_results.sh]
                          |
                +---------+---------+
                |  Visualisasi     |
                |  Tableau, Jupyter|
                +------------------+
```

---

## 5. Pipeline ETL & Analitik

### 5.1 Alur Proses

1. `ingest_data.sh`: Baca CSV dan simpan ke PostgreSQL
2. `etl_transform.sh`: Pembersihan null, pivot data per kabupaten
3. `run_clustering.sh`: Jalankan KMeans clustering dengan Spark MLlib
4. `export_results.sh`: Simpan hasil klaster ke tabel PostgreSQL
5. Visualisasi: Gunakan Tableau dan Jupyter

### 5.2 Teknologi Pendukung

* Format: CSV → Parquet → PostgreSQL (via JDBC)
* Spark Job dijalankan dengan `spark-submit` dari skrip `.sh`
* Password database dikelola dengan `.env` file

### 5.3 Contoh Script Clustering

```python
from pyspark.ml.clustering import KMeans
from pyspark.ml.feature import VectorAssembler

# Data sudah diproses dan dipivot
df = spark.read.parquet("/data/penyakit_pivot.parquet")

assembler = VectorAssembler(inputCols=df.columns[1:], outputCol="features")
df_vector = assembler.transform(df)

kmeans = KMeans(k=4)
model = kmeans.fit(df_vector)
result = model.transform(df_vector)

# Simpan ke PostgreSQL
result.write \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://localhost:5432/penyakit") \
    .option("dbtable", "hasil_klaster") \
    .option("user", "postgres") \
    .option("password", "password") \
    .save()
```

---

## 6. Dokumentasi & Repositori

### 6.1 Repositori

[GitHub - Tugas Besar ABD](https://github.com/sains-data/TugasBesarABD)

### 6.2 Struktur Direktori

```
project/
├── data/
│   └── Penyakit_Sumut.csv
├── scripts/
│   ├── ingest_data.sh
│   ├── etl_transform.sh
│   ├── run_clustering.sh
│   └── export_results.sh
├── notebooks/
│   └── exploratory.ipynb
├── sql/
│   └── schema_postgres.sql
├── docker-compose.yml
├── .env
└── README.md
```

