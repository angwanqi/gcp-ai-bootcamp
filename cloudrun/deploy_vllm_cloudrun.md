# Introduction

Large Language Models (LLMs) are changing how we build smart applications. But getting these powerful models ready for real-world use can be tricky. They need a lot of computing power, especially graphics cards (GPUs), and smart ways to handle many requests at once. Plus, you want to keep costs down and your application running smoothly without delays.

This Codelab will show you how to tackle these challenges\! We'll use two key tools:

1. **vLLM**: Think of this as a super-fast engine for LLMs. It makes your models run much more efficiently, handling more requests at once and reducing memory use.

2. **Google Cloud Run**: This is Google's serverless platform. It's fantastic for deploying applications because it handles all the scaling for you – from zero users to thousands, and back down again. Best of all, Cloud Run [now supports GPUs](https://cloud.google.com/run/docs/configuring/services/gpu), which are essential for LLMs\!

Together, vLLM and Cloud Run offer a powerful, flexible, and cost-effective way to serve your LLMs. In this guide, you'll deploy an open model, making it available as a standard web API. 

## **What you'll learn:**

* How to choose the right model size and variant for serving.  
* How to set up vLLM to serve OpenAI-compatible API endpoints.  
* How to containerize the vLLM server with Docker.  
* How to push your container image to Google Artifact Registry.  
* How to deploy the container to Cloud Run with GPU acceleration.  
* How to test your deployed model.

## **What you'll need:**

* A Google Cloud Project with billing enabled.  
* At least one NVIDIA L4 GPU quota for Cloud Run.  
* A Hugging Face Access Token (Create one [here](https://huggingface.co/settings/tokens) if you don’t have it yet)  
* Basic familiarity with Python, Docker, and the command line.

| Note: GPU features in Cloud Run are still in preview, you need to request to increase the GPU quota by following the [guide](https://cloud.google.com/run/docs/configuring/services/gpu#request-quota). |
| :---- |

---

# Environment Setup

Duration: 10:00

## **Create a Google Cloud Project**

This Codelab assumes that you have already created a Google Cloud project with billing enabled. If you don’t have a project yet, follow these steps to create one:

1. **Select or Create a Google Cloud Project**: Navigate to the [Google Cloud Console](https://console.cloud.google.com/). At the top, click the project selector dropdown (next to the Google Cloud logo) and choose an existing project or create a new one.

2. **Enable Billing**: Ensure that billing is enabled for your selected Google Cloud project. You can learn how to check if billing is enabled on a project by following the instructions in the [Google Cloud Billing documentation](https://cloud.google.com/billing/docs/how-to/modify-project).

##  **Configure Cloud Shell**

Now let's make sure you're set up correctly within Cloud Shell, a handy command-line interface directly within Google Cloud Console:

1. **Launch Cloud Shell**: In the upper right corner of your Google Cloud Console, you'll see an icon that looks like a terminal (`>_`). Click on it to activate Cloud Shell.  

2. **Authorize Access**: If prompted, click **Authorize** to grant Cloud Shell the necessary permissions to interact with your Google Cloud project.

3. **Verify Your Account**: Once Cloud Shell has loaded, let's confirm you're using the correct Google Cloud account. Run the following command:

```
gcloud auth list
```

4. **Switch Accounts (If Necessary):** If the active account isn't the one you intend to use for this Codelab, switch to the correct account using this command, replacing `<your_desired_account@example.com>` with your actual email:

```
gcloud config set account <your_desired_account@example.com
```

5. **Confirm Your Project**: Next, let's verify that Cloud Shell is configured to use the correct Google Cloud Project. Run:

```
gcloud config list project
```

6. **Set Your Project (If Necessary)**: If the `project` value is incorrect, set it to your desired project using the following command:

```
gcloud config set project <your-desired-project-id>
```

## **Enable necessary APIs**

To use Google Cloud services like Cloud Run, you must first activate their respective APIs for your project. Running the commands below in the Cloud Shell terminal enables all the services that you will need for this Codelab:

```
gcloud services enable run.googleapis.com 
cloud services enable cloudbuild.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable artifactregistry.googleapis.com
```

# Choosing the right model

Duration: 5:00

You can find many open models on websites like [Hugging Face Hub](https://huggingface.co/docs/hub/en/index) and [Kaggle](https://www.kaggle.com/models). When you want to use one of these models on a service like Google Cloud Run, you need to pick one that fits the resources you have (i.e. NVIDIA L4 GPU).

Beyond just size, remember to consider what the model can actually do. Models aren't all the same; each has its own advantages and disadvantages. For example, some models can handle different types of input (like images and text – known as multimodal capabilities), while others can remember and process more information at once (meaning they have bigger context windows). Often, larger models will have more advanced capabilities like [function calling](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/function-calling#:~:text=Function%20calling%20is%20sometimes%20referred,respond%20to%20the%20user's%20prompt.) and [thinking](https://ai.google.dev/gemini-api/docs/thinking).

It is also important to check if your desired model is supported by the serving tool (vLLM in this case). You can check all the models that are supported by the vLLM [here](https://docs.vllm.ai/en/latest/models/supported_models.html).  
Now, let's explore Gemma 3, which is Google's newest family of openly available Large Language Models (LLMs). Gemma 3 comes in four different scales based on their complexity, measured in **parameters**: 1 billion, 4 billion, 12 billion, and a hefty 27 billion.

For each of these sizes, you'll find two main types:

* A base (pre-trained) version: This is the foundational model that has learned from a massive amount of data.  
* An instruction-tuned version: This version has been further refined to better understand and follow specific instructions or commands.

The larger models (4 billion, 12 billion, and 27 billion parameters) are **multimodal**, which means they can understand and work with both images and text. The smallest 1 billion parameter variant, however, focuses solely on text.

For this Codelab, we'll use **1 billion variants** **of Gemma 3: [gemma-3-1b-it](https://huggingface.co/google/gemma-3-1b-it)**. Using a smaller model also helps you learn how to work with limited resources, which is important for keeping costs down and making sure your app runs smoothly in the cloud.

---

# Environment Variables & Secrets

Duration: 5:00

## **Create an environment file**

Before we proceed, it is a good practice to have all the configurations that you'll use throughout this Codelab in one place. To get started, open your terminal do these steps:

1. **Create a new folder** for this project.  
2. **Navigate into the newly created folder.**  
3. **Create an empty .env** file within this folder (this file will later hold your environment variables)

Here is the command to perform those steps:

```
mkdir vllm-gemma3
cd vllm-gemma3 touch .env
```

| Note: If you are not comfortable with using command line tools like vim or nano, you can use the Cloud Code Editor by clicking on the Open Editor button.  |
| :---- |

Next, copy the variables listed below and paste them into the **.env file** you just created. Remember to replace the placeholder values inside the \<\> brackets with your specific information.

```
PROJECT_ID=<your_project_id>
REGION=<your_region>

MODEL_PROVIDER=google
MODEL_VARIANT=gemma-3-1b-it
MODEL_NAME=${MODEL_PROVIDER}/${MODEL_VARIANT}
AR_REPO_NAME=vllm-gemma3-repo
SERVICE_NAME=${MODEL_VARIANT}-service
IMAGE_NAME=${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO_NAME}/${SERVICE_NAME}
SERVICE_ACC_NAME=${SERVICE_NAME}-sa
SERVICE_ACC_EMAIL=${SERVICE_ACC_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

Once **.env file** is edited and saved, type this command to load those environment variables into the terminal session:

```
source .env
```

You can test whether the variables are successfully loaded or not by echoing one of the variables. For example:

```
echo $SERVICE_NAME
```

If you get the same value as you assigned in the .env file, the variables are loaded successfully.

## **Store a secret on Secret Manager**

For any sensitive data, including access codes, credentials, and passwords, utilizing a secret manager is the recommended approach. 

Before using Gemma 3 models, you must first acknowledge the terms and conditions, as they are gated. Head over to [Hugging Face Hub](https://huggingface.co/google/gemma-3-1b-it) and acknowledge the terms and conditions. 

| Note: If you do not have a Hugging Face Access Token yet, create one [here](https://huggingface.co/settings/tokens). You will be needing it later. |
| :---- |

Once you have the Access Token, head over to Secret Manager page, click on **\+Create Secret** button, fill up these information:

* **Name**: HF\_TOKEN  
* **Secret Value**: \<your\_hf\_access\_token\>

Click the **Create Secret** button once you are done. You should now have the Hugging Face Access Token as a secret on **Google Cloud Secret Manager**.

You can test your access to the secret by executing the command below, which will retrieve it from Secret Manager:

```
gcloud secrets versions access latest --secret=HF_TOKEN
```

---

# Create a service account

Duration: 5:00

To enhance security and manage access effectively in a production setting, services should operate under dedicated service accounts that are strictly limited to the permissions necessary for their specific tasks.

Run this command to create a service account

```
gcloud iam service-accounts create $SERVICE_ACC_NAME --display-name='Cloud Run vLLM Model Serving SA'
```

The following command attach the necessary permission

```
TO BE ADDED
```

---

# Create an Image on Artifact Registry

Duration: 5:00

This step involves creating a Docker image that includes the model weights and a pre-installed vLLM.

## **Create a docker repository on Artifact Registry**

Let’s create a Docker repository in Artifact Registry for pushing your built images. Run the following command in the terminal:

```
gcloud artifacts repositories create ${AR_REPO_NAME} \   --repository-format docker \   --location ${REGION}
```

## **Storing the model**

Based on the [GPU best practices documentation](https://cloud.google.com/run/docs/configuring/services/gpu-best-practices), you can either store ML models [inside container images](https://cloud.google.com/run/docs/configuring/services/gpu-best-practices#model-container) or [optimize loading them from Cloud Storage](https://cloud.google.com/run/docs/configuring/services/gpu-best-practices#model-storage). Of course, each approach has its own pros and cons. You can read the documentation to learn more about them. For simplicity, we will just store the model in the container image.

## **Create a Docker file**

Create a file named **Dockerfile** and copy the contents below into it:

```
FROM vllm/vllm-openai:latest

ARG MODEL_NAME

ENV HF_HOME=/model-cache
ENV MODEL_NAME=${MODEL_NAME}

RUN --mount=type=secret,id=HF_TOKEN HF_TOKEN=$(cat /run/secrets/HF_TOKEN) \
    huggingface-cli download ${MODEL_NAME}

ENV HF_HUB_OFFLINE=1

EXPOSE 8080

ENTRYPOINT python3 -m vllm.entrypoints.openai.api_server \
    --port ${PORT:-8080} \
    --model ${MODEL_NAME:-google/gemma-3-4b-it} \
    --gpu-memory-utilization ${GPU_MEMORY_UTILIZATION:-0.80} \
    ${MAX_MODEL_LEN:+--max-model-len "$MAX_MODEL_LEN"}

```

## **Build and push the image**

The following commands build a docker image, tag it appropriately, and push the image to the docker repository that was created on the Artifact Registry.

```
docker build \
    --secret id=HF_TOKEN,src=<(gcloud secrets versions access latest --secret=HF_TOKEN) \
    --build-arg MODEL_NAME=${MODEL_NAME} \
    -t ${SERVICE_NAME} .

docker tag ${SERVICE_NAME} ${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO_NAME}/${SERVICE_NAME}

gcloud auth configure-docker ${REGION}-docker.pkg.dev

docker push ${REGION}-docker.pkg.dev/${PROJECT_ID}/${AR_REPO_NAME}/${SERVICE_NAME}

```

---

# Deploy the service

Duration: 5:00

As the docker image is already pushed to the Artifact Registry, it can be deployed to Cloud Run with just one command:

```
gcloud beta run deploy ${SERVICE_NAME} \
    --image=${IMAGE_NAME} \
    --service-account ${SERVICE_ACC_EMAIL} \
    --cpu=8 \
    --memory=32Gi \
    --gpu=1 --gpu-type=nvidia-l4 \
    --region asia-southeast1 \
    --no-allow-unauthenticated \
    --max-instances 3 \
    --no-cpu-throttling
```

---

# Test the service

Duration: 5:00

Run the following command in the terminal to create a proxy, so that you can access the service as it is running in localhost:

```
gcloud run services proxy ${SERVICE_NAME} --region ${REGION}
```

In another terminal window, type this curl command in the terminal to test the connection

```
curl -X POST http://localhost:8080/v1/completions \
-H "Content-Type: application/json" \
-d '{
  "model": "google/gemma-3-1b-it",
  "prompt": "Cloud Run is a ",
  "max_tokens": 128,
  "temperature": 0.90
}'
```

If you see a similar output as below:
```
{"id":"cmpl-e96d05d2893d42939c1780d44233defa","object":"text_completion","created":1746870778,"model":"google/gemma-3-1b-it","choices":[{"index":0,"text":"100% managed Kubernetes service. It's a great option for many use cases.\n\nHere's a breakdown of key features and considerations:\n\n* **Managed Kubernetes:**  This means Google handles the underlying infrastructure, including scaling, patching, and maintenance.  You don't need to worry about managing Kubernetes clusters.\n* **Serverless:**  You only pay for the compute time your application actually uses.  No charges when your code isn't running.\n* **Scalability:**  Cloud Run automatically scales your application based on demand. You can easily scale up or down to handle fluctuating traffic.\n*","logprobs":null,"finish_reason":"length","stop_reason":null,"prompt_logprobs":null}],"usage":{"prompt_tokens":6,"total_tokens":134,"completion_tokens":128,"prompt_tokens_details":null}}
```

---

# Conclusion

Duration: 1:00

Congratulations for making it to the end of this Codelab. You just learned 

* How to choose the right model size and variant for serving.  
* How to set up vLLM to serve OpenAI-compatible API endpoints.  
* How to containerize the vLLM server with Docker.  
* How to push your container image to Google Artifact Registry.  
* How to deploy the container to Cloud Run with GPU acceleration.  
* How to test your deployed model.

Now, feel free to explore deploying some other exciting models, like Llama, DeepSeek, or Qwen, whenever you're ready to dive deeper\!

---

# Clean Up

Duration: 1:00

## **Delete the cloud run service**


## **Delete the docker repository**


## **Delete the service account**
