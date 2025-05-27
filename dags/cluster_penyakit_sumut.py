from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.bash_operator import BashOperator

default_args = {
    'owner': 'kelompok9',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'cluster_penyakit_sumut',
    default_args=default_args,
    description='Pipeline ETL dan Clustering Penyakit',
    schedule_interval='@daily',
    catchup=False,
)

ingest = BashOperator(
    task_id='ingest_csv',
    bash_command='spark-submit /scripts/ingest.py',
    dag=dag,
)

etl = BashOperator(
    task_id='etl_cleaning',
    bash_command='spark-submit /scripts/etl_cleaning.py',
    dag=dag,
)

clustering = BashOperator(
    task_id='run_kmeans',
    bash_command='spark-submit /scripts/clustering_kmeans.py',
    dag=dag,
)

ingest >> etl >> clustering
