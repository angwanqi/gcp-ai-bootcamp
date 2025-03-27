#/bin/bash
# ways to call: ./build.sh -u us-central1-docker.pkg.dev/fraud-finder-lab/fraudfinder-8wc8m/dask-xgb-classificator:latest -r fraudfinder-8wc8m -l us-central1

while getopts u:r:l: flag
do
    case "$flag" in
        u) IMAGE_URI=${OPTARG};;
        r) IMAGE_REPOSITORY=${OPTARG};;
        l) LOCATION=${OPTARG};;
    esac
done

# IMAGE_URI="us-central1-docker.pkg.dev/fraud-finder-lab/fraudfinder-8wc8m/dask-xgb-classificator:latest"
# IMAGE_REPOSITORY="fraudfinder-8wc8m"
# LOCATION="us-central1"

gcloud artifacts repositories create $IMAGE_REPOSITORY --repository-format=docker --location=$LOCATION --description="FraudFinder Docker Image repository"
gcloud auth configure-docker us-central1-docker.pkg.dev
docker build ./ -t $IMAGE_URI --build-arg project_id=$(gcloud config get-value project)
docker push $IMAGE_URI