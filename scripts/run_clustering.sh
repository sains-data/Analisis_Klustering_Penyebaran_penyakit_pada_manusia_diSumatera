#!/bin/bash

# Script untuk menjalankan KMeans Clustering
# Tim Data Engineering - Institut Teknologi Sumatera

set -e

echo "🧠 MENJALANKAN KMEANS CLUSTERING"
echo "=============================="

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
if ! docker exec spark_master ls -la /data/parquet/penyakit_transformed.parquet > /dev/null 2>&1; then
    echo "❌ Data transform belum tersedia. Silakan jalankan ./scripts/etl_transform.sh terlebih dahulu."
    exit 1
fi

# Jalankan clustering script
echo "📝 Menjalankan script run_clustering.py..."
docker exec spark_master /spark/bin/spark-submit \
    --master spark://spark-master:7077 \
    --driver-memory 1g \
    --executor-memory 1g \
    /app/run_clustering.py

# Tampilkan hasil parquet
echo ""
echo "📊 Hasil Clustering:"
docker exec spark_master ls -lah /data/parquet/

echo ""
echo "✅ CLUSTERING SELESAI"
