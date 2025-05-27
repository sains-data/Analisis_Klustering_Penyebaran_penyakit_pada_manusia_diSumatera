#!/bin/bash

# Script untuk menjalankan ETL Transform
# Tim Data Engineering - Institut Teknologi Sumatera

set -e

echo "🔄 MENJALANKAN ETL TRANSFORM"
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

# Cek apakah data inputan telah tersedia
if ! docker exec spark_master ls -la /data/parquet/penyakit_clean.parquet > /dev/null 2>&1; then
    echo "❌ Data clean belum tersedia. Silakan jalankan ./scripts/ingest_data.sh terlebih dahulu."
    exit 1
fi

# Jalankan ETL transform script
echo "📝 Menjalankan script etl_transform.py..."
docker exec spark_master /spark/bin/spark-submit \
    --master spark://spark-master:7077 \
    --driver-memory 1g \
    --executor-memory 1g \
    /app/etl_transform.py

# Tampilkan hasil parquet
echo ""
echo "📊 Hasil ETL Transform:"
docker exec spark_master ls -lah /data/parquet/

echo ""
echo "✅ ETL TRANSFORM SELESAI"
