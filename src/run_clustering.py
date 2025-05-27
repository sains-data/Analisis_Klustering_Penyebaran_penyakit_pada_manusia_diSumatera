"""
Clustering Script - Penyakit Sumatera Utara
Fungsi: Melakukan KMeans clustering menggunakan Spark MLlib
"""

import os
import sys
from pyspark.sql import SparkSession
from pyspark.ml.feature import VectorAssembler, StandardScaler
from pyspark.ml.clustering import KMeans
from pyspark.ml.evaluation import ClusteringEvaluator
from pyspark.sql.functions import col, desc, asc

def create_spark_session():
    """Membuat Spark Session"""
    spark = SparkSession.builder \
        .appName("PenyakitSumut-Clustering") \
        .getOrCreate()
    
    spark.sparkContext.setLogLevel("WARN")
    return spark

def read_transformed_data(spark):
    """Membaca data yang sudah ditransformasi"""
    parquet_path = "/data/parquet/penyakit_transformed.parquet"
    
    try:
        df = spark.read.parquet(parquet_path)
        print(f"✅ Berhasil membaca data dari: {parquet_path}")
        print(f"📊 Total baris: {df.count()}")
        return df
        
    except Exception as e:
        print(f"❌ Error membaca data: {e}")
        sys.exit(1)

def prepare_features(df):
    """Persiapan features untuk clustering"""
    print("\n=== FEATURE PREPARATION ===")
    
    # Define feature columns (exclude kabupaten_kota)
    feature_cols = [c for c in df.columns if c != 'kabupaten_kota']
    print(f"Feature columns: {feature_cols}")
    
    # Assemble features into vector
    assembler = VectorAssembler(
        inputCols=feature_cols,
        outputCol="features_raw"
    )
    
    df_assembled = assembler.transform(df)
    
    # Scale features for better clustering
    scaler = StandardScaler(
        inputCol="features_raw",
        outputCol="features",
        withStd=True,
        withMean=True
    )
    
    scaler_model = scaler.fit(df_assembled)
    df_scaled = scaler_model.transform(df_assembled)
    
    print("✅ Features berhasil dipersiapkan dan discale")
    
    return df_scaled, feature_cols

def find_optimal_k(df_scaled, max_k=8):
    """Mencari optimal K menggunakan elbow method"""
    print("\n=== FINDING OPTIMAL K ===")
    
    costs = []
    silhouette_scores = []
    
    for k in range(2, max_k + 1):
        # Train KMeans
        kmeans = KMeans(k=k, seed=42, maxIter=20)
        model = kmeans.fit(df_scaled)
        
        # Calculate cost (WSSSE)
        cost = model.summary.trainingCost
        costs.append(cost)
        
        # Calculate silhouette score
        predictions = model.transform(df_scaled)
        evaluator = ClusteringEvaluator()
        silhouette = evaluator.evaluate(predictions)
        silhouette_scores.append(silhouette)
        
        print(f"K={k}: Cost={cost:.2f}, Silhouette={silhouette:.3f}")
    
    # Find optimal K (highest silhouette score)
    optimal_k = silhouette_scores.index(max(silhouette_scores)) + 2
    print(f"\n🎯 Optimal K: {optimal_k} (Silhouette Score: {max(silhouette_scores):.3f})")
    
    return optimal_k, costs, silhouette_scores

def perform_clustering(df_scaled, k=4):
    """Melakukan KMeans clustering"""
    print(f"\n=== PERFORMING KMEANS CLUSTERING (K={k}) ===")
    
    # Initialize KMeans
    kmeans = KMeans(
        k=k,
        seed=42,
        maxIter=50,
        tol=1e-4
    )
    
    # Train model
    model = kmeans.fit(df_scaled)
    
    # Make predictions
    predictions = model.transform(df_scaled)
    
    # Evaluate clustering
    evaluator = ClusteringEvaluator()
    silhouette = evaluator.evaluate(predictions)
    
    print(f"✅ Clustering selesai")
    print(f"📊 Silhouette Score: {silhouette:.3f}")
    print(f"📊 Within Set Sum of Squared Errors: {model.summary.trainingCost:.2f}")
    
    return model, predictions

def analyze_clusters(predictions):
    """Analisis hasil clustering"""
    print("\n=== CLUSTER ANALYSIS ===")
    
    # Count by cluster
    cluster_counts = predictions.groupBy("prediction").count().orderBy("prediction")
    print("\nJumlah kabupaten per cluster:")
    cluster_counts.show()
    
    # Show kabupaten in each cluster
    for i in range(4):  # Assuming 4 clusters
        print(f"\n🏷️  CLUSTER {i}:")
        cluster_data = predictions.filter(col("prediction") == i) \
            .select("kabupaten_kota", "prediction") \
            .orderBy("kabupaten_kota")
        cluster_data.show(truncate=False)
    
    return predictions

def save_results_to_parquet(predictions):
    """Simpan hasil clustering ke Parquet"""
    try:
        output_path = "/data/parquet/clustering_results.parquet"
        
        predictions.coalesce(1).write \
            .mode("overwrite") \
            .parquet(output_path)
        
        print(f"✅ Hasil clustering berhasil disimpan ke: {output_path}")
        
    except Exception as e:
        print(f"❌ Error saving to Parquet: {e}")

def export_for_visualization(predictions):
    """Export data untuk visualisasi"""
    print("\n=== EXPORTING FOR VISUALIZATION ===")
    
    try:
        # Convert to Pandas for easier manipulation
        pandas_df = predictions.select(
            "kabupaten_kota",
            "prediction",
            "aids_kasus_baru",
            "aids_kasus_kumulatif", 
            "dbd",
            "diare",
            "tb_paru"
        ).toPandas()
        
        # Save to CSV for Tableau
        csv_path = "/data/output/clustering_results.csv"
        pandas_df.to_csv(csv_path, index=False)
        print(f"✅ Data exported ke CSV: {csv_path}")
        
        return pandas_df
        
    except Exception as e:
        print(f"❌ Error exporting data: {e}")
        return None

def main():
    """Main function untuk clustering"""
    print("🧠 MEMULAI CLUSTERING ANALYSIS")
    print("=" * 50)
    
    # Create Spark session
    spark = create_spark_session()
    
    try:
        # Read transformed data
        df = read_transformed_data(spark)
        
        # Prepare features
        df_scaled, feature_cols = prepare_features(df)
        
        # Find optimal K
        optimal_k, costs, silhouette_scores = find_optimal_k(df_scaled)
        
        # Perform clustering with optimal K (or use default K=4)
        k = 4  # As specified in requirements
        model, predictions = perform_clustering(df_scaled, k)
        
        # Analyze clusters
        final_predictions = analyze_clusters(predictions)
        
        # Save results to Parquet
        save_results_to_parquet(final_predictions)
        
        # Export for visualization
        export_for_visualization(final_predictions)
        
        print("\n✅ CLUSTERING ANALYSIS SELESAI")
        
    except Exception as e:
        print(f"❌ Error dalam clustering: {e}")
        sys.exit(1)
        
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
