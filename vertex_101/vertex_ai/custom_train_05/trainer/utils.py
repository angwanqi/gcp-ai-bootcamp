from typing import List, Union, Dict, Optional
import numpy as np
import dask.dataframe as dask_df
import xgboost as xgb
from sklearn.metrics import (roc_curve, confusion_matrix, average_precision_score, f1_score, 
                            log_loss, precision_score, recall_score)
from google.cloud import storage
from pydantic import BaseModel, Field


def gcs_read(project_id: str, bucket: str, blob_name: str) -> storage.Blob:
    client = storage.Client(project=project_id)
    bucket = client.bucket(bucket_name=bucket)
    return bucket.blob(blob_name)


class VertexConfig(BaseModel):
    PROJECT_ID: str
    BUCKET_NAME: str
    REGION: str
    ID: str
    FEATURESTORE_ID: str
    FEATUREVIEW_ID: str
    NETWORK: str
    SUBNET: str
    CUSTOMER_ENTITY_ID: str = Field(default="customer")
    CUSTOMER_ENTITY_ID_FIELD: str = Field(default="customer_id")
    TERMINAL_ENTITY_ID: str = Field(default="terminal")
    TERMINALS_ENTITY_ID_FIELD: str = Field(default="terminal_id")
    MODEL_REGISTRY: str = Field(default="ff_model")
    RAW_BQ_TRANSACTION_TABLE_URI: str
    RAW_BQ_LABELS_TABLE_URI: str
    FEATURES_BQ_TABLE_URI: str
    FEATURE_TIME: str = Field(default="feature_ts")
    ONLINE_STORAGE_NODES: int = Field(default=1)
    SUBSCRIPTION_NAME: str
    SUBSCRIPTION_PATH: str
    DROP_COLUMNS: List[str]
    TARGET_COLUMN: str = Field(default="tx_fraud")
    FEAT_COLUMNS: List[str]
    DATA_SCHEMA: Dict[str, str]
    MODEL_NAME: str = Field(default="ff_model_xgb_exp_8wc8m")
    EXPERIMENT_NAME: str = Field(default="ff-experiment-8wc8m")
    DATA_URI: str
    TRAIN_DATA_URI: str
    READ_INSTANCES_TABLE: str
    READ_INSTANCES_URI: str
    DATASET_NAME: str
    JOB_NAME: str
    ENDPOINT_NAME: str
    MODEL_SERVING_IMAGE_URI: str = Field(default="us-docker.pkg.dev/vertex-ai/prediction/xgboost-cpu.1-7:latest")
    IMAGE_REPOSITORY: str
    IMAGE_NAME: str = Field(default="dask-xgb-classificator")
    IMAGE_TAG: str = Field(default="latest")
    IMAGE_URI: str
    TRAIN_COMPUTE: str = Field(default="e2-standard-4")
    DEPLOY_COMPUTE: str = Field(default="n1-standard-4")
    BASE_IMAGE: str = Field(default="python:3.10")
    PIPELINE_NAME: str
    PIPELINE_ROOT: str
    BQ_DATASET: str = Field(default="tx")
    METRICS_URI: str
    AVG_PR_THRESHOLD: float
    MODEL_THRESHOLD: float
    AVG_PR_CONDITION: str = Field(default="avg_pr_condition")
    PERSISTENT_RESOURCE_ID: Optional[str] = Field(default=None)
    REPLICA_COUNT: int = Field(default=1)
    SERVICE_ACCOUNT: str


def gcs_path_to_local_path(old_path: str) -> str:
    """convert GCS path to local path

    Args:
        old_path (str): GCS path

    Returns:
        str: local path
    """
    if old_path.startswith("gs://"):
        new_path = old_path.replace("gs://", "/gcs/")
    else:
        new_path = f"/gcs/{old_path}"
    return new_path


def resample(df: dask_df.DataFrame, replace: bool, frac: float = 1, random_state: int = 8) -> dask_df.DataFrame:
    shuffled_df = df.sample(frac=frac, replace=replace, random_state=random_state)
    return shuffled_df


def preprocess(df: dask_df.DataFrame, drop_cols: List[str] = None) -> dask_df.DataFrame:
    if drop_cols:
        df = df.drop(columns=drop_cols)

    # Drop rows with NaN"s
    df = df.dropna()

    # Convert integer valued (numeric) columns to floating point
    numeric_columns = df.select_dtypes(["float32", "float64"]).columns
    numeric_format = {col:"float32" for col in numeric_columns}
    df = df.astype(numeric_format)

    return df


def evaluate_model(model: xgb.Booster, x_true: Union[dask_df.DataFrame, np.ndarray], y_true: Union[dask_df.Series, np.ndarray]) -> dict:
    y_true = y_true.compute()
 
    #calculate metrics
    metrics={}

    y_score =  model.predict_proba(x_true)[:, 1]
    y_score = y_score.compute()
    fpr, tpr, thr = roc_curve(
         y_true=y_true, y_score=y_score, pos_label=True
    )
    fpr_list = fpr.tolist()[::1000]
    tpr_list = tpr.tolist()[::1000]
    thr_list = thr.tolist()[::1000]

    y_pred = model.predict(x_true)
    y_pred = y_pred.compute()
    c_matrix = confusion_matrix(y_true, y_pred)
 
    avg_precision_score = round(average_precision_score(y_true, y_score), 3)
    f1 = round(f1_score(y_true, y_pred), 3)
    lg_loss = round(log_loss(y_true, y_pred), 3)
    prec_score = round(precision_score(y_true, y_pred), 3)
    rec_score = round(recall_score(y_true, y_pred), 3)

    metrics["fpr"] = [round(f, 3) for f in fpr_list]
    metrics["tpr"] = [round(f, 3) for f in tpr_list]
    metrics["thrs"] = [round(f, 3) for f in thr_list]
    metrics["confusion_matrix"] = c_matrix.tolist()
    metrics["avg_precision_score"] = avg_precision_score
    metrics["f1_score"] = f1
    metrics["log_loss"] = lg_loss
    metrics["precision_score"] = prec_score
    metrics["recall_score"] = rec_score
 
    return metrics
