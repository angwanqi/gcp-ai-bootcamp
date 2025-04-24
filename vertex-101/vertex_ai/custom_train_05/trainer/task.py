import os
import json
import yaml
from pathlib import Path
import dask.dataframe as dask_df
from dask.distributed import LocalCluster, Client
import xgboost as xgb
from trainer.utils import (
    gcs_path_to_local_path, resample, preprocess, evaluate_model, gcs_read, 
    VertexConfig
)


# Detect Cloud project from environment
PROJECT_ID = os.environ["project_id"]
BUCKET_NAME = f"{PROJECT_ID}-fraudfinder"
CONFIG_PATH = "config/vertex_conf.yaml"
with gcs_read(PROJECT_ID, BUCKET_NAME, CONFIG_PATH).open("r") as blob:
    vertex_conf = yaml.safe_load(blob)
vertex_config = VertexConfig(**vertex_conf)

TRAINING_DATA_PATH = gcs_path_to_local_path(os.environ["AIP_TRAINING_DATA_URI"])
TEST_DATA_PATH = gcs_path_to_local_path(os.environ["AIP_TEST_DATA_URI"])
MODEL_DIR = gcs_path_to_local_path(os.environ["AIP_MODEL_DIR"])
MODEL_PATH = MODEL_DIR + "model.bst"


# Training variables
def main():
    # variables
    bucket = gcs_path_to_local_path(vertex_config.BUCKET_NAME)
    deliverable_uri = (Path(bucket)/"deliverables")
    metrics_uri = (deliverable_uri/"metrics.json")

    # read data
    train_df = dask_df.read_csv(TRAINING_DATA_PATH, dtype=vertex_config.DATA_SCHEMA)
    test_df = dask_df.read_csv(TEST_DATA_PATH, dtype=vertex_config.DATA_SCHEMA)
    print("df loaded")
    
    # preprocessing
    preprocessed_train_df = preprocess(train_df, vertex_config.DROP_COLUMNS)
    preprocessed_test_df = preprocess(test_df, vertex_config.DROP_COLUMNS)
    print("df preprocessed")

    # downsampling
    train_nfraud_df = preprocessed_train_df[preprocessed_train_df[vertex_config.TARGET_COLUMN]==0]
    train_fraud_df = preprocessed_train_df[preprocessed_train_df[vertex_config.TARGET_COLUMN]==1]
    train_nfraud_downsample = resample(train_nfraud_df, replace=True, frac=len(train_fraud_df)/len(train_df))
    ds_preprocessed_train_df = dask_df.concat([train_nfraud_downsample, train_fraud_df])
    
    # target, features split
    x_train = ds_preprocessed_train_df[vertex_config.FEAT_COLUMNS].values
    y_train = ds_preprocessed_train_df.loc[:, vertex_config.TARGET_COLUMN].astype(int).values
    x_true = preprocessed_test_df[vertex_config.FEAT_COLUMNS].values
    y_true = preprocessed_test_df.loc[:, vertex_config.TARGET_COLUMN].astype(int).values
    
    # train model
    print("start training")
    cluster =  LocalCluster()
    client = Client(cluster)
    model = xgb.dask.DaskXGBClassifier(objective="reg:logistic", eval_metric="logloss")
    model.client = client
    model.fit(x_train, y_train, eval_set=[(x_true, y_true)])
    print("finish training")
    if not Path(MODEL_DIR).exists():
        Path(MODEL_DIR).mkdir(parents=True, exist_ok=True)
    model.save_model(MODEL_PATH)
    print("model saved")
    
    #generate metrics
    metrics = evaluate_model(model, x_true, y_true)
    if not Path(deliverable_uri).exists():
        Path(deliverable_uri).mkdir(parents=True, exist_ok=True)
    with open(metrics_uri, "w") as file:
        json.dump(metrics, file, sort_keys=True, indent=2)
    print("metrics saved")


if __name__ == "__main__":
    print("start training...")
    main()
    print("finish training")
