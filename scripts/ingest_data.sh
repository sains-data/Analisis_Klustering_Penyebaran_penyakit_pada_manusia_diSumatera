#!/bin/bash

# Script untuk menjalankan Data Ingestion
# Tim Data Engineering - Institut Teknologi Sumatera

set -e

echo "🔄 MENJALANKAN DATA INGESTION"
echo "============================="

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

# Jalankan ingestion script
echo "📝 Menjalankan script ingest_data.py..."
docker exec spark_master /spark/bin/spark-submit \
    --master spark://spark-master:7077 \
    --driver-memory 1g \
    --executor-memory 1g \
    /app/ingest_data.py

# Tampilkan hasil parquet
echo ""
echo "📊 Hasil Data Ingestion:"
docker exec spark_master ls -lah /data/parquet/

echo ""
echo "✅ DATA INGESTION SELESAI"
