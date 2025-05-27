#!/bin/bash

# Script untuk start Docker services
# # Check dan hentikan container yang konfliks
if docker ps -a | grep -q "postgres_penyakit" || docker ps -a | grep -q "spark_master" || docker ps -a | grep -q "spark_worker"; then
    log "Container dengan nama yang sama sudah ada, menghentikan dan menghapusnya..."
    
    # Hentikan dan hapus container satu per satu
    for container in postgres_penyakit spark_master spark_worker; do
        if docker ps -a | grep -q "$container"; then
            warning "Menghentikan dan menghapus container: $container"
            docker stop $container 2>/dev/null || true
            docker rm $container 2>/dev/null || true
        fi
    done
fi

# Stop dan remove container yang ada dari docker-compose (jika ada)
log "Stopping dan removing existing containers dari docker-compose..."
docker-compose down --remove-orphans || true

# Build dan start services
log "Building dan starting Docker services..."
docker-compose up -da Engineering - Institut Teknologi Sumatera

set -e

echo "🚀 STARTING DOCKER SERVICES FOR PENYAKIT SUMUT PIPELINE"
echo "====================================================="

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Check jika Docker sudah berjalan
if ! docker info > /dev/null 2>&1; then
    error "Docker tidak berjalan. Silakan start Docker terlebih dahulu."
    exit 1
fi

# Check jika docker compose tersedia
if ! command -v docker compose &> /dev/null; then
    error "docker compose tidak ditemukan. Silakan install docker compose."
    exit 1
fi

# Membuat direktori yang diperlukan
log "Membuat direktori yang diperlukan..."
mkdir -p data/output/plots
mkdir -p data/parquet
mkdir -p data/logs

# Stop dan remove container yang ada (jika ada)
log "Stopping dan removing existing containers..."
docker compose down --remove-orphans || true

# Build dan start services
log "Building dan starting Docker services..."
docker compose up -d

# Tunggu hingga services siap
log "Menunggu services siap..."
sleep 10

# Check PostgreSQL
log "Checking PostgreSQL readiness..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if docker exec postgres_penyakit pg_isready -U postgres > /dev/null 2>&1; then
        log "PostgreSQL is ready!"
        break
    else
        warning "PostgreSQL belum siap, attempt $attempt/$max_attempts..."
        sleep 2
        ((attempt++))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    error "PostgreSQL tidak siap setelah $max_attempts attempts"
    exit 1
fi

# Check Spark Master
log "Checking Spark Master readiness..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -s http://localhost:8080 > /dev/null 2>&1; then
        log "Spark Master is ready!"
        break
    else
        warning "Spark Master belum siap, attempt $attempt/$max_attempts..."
        sleep 2
        ((attempt++))
    fi
done

if [ $attempt -gt $max_attempts ]; then
    error "Spark Master tidak siap setelah $max_attempts attempts"
    exit 1
fi

# Tampilkan status containers
log "Docker containers status:"
docker compose ps

echo ""
info "====================================================="
info "🎉 DOCKER SERVICES SUCCESSFULLY STARTED!"
info "====================================================="
echo ""
info "Services available:"
info "- PostgreSQL: localhost:5432 (user: postgres, pass: password123)"
info "- Spark Master UI: http://localhost:8080"
echo ""
info "To run the pipeline:"
info "  ./run_pipeline.sh"
echo ""
info "To stop all services:"
info "  docker compose down"
echo ""
info "To view logs:"
info "  docker compose logs [service_name]"
echo ""
