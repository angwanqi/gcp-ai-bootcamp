import yaml
import argparse
import requests
from google.cloud import aiplatform as vertex_ai

from trainer.utils import gcs_read, VertexConfig


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-m", "--model", required=True)
    args = parser.parse_args()

    headers = {"Metadata-Flavor": "Google"}
    PROJECT_ID = requests.get(
        "http://metadata.google.internal/computeMetadata/v1/project/project-id", 
        headers=headers, 
        timeout=10,
    )
    PROJECT_ID = PROJECT_ID.content.decode()
    BUCKET_NAME = f"{PROJECT_ID}-fraudfinder"
    CONFIG_PATH = "config/vertex_conf.yaml"
    with gcs_read(PROJECT_ID, BUCKET_NAME, CONFIG_PATH).open("r") as blob:
        vertex_conf = yaml.safe_load(blob)
    vertex_config = VertexConfig(**vertex_conf)

    vertex_ai.init(
        project=vertex_config.PROJECT_ID,
        location=vertex_config.REGION,
        staging_bucket=vertex_config.BUCKET_NAME,
        experiment=vertex_config.EXPERIMENT_NAME,
    )


    # Percentage of traffic that the model will receive in the endpoint
    TRAFFIC_SPLIT = {"0": 100}

    # Parameters to configure the minimum and maximum nodes during autoscaling
    MIN_NODES = 1
    MAX_NODES = 1

    model = vertex_ai.Model(f"projects/{vertex_config.PROJECT_ID}/locations/{vertex_config.REGION}/models/{args.model}")

    endpoint = model.deploy(
        deployed_model_display_name=f"{vertex_config.MODEL_NAME}_xgb_{vertex_config.ID}",
        traffic_split=TRAFFIC_SPLIT,
        machine_type=vertex_config.DEPLOY_COMPUTE,
        accelerator_count=0,
        min_replica_count=MIN_NODES,
        max_replica_count=MAX_NODES,
    )
