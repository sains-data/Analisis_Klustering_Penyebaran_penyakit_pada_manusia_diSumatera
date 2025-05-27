# 🏥 Clustering Penyakit Sumatera Utara

Pipeline big data untuk clustering kasus penyakit di Sumatera Utara menggunakan Apache Spark dan PostgreSQL. Proyek ini mengimplementasikan end-to-end batch processing pipeline untuk analisis dan visualisasi pola penyakit di kabupaten/kota di Sumatera Utara.

## 🎯 Tujuan Proyek

Mengembangkan sistem batch processing pipeline untuk:
- 📊 Mengelompokkan kabupaten/kota berdasarkan kemiripan pola penyakit dengan KMeans
- 🎯 Mengidentifikasi wilayah dengan beban penyakit tinggi
- 📈 Memberikan insights untuk alokasi sumber daya kesehatan
- 🗺️ Menyediakan data untuk visualisasi di Tableau

## 🏗️ Arsitektur Sistem

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Source   │───▶│  Apache Spark   │───▶│   PostgreSQL    │
│ Penyakit_Sumut  │    │  ETL Pipeline   │    │  Data Warehouse │
│      .csv       │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Spark MLlib   │    │   Visualization │
                       │ KMeans Clustering│    │ Jupyter/Tableau │
                       └─────────────────┘    └─────────────────┘
```

## 📊 Dataset

**Sumber**: Dinas Kesehatan Sumatera Utara (2024)
**Coverage**: 34 Kabupaten/Kota di Sumatera Utara

### Jenis Penyakit yang Dianalisis:
- 🦠 AIDS (Kasus Baru & Kumulatif)
- 🔴 DBD (Demam Berdarah Dengue)
- 💧 Diare
- 🫁 TB Paru (Tuberkulosis)
- 👶 Pneumonia Balita
- 🤒 Campak (Suspek)
- 🦟 Malaria (Suspek)
- 🤲 Kusta
- 🧬 HIV (Kasus Baru & Kumulatif)
- 💉 Tetanus

## 🚀 Quick Start

### Prerequisites
- Docker dan Docker Compose
- Minimum 8GB RAM
- 10GB free disk space

### 1. Clone & Setup
```bash
git clone <repository>
cd ABD
```

### 2. Siapkan Data
Letakkan file `Penyakit_Sumut.csv` di folder `data/`:
```
data/
└── Penyakit_Sumut.csv
```

### 3. Jalankan Pipeline
```bash
# Start semua services
docker-compose up -d

# Tunggu services ready, lalu jalankan pipeline
docker-compose exec spark-master bash /scripts/run_pipeline.sh
```

### 4. Akses Results
- 📓 **Jupyter Notebook**: http://localhost:8888 (token: `penyakit123`)
- 🗄️ **pgAdmin**: http://localhost:5050 (admin@admin.com / admin123)
- 📈 **Spark UI**: http://localhost:8080

## 📂 Struktur Proyek

```
project_root/
├── 🐳 docker-compose.yml          # Orchestration services
├── 📊 data/
│   ├── Penyakit_Sumut.csv         # Source data
│   ├── output/                    # Hasil clustering & visualisasi
│   └── parquet/                   # Intermediate data storage
├── 🔧 scripts/
│   ├── ingest_data.sh             # Data ingestion
│   ├── etl_transform.sh           # Data transformation
│   ├── run_clustering.sh          # ML clustering
│   ├── export_results.sh          # Export untuk visualisasi
│   └── run_pipeline.sh            # Master pipeline script
├── 💻 src/
│   ├── ingest_data.py             # PySpark data ingestion
│   ├── etl_transform.py           # PySpark transformations
│   ├── run_clustering.py          # Spark MLlib clustering
│   └── export_results.py          # Results export
├── 📓 notebooks/
│   └── exploratory_analysis.ipynb # Jupyter analysis
├── 🗄️ sql/
│   └── schema_postgres.sql        # Database schema
└── 📖 README.md
```

## 🔄 Pipeline Stages

### Stage 1: Data Ingestion 📥
- Membaca CSV menggunakan PySpark
- Validasi dan cleaning data
- Insert data kabupaten ke PostgreSQL
- Save ke Parquet format

### Stage 2: ETL Transform 🔄
- Handle missing values
- Data normalization (opsional)
- Save processed data ke PostgreSQL
- Prepare features untuk clustering

### Stage 3: Clustering Analysis 🧠
- Feature engineering dengan VectorAssembler
- Standardization dengan StandardScaler
- KMeans clustering (K=4)
- Model evaluation dengan Silhouette Score
- Save results ke PostgreSQL

### Stage 4: Export Results 📤
- Generate summary statistics
- Export ke CSV untuk Tableau
- Create comprehensive reports
- Generate basic visualizations

## 🎯 Hasil Clustering

### Cluster Characteristics:
- **Cluster 0**: Wilayah dengan beban penyakit rendah
- **Cluster 1**: Wilayah dengan fokus penyakit menular
- **Cluster 2**: Wilayah dengan beban penyakit sedang
- **Cluster 3**: Wilayah dengan beban penyakit tinggi

### Output Files:
```
data/output/
├── 📊 tableau_export.csv              # Ready untuk Tableau
├── 📈 cluster_summary_stats.csv       # Statistik per cluster
├── 📋 clustering_summary_report.txt   # Laporan komprehensif
├── 💾 clustering_results_detailed.csv # Detail hasil clustering
└── 📊 analysis_summary.json           # Summary untuk API
```

## 📊 Visualisasi

### Jupyter Notebook
- Interactive analysis dengan Plotly
- Statistical summaries
- Cluster characteristics analysis
- Heatmaps dan scatter plots

### Tableau Dashboard
Gunakan `tableau_export.csv` untuk membuat:
- 🗺️ Choropleth maps wilayah clusters
- 📊 Bar charts disease burden
- 📈 Time series analysis (jika ada data temporal)
- 🎯 Interactive filters per penyakit

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Orchestration** | Docker Compose | Service management |
| **Big Data Processing** | Apache Spark 3.4 | ETL & ML pipeline |
| **Machine Learning** | Spark MLlib | KMeans clustering |
| **Data Warehouse** | PostgreSQL 15 | Structured data storage |
| **Analytics** | Jupyter Lab | Interactive analysis |
| **Visualization** | Tableau/Plotly | Dashboard & charts |
| **Admin** | pgAdmin 4 | Database management |

## 🔧 Configuration

### Environment Variables
```bash
# Database
POSTGRES_HOST=postgres
POSTGRES_DB=penyakit_db
POSTGRES_USER=postgres
POSTGRES_PASSWORD=password123

# Spark
SPARK_MASTER_URL=spark://spark-master:7077

# Jupyter
JUPYTER_TOKEN=penyakit123
```

### Spark Configuration
- Driver Memory: 1GB
- Executor Memory: 1GB
- Total Executor Cores: 2

## 📋 API Reference

### PostgreSQL Tables

#### `hasil_klaster`
```sql
SELECT kabupaten, cluster_id FROM hasil_klaster;
```

#### `data_pivot`
```sql
SELECT kabupaten, dbd, diare, tb_paru, aids_kasus_baru 
FROM data_pivot ORDER BY cluster_id;
```

### Key Metrics
- **Silhouette Score**: Model evaluation metric
- **WSSSE**: Within Set Sum of Squared Errors
- **Cluster Distribution**: Jumlah kabupaten per cluster

## 🧪 Testing & Validation

### Data Quality Checks
- ✅ No missing kabupaten names
- ✅ Numeric values validation
- ✅ Outlier detection
- ✅ Cluster balance check

### Model Validation
- ✅ Silhouette Score > 0.3
- ✅ Reasonable cluster sizes
- ✅ Geographic distribution makes sense

## 🚀 Deployment

### Production Considerations
1. **Scaling**: Increase Spark executors untuk dataset besar
2. **Security**: Ganti default passwords
3. **Monitoring**: Add logging & alerting
4. **Backup**: Regular PostgreSQL backup strategy

### Docker Resources
```yaml
# Minimum requirements
spark-master:
  mem_limit: 2g
spark-worker:
  mem_limit: 2g
postgres:
  mem_limit: 1g
```

## 🐛 Troubleshooting

### Common Issues

**Service tidak start**
```bash
# Check logs
docker-compose logs [service-name]

# Restart services
docker-compose restart
```

**Pipeline gagal**
```bash
# Check individual scripts
docker-compose exec spark-master bash /scripts/ingest_data.sh
```

**Data tidak muncul**
```bash
# Check PostgreSQL connection
docker-compose exec postgres psql -U postgres -d penyakit_db -c "\dt"
```

## 📚 References

- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Spark MLlib Guide](https://spark.apache.org/docs/latest/ml-guide.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 👥 Team

**Data Engineering Team - Institut Teknologi Sumatera**
- 📧 Contact: dataeng@itera.ac.id
- 🌐 Website: https://itera.ac.id

---

**🎯 Untuk memulai analisis clustering penyakit Sumatera Utara, jalankan pipeline dan akses Jupyter Notebook untuk eksplorasi data yang komprehensif!**
