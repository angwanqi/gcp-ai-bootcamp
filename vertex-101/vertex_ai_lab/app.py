"""
29 Oct:
- Need to add metadata check before training. It fails if metadata already exist
- Code to be clean up. Remove unnecessary prints 

"""
# General
import os
import sys
from typing import Union, List
import random
from datetime import datetime, timedelta
import time
import json
import logging
import subprocess

# GCP 
from google.cloud import aiplatform as vertex_ai
from google.cloud.aiplatform import Featurestore, EntityType, Feature
import google.cloud.storage as storage

# Data Preprocessing
import numpy as np
import pandas as pd

# Model Training
from google.cloud import bigquery
from google.cloud import storage
from sklearn.metrics import accuracy_score
from sklearn.metrics import f1_score
from sklearn.linear_model import LogisticRegression
import xgboost as xgb

# Define constants and variables 

# General
#DATA_DIR = "data"
#DATA_URI = f"gs://{BUCKET_NAME}/data"
#TRAIN_DATA_URI = f"{DATA_URI}/train"


# Training
COLUMNS_IGNORE = [
    "terminal_id",
    "customer_id",
    "entity_type_event",
    "entity_type_customer",
    "entity_type_terminal",
]
TARGET = "tx_fraud"


def load_environment_variables_from_gcs(bucket_name, file_path):
    """Loads environment variables from a Python file in GCS.

    Args:
        bucket_name: The name of the GCS bucket.
        file_path: The path to the Python file within the bucket.

    Returns:
        None. Sets the environment variables directly.
    """

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file_path)
    config_file_content = blob.download_as_string().decode("utf-8")

    # Execute the content of the config file in a local dictionary
    local_vars = {}
    exec(config_file_content, globals(), local_vars)

    
    # Declare all variables in the config file as global
    globals().update({key: value for key, value in local_vars.items() if not key.startswith("_")}) 
    
    # Set environment variables from the local dictionary
    #for key, value in local_vars.items():
    #    if not key.startswith("_"):  # Exclude internal variables
    #        os.environ[key] = str(value)  # Ensure value is a string


def get_gcp_project():
  """Retrieves the currently active GCP project ID.
  """
  try:
    process = subprocess.run(['gcloud', 'config', 'get-value', 'project'], capture_output=True, text=True)
    project_id = process.stdout.strip()
    return project_id
  except FileNotFoundError:
    print("gcloud CLI not found. Please install and configure it.")
    return None

def save_model_to_gcs(model, bucket_name, model_path):
    """Saves a model to a GCS bucket.
    """
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(model_path)

    # Save the model to a temporary file
    temp_file = "/tmp/model.bst" 
    model.save_model(temp_file)

    # Upload the temporary file to GCS
    blob.upload_from_filename(temp_file)

    
def run_bq_query(sql: str) -> Union[str, pd.DataFrame]:
    """
    Run a BigQuery query and return the job ID or result as a DataFrame
    Args:
        sql: SQL query, as a string, to execute in BigQuery
    Returns:
        df: DataFrame of results from query, or error, if any
    """

    bq_client = bigquery.Client()

    # Try dry run before executing query to catch any errors
    job_config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
    bq_client.query(sql, job_config=job_config)

    # If dry run succeeds without errors, proceed to run query
    job_config = bigquery.QueryJobConfig()
    client_result = bq_client.query(sql, job_config=job_config)

    job_id = client_result.job_id

    # Wait for query/job to finish running. then get & return data frame
    df = client_result.result().to_arrow().to_pandas()
    print(f"Finished job_id: {job_id}")
    return df


def preprocess(df: pd.DataFrame):
    """
    Converts categorical features to numeric. Removes unused columns.
    Args:
        df: Pandas df with raw data
    Returns:
        df with preprocessed data
    """
    df = df.drop(columns=UNUSED_COLUMNS)

    # Drop rows with NaN"s
    df = df.dropna()

    # Convert integer valued (numeric) columns to floating point
    numeric_columns = df.select_dtypes(["int32", "float32", "float64"]).columns
    df[numeric_columns] = df[numeric_columns].astype("float32")

    dummy_columns = list(df.dtypes[df.dtypes == "category"].index)
    df = pd.get_dummies(df, columns=dummy_columns)

    return df

if __name__ == "__main__": 
    
    # Get project id, bucket name and set env 
    GCP_PROJECTS = get_gcp_project()
    PROJECT_ID = GCP_PROJECTS
    BUCKET_NAME = f"{PROJECT_ID}-fraudfinder"
    DATA_DIR = "data"
    DATA_URI = f"gs://{BUCKET_NAME}/data"
    TRAIN_DATA_URI = f"{DATA_URI}/train"

    # Load environment variables from GCS
    load_environment_variables_from_gcs(BUCKET_NAME, "config/notebook_env.py")

    # (testing code)Print the environment variables
    #print("\nEnvironment variables:")
    #for key, value in os.environ.items():
    #    print(f"  {key}: {value}")
    
    # Feature Store
    START_DATE_TRAIN = (datetime.today() - timedelta(days=1)).strftime("%Y-%m-%d")
    END_DATE_TRAIN = (datetime.today() - timedelta(days=1)).strftime("%Y-%m-%d")
    CUSTOMER_ENTITY = "customer"
    TERMINAL_ENTITY = "terminal"
    SERVING_FEATURE_IDS = {CUSTOMER_ENTITY: ["*"], TERMINAL_ENTITY: ["*"]}
    READ_INSTANCES_TABLE = f"ground_truth_{END_DATE_TRAIN}"
    READ_INSTANCES_URI = f"bq://{PROJECT_ID}.tx.{READ_INSTANCES_TABLE}"

    # Custom Training
    MODEL_NAME = f"ff_model_xgb_exp_{ID}"

    # Experiment
    EXPERIMENT_NAME = f"ff-experiment-{ID}"
    
    
    bq_client = bigquery.Client(project=PROJECT_ID, location=REGION)

    vertex_ai.init(
        project=PROJECT_ID,
        location=REGION,
        staging_bucket=BUCKET_NAME,
        experiment=EXPERIMENT_NAME,
    )

    # This code will only run when the script is executed, not when it's imported

    read_instances_query = f"""
        SELECT
            raw_tx.TX_TS AS timestamp,
            raw_tx.CUSTOMER_ID AS customer,
            raw_tx.TERMINAL_ID AS terminal,
            raw_tx.TX_AMOUNT AS tx_amount,
            raw_lb.TX_FRAUD AS tx_fraud,
        FROM 
            tx.tx as raw_tx
        LEFT JOIN 
            tx.txlabels as raw_lb
        ON raw_tx.TX_ID = raw_lb.TX_ID
        WHERE
            DATE(raw_tx.TX_TS) = "{START_DATE_TRAIN}";
    """
    print(read_instances_query)

    query_df = run_bq_query(read_instances_query)
    print(query_df.head(4))

    ff_feature_store = Featurestore(FEATURESTORE_ID)

    sample_df = ff_feature_store.batch_serve_to_df(
        serving_feature_ids=SERVING_FEATURE_IDS,
        read_instances_df=query_df,
        pass_through_fields=["tx_fraud", "tx_amount"],
    )

    print(sample_df.head(5))
    print(sample_df.info())

    ## --- Create balanced_df ---
    shuffled_df = sample_df.sample(frac=1, random_state=4)
    fraud_df = shuffled_df.loc[shuffled_df["tx_fraud"] == 1]
    non_fraud_df = shuffled_df.loc[shuffled_df["tx_fraud"] == 0].sample(
        n=fraud_df.shape[0], random_state=42
    )
    balanced_df = pd.concat([fraud_df, non_fraud_df])
    #print((balanced_df.tx_fraud.value_counts() / balanced_df.shape[0]) * 100)
    
    # Set up training variables
    LABEL_COLUMN = "tx_fraud"
    UNUSED_COLUMNS = ["timestamp", "entity_type_customer", "entity_type_terminal"]
    NA_VALUES = ["NA", "."]

    df_dataset = balanced_df
    df_train, df_test, df_val = np.split(
        df_dataset.sample(frac=1, random_state=42),
        [int(0.6 * len(df_dataset)), int(0.8 * len(df_dataset))],
    )

    # Training set
    preprocessed_train_data = preprocess(df_train)
    x_train = preprocessed_train_data[
        preprocessed_train_data.columns.drop(LABEL_COLUMN).to_list()
    ].values
    y_train = preprocessed_train_data.loc[:, LABEL_COLUMN].astype(int)

    # Validation set
    preprocessed_val_data = preprocess(df_val)
    x_val = preprocessed_val_data[
        preprocessed_val_data.columns.drop(LABEL_COLUMN).to_list()
    ].values
    y_val = preprocessed_val_data.loc[:, LABEL_COLUMN].astype(int)

    # Test set
    preprocessed_test_data = preprocess(df_test)
    x_test = preprocessed_test_data[
        preprocessed_test_data.columns.drop(LABEL_COLUMN).to_list()
    ].values
    y_test = preprocessed_test_data.loc[:, LABEL_COLUMN].astype(int)


    parameters = [
        {"eta": 0.2, "gamma": 0.0, "max_depth": 4},
        {"eta": 0.2, "gamma": 0.0, "max_depth": 5},
        {"eta": 0.2, "gamma": 0.1, "max_depth": 4},
        {"eta": 0.2, "gamma": 0.1, "max_depth": 5},
        {"eta": 0.3, "gamma": 0.0, "max_depth": 4},
        {"eta": 0.3, "gamma": 0.0, "max_depth": 5},
        {"eta": 0.3, "gamma": 0.1, "max_depth": 4},
        {"eta": 0.3, "gamma": 0.1, "max_depth": 5},
    ]

    models = {}
    for i, params in enumerate(parameters):
        run_name = f"ff-xgboost-local-run-app-{i}"
        print(run_name)
        vertex_ai.start_run(run=run_name)
        vertex_ai.log_params(params)
        model = xgb.XGBClassifier(
            objective="reg:logistic",
            max_depth=params["max_depth"],
            gamma=params["gamma"],
            eta=params["eta"],
            use_label_encoder=False,
        )
        model.fit(x_train, y_train)
        models[run_name] = model
        y_pred_proba = model.predict_proba(x_val)[:, 1]
        y_pred = model.predict(x_val)
        acc_score = accuracy_score(y_val, y_pred)
        val_f1_score = f1_score(y_val, y_pred, average="weighted")
        vertex_ai.log_metrics({"acc_score": acc_score, "f1score": val_f1_score})
        vertex_ai.end_run()


    experiment_df = vertex_ai.get_experiment_df()
    # print(experiment_df.sort_values(["metric.f1score"], ascending=False))

    model_directory = "models"  # Changed to current directory
    os.makedirs(model_directory, exist_ok=True)  # Create if it doesn't exist

    model = models[f"ff-xgboost-local-run-app-{i}"]
    artifact_filename = "model.bst"
    # Replace with your desired bucket name and model path
    bucket_name = "model-upload"  
    model_path = "models/model.bst"  

    save_model_to_gcs(model, bucket_name, model_path) 
