#!/bin/bash

# ==========================================
# PENYAKIT SUMATERA UTARA - PIPELINE STARTER
# ==========================================
# Script utama untuk menjalankan seluruh pipeline clustering
# menggunakan Docker Compose dan Apache Spark

set -e  # Exit on error

# Colors untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_status() {
    echo -e "${YELLOW}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if data file exists
    if [ ! -f "data/Penyakit_Sumut.csv" ]; then
        print_error "Data file not found: data/Penyakit_Sumut.csv"
        echo "Please make sure the CSV file is in the data/ directory"
        exit 1
    fi
    
    # Check if required directories exist
    mkdir -p data/parquet data/output data/logs data/output/plots
    
    print_success "All prerequisites checked"
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=60
    local attempt=1
    
    print_status "Waiting for $service_name to be ready on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec postgres_penyakit pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        echo "  Attempt $attempt/$max_attempts - waiting 5 seconds..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start after $max_attempts attempts"
    return 1
}

# Function to check Spark master
wait_for_spark() {
    local max_attempts=60
    local attempt=1
    
    print_status "Waiting for Spark Master to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:8080 > /dev/null 2>&1; then
            print_success "Spark Master is ready!"
            # Install Python dependencies untuk Spark worker dan master
            print_status "Installing Python dependencies..."
            docker exec spark_worker apk add --no-cache  py3-numpy py3-scipy
            docker exec spark_master apk add --no-cache  py3-numpy py3-scipy 
            print_success "Python dependencies installed"
            return 0
        fi
        
        echo "  Attempt $attempt/$max_attempts - waiting 5 seconds..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "Spark Master failed to start"
    return 1
}

# Main execution
main() {
    print_header "STARTING PENYAKIT SUMATERA UTARA PIPELINE"
    echo "Started at: $(date)"
    echo ""
    
    # Step 1: Check prerequisites
    check_docker
    check_prerequisites
    
    # Step 2: Stop any existing containers
    print_status "Stopping existing containers..."
    docker compose down -v 2>/dev/null || true
    print_success "Existing containers stopped"
    
    # Step 3: Start services
    print_status "Starting Docker services..."
    docker compose up -d
    
    if [ $? -eq 0 ]; then
        print_success "Docker services started successfully"
    else
        print_error "Failed to start Docker services"
        exit 1
    fi
    
    # Step 4: Wait for services to be ready
    wait_for_service "PostgreSQL" "5432"
    wait_for_spark
    
    # Give services a moment to fully initialize
    print_status "Allowing services to fully initialize..."
    sleep 10
    
    # Step 5: Run the complete pipeline
    print_header "RUNNING DATA PIPELINE"
    
    print_status "Executing pipeline inside Spark Master container..."
    
    # Execute the pipeline inside the Spark container
    ./run_pipeline.sh
    
    
    if [ $? -eq 0 ]; then
        print_success "Pipeline completed successfully!"
    else
        print_error "Pipeline failed!"
        echo ""
        echo "To debug, check logs:"
        echo "  docker logs spark_master"
        echo "  docker logs postgres_penyakit"
        exit 1
    fi
    
    # Step 6: Show access information
    print_header "PIPELINE COMPLETED - ACCESS INFORMATION"
    
    echo -e "${GREEN}🎉 Success! Your pipeline is now running.${NC}"
    echo ""
    echo -e "${BLUE}📊 Access Points:${NC}"
    echo "  • Spark Master UI: http://localhost:8080"
    echo "  • PostgreSQL: localhost:5432 (user: postgres, password: password123)"
    echo ""
    echo -e "${BLUE}📁 Output Files:${NC}"
    echo "  • data/output/tableau_export.csv - For Tableau visualization"
    echo "  • data/output/clustering_summary_report.txt - Analysis report"
    echo "  • data/parquet/ - Intermediate Parquet files"
    echo ""
    echo -e "${BLUE}🔧 Useful Commands:${NC}"
    echo "  • Check logs: dockercompose logs -f"
    echo "  • Access Spark container: docker exec -it spark_master bash"
    echo "  • Access PostgreSQL: docker exec -it postgres_penyakit psql -U postgres -d penyakit_db"
    echo "  • Stop pipeline: dockercompose down"
    echo ""
    echo "Completed at: $(date)"
}

# Trap to handle interruption
trap 'echo -e "\n${RED}Pipeline interrupted by user${NC}"; dockercompose down; exit 1' INT

# Run main function
main "$@"
