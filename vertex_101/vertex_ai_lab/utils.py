import io
from typing import List, Dict, Optional, Any

import yaml
from google.cloud import storage
from pydantic import BaseModel, Field


def gcs_read(project_id: str, bucket: str, blob_name: str) -> storage.Blob:
    client = storage.Client(project=project_id)
    bucket = client.bucket(bucket_name=bucket)
    return bucket.blob(blob_name)


def gcs_write(project_id: str, bucket: str, blob_name: str, content: io.StringIO | io.BytesIO) -> None:
    client = storage.Client(project=project_id)
    bucket = client.bucket(bucket_name=bucket)
    blob = bucket.blob(blob_name)
    blob.upload_from_file(content, rewind=True)


def read_from_bucket(bucket_name: str, uri: str, deserialize: bool = True) -> Any:
    client = storage.Client()
    bucket = client.bucket(bucket_name=bucket_name)
    blob = bucket.blob(uri)
    content = blob.download_as_string()
    if deserialize:
        content = yaml.safe_load(content)
    return content


class VertexConfig(BaseModel):
    PROJECT_ID: str
    BUCKET_NAME: str
    STAGING_BUCKET: str
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
    MODEL_NAME: str = Field(default="ff_model")
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
    BASE_IMAGE: str = Field(default="python:3.11")
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
