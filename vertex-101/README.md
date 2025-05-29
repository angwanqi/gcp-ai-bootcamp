## Fraudfinder - A comprehensive lab series on how to build a real-time fraud detection system on Google Cloud.

[Fraudfinder](https://github.com/googlecloudplatform/fraudfinder) FraudFinder is a golden Data to AI workshop to show an end-to-end architecture from raw data to MLOps, through the use case of real-time fraud detection. Fraudfinder is a series of labs to showcase the comprehensive Data to AI journey on Google Cloud, through the use case of real-time fraud detection. Throughout the Fraudfinder labs, you will learn how to read historical payment transactions data stored in a data warehouse, read from a live stream of new transactions, perform exploratory data analysis (EDA), do feature engineering, ingest features into a feature store, train a model using feature store, register your model in a model registry, evaluate your model, deploy your model to an endpoint, do real-time inference on your model with feature store, and monitor your model. Below you will find an image of the overall architecture:

![image](./misc/images/fraudfinder-architecture.png)

## How to use this repo

This repo is organized across various notebooks as:

* [00_v2_ff_labsetup.ipynb](00_v2_ff_labsetup.ipynb)
* [01_exploratory_data_analysis.ipynb](01_exploratory_data_analysis.ipynb)
* [02_feature_engineering_batch.ipynb](02_feature_engineering_batch.ipynb)
* [03_feature_engineering_streaming.ipynb](03_feature_engineering_streaming.ipynb)
* [vertex_ai_lab/](vertex_ai_lab/)
  * [04_experimentation.ipynb](bqml/04_experimentation.ipynb)
  * [05_model_training_xgboost_formalization.ipynb](bqml/05_model_training_xgboost_formalization.ipynb)
  * [06_formalization.ipynb](bqml/06_formalization.ipynb)

## Creating a Google Cloud project

Before you begin, it is recommended to create a new Google Cloud project so that the activities from this lab do not interfere with other existing projects. 

If you are using a provided temporary account, please just select an existing project that is pre-created before the event as shown in the image below.

It is not uncommon for the pre-created project in the provided temporary account to have a different name. Please check with the account provider if you need more clarifications on which project to choose.

If you are NOT using a temporary account, please create a new Google Cloud project and select that project. You may refer to the official documentation ([Creating and Managing Projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)) for detailed instructions.

## Running the notebooks

To run the notebooks successfully, follow the steps below.

### Step 0: Select your Google Cloud project
Please make sure that you have selected a Google Cloud project as shown below:
  ![image](./misc/images/select-project-dasher.png)

### Step 1: Initial setup using Cloud Shell

- Activate Cloud Shell in your project by clicking the `Activate Cloud Shell` button as shown in the image below.
  ![image](./misc/images/activate-cloud-shell.png)

- Once the Cloud Shell has activated, copy the following codes and execute them in the Cloud Shell to enable the necessary APIs, and create Pub/Sub subscriptions to read streaming transactions from public Pub/Sub topics.

- Authorize the Cloud Shell if it prompts you to. Please note that this step may take a few minutes. You can navigate to the [Pub/Sub console](https://console.cloud.google.com/cloudpubsub/subscription/) to verify the subscriptions. 

  ```shell
  gcloud services enable notebooks.googleapis.com
  gcloud services enable cloudresourcemanager.googleapis.com
  gcloud services enable aiplatform.googleapis.com
  gcloud services enable pubsub.googleapis.com
  gcloud services enable run.googleapis.com
  gcloud services enable cloudbuild.googleapis.com
  gcloud services enable dataflow.googleapis.com
  gcloud services enable bigquery.googleapis.com
  gcloud services enable artifactregistry.googleapis.com
  gcloud services enable iam.googleapis.com
  gcloud services enable ml.googleapis.com
  gcloud services enable datacatalog.googleapis.com
  gcloud services enable visionai.googleapis.com
  gcloud services enable composer.googleapis.com
  gcloud services enable dataproc.googleapis.com
  
  gcloud pubsub subscriptions create "ff-tx-sub" --topic="ff-tx" --topic-project="cymbal-fraudfinder"
  gcloud pubsub subscriptions create "ff-tx-for-feat-eng-sub" --topic="ff-tx" --topic-project="cymbal-fraudfinder"
  gcloud pubsub subscriptions create "ff-txlabels-sub" --topic="ff-txlabels" --topic-project="cymbal-fraudfinder"
  
  # Run the following command to grant the Compute Engine default service account access to read and write pipeline artifacts in Google Cloud Storage. Wait for few minutes for some principals creation completion
  PROJECT_ID=$(gcloud config get-value project)
  PROJECT_NUM=$(gcloud projects list --filter="$PROJECT_ID" --format="value(PROJECT_NUMBER)")
  REGION="us-central1"
  ce_roles=(storage.admin pubsub.admin bigquery.admin dataflow.admin dataflow.worker artifactregistry.admin aiplatform.admin run.admin resourcemanager.projectIamAdmin editor iam.serviceAccountUser notebooks.runner)
  for ce_role in ${ce_roles[@]};
    do
      echo "roles/${ce_role}"
      gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${PROJECT_NUM}-compute@developer.gserviceaccount.com"\
        --role="roles/${ce_role}"
  done
  gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com"\
        --role='roles/aiplatform.admin'
  gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:service-${PROJECT_NUM}@gcp-sa-aiplatform.iam.gserviceaccount.com"\
        --role='roles/artifactregistry.writer'
  gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:service-${PROJECT_NUM}@gcp-sa-aiplatform.iam.gserviceaccount.com"\
        --role='roles/storage.objectAdmin'   
  
  gcloud compute networks create ai-takeoff-vpc --enable-ula-internal-ipv6 --subnet-mode=custom
  gcloud compute networks subnets create us-central1 --network=ai-takeoff-vpc --range=10.0.0.0/24 --region=${REGION}
  gcloud compute firewall-rules create fraud-finder-fw-rule --network=ai-takeoff-vpc --allow=tcp:22,tcp:3389,udp,icmp,sctp
  ```

- Override parent's policy: `constraints/compute.vmExternalIpAccess`

#### Step 2: Create a Vertex AI Workbench Instance

- Browse to [Vertex AI Workbench](https://console.cloud.google.com/vertex-ai/workbench/list/instances) page, Click on "**CREATE NEW**" as shown in the image below. You can also click on **ADVANCED OPTIONS** to configure the instance.
  ![image](./misc/images/click-new-notebook.png)
  
- Pick a name (or leave it default), select a location, and `Instance` workbench type is recommended.
  ![image](./misc/images/create-notebook-instance.png)

- The instance will be ready when you see a green tick and can click on "**OPEN JUPYTERLAB**" on the [User-Managed Notebooks page](https://console.cloud.google.com/vertex-ai/workbench/list/instances). It may take a few minutes for the instance to be ready.
  ![image](./misc/images/notebook-instance-ready.png)

#### Step 3: Open JupyterLab
- Click on "**OPEN JUPYTERLAB**", which should launch your Managed Notebook in a new tab.

#### Step 4: Opening a terminal

- Open a terminal via the file menu: **File > New > Terminal**.
  ![image](./misc/images/file-new-terminal.png)
  ![image](./misc/images/terminal.png)
#### Step 5: Cloning this repo

- Run the following code to clone this repo:
  ```
  git clone https://github.com/angwanqi/cloud-ai-takeoff.git
  ```

- You can also navigate to the menu on the top left of the Jupyter Lab environment and click on **Git > Clone a repository**.

- Once cloned, you should now see the **fraudfinder** folder in your main directory.
  ![image](./misc/images/git-clone-on-terminal.png)


#### Step 6: Open the first notebook

- Open the first notebook: `00_environment_setup.ipynb`
  ![image](./misc/images/open-notebook-00.png)

- Follow the instructions in the notebook, and continue through the remaining notebooks. 

 #### Step 7: Create your virtual env kernel (Optional)
 To choose your own Python version, e.g. 3.12, you can create your custom kernel.

 - Install uv
 ```shell
 curl -LsSf https://astral.sh/uv/install.sh | sh
 ```

- Restart the shell and install new python version (we put 3.11.10 and this may affect some package versions if you choose otherwise)
```shell
uv python install 3.12
```

- Create the virtual env and the custom kernel
```shell
cd cloud-ai-takeoff # go back to the home folder where pyproject.toml file locates
uv sync
source .venv/bin/activate
python -m ipykernel install --user --name=vertex-user
```

- Allow hidden file access from jupyter
```
echo "c.ContentsManager.allow_hidden = True" >> /home/jupyter/.jupyter/jupyter_notebook_config.py
sudo service jupyter restart

# check status
sudo service jupyter status
```

- Once done, you can open the jupyter notebook and select the custom kernel `vertex-ai`
  ![image](./misc/images/custom-notebook-kernel.png)