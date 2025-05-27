#!/bin/bash

# Pipeline ETL untuk Clustering Penyakit Sumut
# Tim Data Engineering - Institut Teknologi Sumatera

set -e  # Exit jika ada error

echo "=========================================="
echo "MEMULAI PIPELINE CLUSTERING PENYAKIT SUMUT"
echo "=========================================="

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function untuk logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Membuat direktori yang diperlukan
log "Membuat direktori output..."
mkdir -p data/output/plots
mkdir -p data/parquet
mkdir -p data/logs

# Step 1: Start Docker containers (jika belum berjalan)
log "Checking Docker services..."
if ! docker compose ps | grep -q "Up"; then
    log "Starting Docker services..."
    ./start_docker.sh
else
    log "Docker services sudah berjalan"
fi

# Step 2: Jalankan ETL Pipeline
log "=========================================="
log "MENJALANKAN ETL PIPELINE"
log "=========================================="

# Step 2a: Data Ingestion
log "Step 1: Data Ingestion..."
./scripts/ingest_data.sh

if [ $? -eq 0 ]; then
    log "✓ Data Ingestion berhasil"
else
    error "✗ Data Ingestion gagal"
    exit 1
fi

# Step 2b: ETL Transform
log "Step 2: ETL Transform..."
./scripts/etl_transform.sh

if [ $? -eq 0 ]; then
    log "✓ ETL Transform berhasil"
else
    error "✗ ETL Transform gagal"
    exit 1
fi

# Step 2c: Clustering
log "Step 3: Clustering dengan KMeans..."
./scripts/run_clustering.sh

if [ $? -eq 0 ]; then
    log "✓ Clustering berhasil"
else
    error "✗ Clustering gagal"
    exit 1
fi

# Step 2d: Export Results
log "Step 4: Export ke PostgreSQL..."
./scripts/export_results.sh

if [ $? -eq 0 ]; then
    log "✓ Export ke PostgreSQL berhasil"
else
    error "✗ Export ke PostgreSQL gagal"
    exit 1
fi

# Step 3: Verifikasi hasil
log "=========================================="
log "VERIFIKASI HASIL"
log "=========================================="

log "Checking data di PostgreSQL..."
docker exec postgres_penyakit psql -U postgres -d penyakit_db -c "
SELECT 
    'kabupaten' as table_name, 
    COUNT(*) as record_count 
FROM kabupaten
UNION ALL
SELECT 
    'penyakit' as table_name, 
    COUNT(*) as record_count 
FROM penyakit
UNION ALL
SELECT 
    'kasus_penyakit' as table_name, 
    COUNT(*) as record_count 
FROM kasus_penyakit
UNION ALL
SELECT 
    'hasil_klaster' as table_name, 
    COUNT(*) as record_count 
FROM hasil_klaster;
"

log "Preview hasil clustering:"
docker exec postgres_penyakit psql -U postgres -d penyakit_db -c "
SELECT 
    kabupaten, 
    cluster_id, 
    COUNT(*) as jumlah 
FROM hasil_klaster 
GROUP BY cluster_id, kabupaten 
ORDER BY cluster_id, kabupaten 
LIMIT 20;
"

# Step 4: Informasi akses
log "=========================================="
log "PIPELINE SELESAI!"
log "=========================================="

echo ""
log "Akses ke services:"
log "- Spark Master UI: http://localhost:8080"
log "- PostgreSQL: localhost:5432 (user: postgres, pass: password123, db: penyakit_db)"
echo ""
log "Untuk menghentikan semua services:"
log "docker compose down"
echo ""
log "Untuk melihat logs:"
log "docker compose logs [service_name]"
echo ""

# Optional: Generate summary report
log "Membuat summary report..."
docker exec postgres_penyakit psql -U postgres -d penyakit_db -c "
copy (
    SELECT 
        k.nama_kabupaten,
        hk.cluster_id,
        COUNT(kp.id_kasus) as total_kasus,
        SUM(kp.jumlah_kasus) as total_jumlah_kasus
    FROM hasil_klaster hk
    JOIN kabupaten k ON k.nama_kabupaten = hk.kabupaten
    LEFT JOIN kasus_penyakit kp ON kp.id_kabupaten = k.id_kabupaten
    GROUP BY k.nama_kabupaten, hk.cluster_id
    ORDER BY hk.cluster_id, total_jumlah_kasus DESC
) TO '/data/output/clustering_summary.csv' WITH CSV HEADER;
"

log "Summary report tersimpan di: data/output/clustering_summary.csv"

echo ""
echo "=========================================="
echo -e "${GREEN}PIPELINE CLUSTERING PENYAKIT SUMUT SELESAI!${NC}"
echo "=========================================="
