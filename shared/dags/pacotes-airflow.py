import airflow
from airflow.models import DAG
from airflow.operators.bash_operator import BashOperator
from airflow.operators.dummy_operator import DummyOperator

args = {
    'owner': 'Helder',
    'start_date': airflow.utils.dates.days_ago(2)
}

dag = DAG(
    dag_id='instalacao-inicial',
    default_args=args,
    schedule_interval=None
)

A = DummyOperator(
    task_id="início",
    dag=dag
)

B = BashOperator(
    task_id='ler-script-R',
    bash_command="Rscript /usr/local/spark/app/scripts/instalacao-inicial.R",
    dag=dag)

C = DummyOperator(
    task_id="fim",
    dag=dag
)

A >> B >> C