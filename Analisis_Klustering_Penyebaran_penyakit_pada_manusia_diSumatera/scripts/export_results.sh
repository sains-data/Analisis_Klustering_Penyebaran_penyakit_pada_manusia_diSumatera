#!/bin/bash

# Script untuk menjalankan Export Results
# Tim Data Engineering - Institut Teknologi Sumatera

set -e

echo "📥 MENJALANKAN EXPORT RESULTS"
echo "==========================="

# Cek apakah Docker berjalan
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker tidak berjalan. Silakan jalankan Docker terlebih dahulu."
    exit 1
fi

# Cek apakah container spark_master ada
if ! docker ps -a | grep -q spark_master; then
    echo "❌ Container spark_master tidak ditemukan. Silakan jalankan ./start_docker.sh terlebih dahulu."
    exit 1
fi

# Cek apakah container postgres_penyakit ada
if ! docker ps -a | grep -q postgres_penyakit; then
    echo "❌ Container postgres_penyakit tidak ditemukan. Silakan jalankan ./start_docker.sh terlebih dahulu."
    exit 1
fi

# Cek apakah data inputan telah tersedia
if ! docker exec spark_master ls -la /data/parquet/clustering_results.parquet > /dev/null 2>&1; then
    echo "❌ Data clustering belum tersedia. Silakan jalankan ./scripts/run_clustering.sh terlebih dahulu."
    exit 1
fi

# Jalankan export results script
echo "📝 Menjalankan script export_results.py..."
docker exec spark_master /spark/bin/spark-submit \
    --master spark://spark-master:7077 \
    --driver-memory 1g \
    --executor-memory 1g \
    --packages org.postgresql:postgresql:42.2.18 \
    /app/export_results.py

# Tampilkan hasil output
echo ""
echo "📊 Hasil Export:"
docker exec spark_master ls -lah /data/output/

# Tampilkan PostgreSQL data
echo ""
echo "📊 Data di PostgreSQL:"
docker exec postgres_penyakit psql -U postgres -d penyakit_db -c "
SELECT 
    table_name, 
    (xpath('/row/cnt/text()', query_to_xml('SELECT count(*) as cnt FROM '||table_name, false, true, '')))[1]::text AS count
FROM 
    information_schema.tables
WHERE 
    table_schema = 'public' AND 
    table_name IN ('kabupaten', 'penyakit', 'hasil_klaster', 'kasus_penyakit')
ORDER BY 
    table_name;
"

echo ""
echo "📋 Sample data cluster dari PostgreSQL:"
docker exec postgres_penyakit psql -U postgres -d penyakit_db -c "
SELECT k.nama_kabupaten, h.cluster_id 
FROM hasil_klaster h
JOIN kabupaten k ON h.kabupaten = k.nama_kabupaten
ORDER BY h.cluster_id, k.nama_kabupaten
LIMIT 10;
"

echo ""
echo "✅ EXPORT RESULTS SELESAI"
