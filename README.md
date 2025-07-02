# ☁️👨‍💻 Google Cloud Platform Hands-on Lab

Welcome to the Google Cloud Hands-on Lab repository! This collection of labs cover multiple topic areas such as Generative AI, AI, Data Analytics and Data Management, designed to give you hands-on experiences with the platform so that you can quickly get started on GCP. 

## 🚀 Getting Started
To get started, clone this repository to your machine (e.g. Vertex Workbench). 
```bash
    git clone https://github.com/angwanqi/gcp-ai-bootcamp.git
    cd gcp-ai-bootcamp
 ```
## 🔧 Status of the Labs
| Lab Name | Status |
| --- | --- |
| [Introduction to Generative AI](intro-to-genai)  | ✅ Completed |
| [Conversational Agents - Low Code](convo-agent) | ✅ Completed |
| [LLM Tuning](llm-tuning) | ✅ Completed |
| [Data Analytics Platform](data-analytics) | ✅ Completed |
| [AI with AlloyDB](alloydb-ai) | ✅ Completed |
| [Multi Agent Systems with ADK](agents) | ✅ Completed |
| [AI Application on Cloud Run](cloudrun) | ✅ Completed |
| [Vertex AI Platform 101](vertex-101) | ✅ Completed |

## 🤖 List of the Labs
1. Introduction to Generative AI
    - [Gemini - Multimodal Prompting](intro-to-genai/intro_gemini_2_0_flash.ipynb)
    - [Open Source Models - Stable Diffusion](intro-to-genai/model_garden_sdxl.ipynb)
    - [Imagen 3 - Image Generation](intro-to-genai/Imagen%20Console%20Lab.pdf)
2. Low-code Agents
    - [Building a Travel Agent with Conversational Agents](convo-agent/travel_convo_agent.md)
3. LLM Tuning
    - Gemini Tuning ([via Console](https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini-use-supervised-tuning#console)) with this [sample dataset](https://cloud.google.com/vertex-ai/generative-ai/docs/models/tune_gemini/text_tune#sample-datasets)
    - Gemma 3 Tuning ([via notebook](llm-tuning/gemma3_finetuning_on_vertex.ipynb))
    - [OSS Model (Llama 3) Tuning](llm-tuning/llama3_finetuning_on_vertex.ipynb)
4. Data Analytics Platform
    - [Predict Visitor Purchases with BigQuery Machine Learning](data-analytics/bigquery-ml)
    - [Analyzing Large Datasets in BigQuery](data-analytics/bigquery)
5. AI with AlloyDB
    - [Vector Search with AlloyDB](alloydb-ai/vector_search_with_alloydb.md)
6. Multi Agent Systems with Agent Development Kit (ADK)
    - [ADK 101](https://github.com/analyticsrepo01/adk_training_002/blob/main/ADK_Training_main.ipynb) 
7. AI Application on Cloud Run
    - [Working with Gemma 3 locally](cloudrun/gemma3_4b_with_hugging_face.ipynb)
    - [Serving Gemma 3 with vLLM on Cloud Run](cloudrun/deploy_vllm_cloudrun.md)
8. Vertex AI Platform 101
    - [End to end training on Vertex platform](vertex-101)
    - [AutoML Vision - Image Classification](automl)


## 🧱 Repository Structure
```bash
.
├── alloydb-ai
├── assignments
├── automl
├── cloudrun
├── convo-agent
├── data-analytics
├── intro-to-genai
├── llm-tuning
├── vertex-101
├── README.md
├── pyproject.toml
├── requirements.txt
└── uv.lock
```

## Disclaimers
This is not an officially supported Google product. This project is intended for demonstration purposes only.
