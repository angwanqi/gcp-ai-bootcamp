import yaml
import argparse
import requests
from google.cloud import aiplatform as vertex_ai

from trainer.utils import gcs_read, VertexConfig


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ds", required=True)
    parser.add_argument("--ps", required=False)
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

    dataset = vertex_ai.TabularDataset(
        f"projects/{vertex_config.PROJECT_ID}/locations/{vertex_config.REGION}/datasets/{args.ds}"
    )
    job = vertex_ai.CustomContainerTrainingJob(
        display_name=vertex_config.JOB_NAME,
        container_uri=vertex_config.IMAGE_URI,
        model_serving_container_image_uri=vertex_config.MODEL_SERVING_IMAGE_URI,
    )

    model = job.run(
        dataset=dataset,
        model_display_name=f"{vertex_config.MODEL_NAME}_xgb_{vertex_config.ID}",
        replica_count=vertex_config.REPLICA_COUNT,
        persistent_resource_id=args.ps,
    )
