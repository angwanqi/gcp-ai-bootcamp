# Build a Patent Search App with AlloyDB, Vector Search & Vertex AI!

## Overview
Across different industries, Patent research is a critical tool for understanding the competitive landscape, identifying potential licensing or acquisition opportunities, and avoiding infringing on existing patents. 

Patent research is vast and complex. Sifting through countless technical abstracts to find relevant innovations is a daunting task. Traditional keyword-based searches are often inaccurate and time-consuming. Abstracts are lengthy and technical, making it difficult to grasp the core idea quickly. This can lead to researchers missing key patents or wasting time on irrelevant results.

The secret sauce behind this revolution lies in Vector Search. Instead of relying on simple keyword matching, vector search transforms text into numerical representations (embeddings). This allows us to search based on the meaning of the query, not just the specific words used. In the world of literature searches, this is a game-changer. Imagine finding a patent for a "wearable heart rate monitor" even if the exact phrase isn't used in the document.

### Objective

In this codelab,  we will work towards making the process of searching for patents faster, more intuitive, and incredibly precise by leveraging AlloyDB, pgvector extension, and in-place Gemini 1.5 Pro, Embeddings and Vector Search.

### What you'll build

As part of this lab, you will:

1. Work with an AlloyDB instance and load Patents Public Dataset data
2. Enable pgvector and generative AI model extensions in AlloyDB
3. Generate embeddings from the insights
4. Perform real time Cosine similarity search for user search text

The following diagram represents the flow of data and steps involved in the implementation.

<TODO: Insert diagram here>
     High level diagram representing the flow of the Patent Search Application with AlloyDB

## Before you begin

### Head to your project
<TODO: Add steps to access assigned GCP project>

## Verify that your AlloyDB database exists
<TODO: Add steps to access AlloyDB Cluster>

In this AlloyDB cluster, you have an instance and you will need to create a table where the patent dataset will be loaded.

### Create a table 
You can create a table using the DDL statement below in the AlloyDB Studio: 

```
CREATE TABLE patents_data ( id VARCHAR(25), type VARCHAR(25), number VARCHAR(20), country VARCHAR(2), date VARCHAR(20), abstract VARCHAR(300000), title VARCHAR(100000), kind VARCHAR(5), num_claims BIGINT, filename VARCHAR(100), withdrawn BIGINT) ;
```

### Enable Extensions
For building the Patent Search App, we will use the extensions pgvector and google_ml_integration. The  [pgvector extension](https://github.com/pgvector/pgvector#readme) allows you to store and search vector embeddings. The  [google_ml_integration](https://cloud.google.com/alloydb/docs/vertex-ai/invoke-predictions) extension provides functions you use to access Vertex AI prediction endpoints to get predictions in SQL.  [Enable](https://cloud.google.com/alloydb/docs/reference/extensions#enable) these extensions by running the following DDLs:

```
CREATE EXTENSION vector;
CREATE EXTENSION google_ml_integration;
```

### Grant Permission
Run the below statement to grant execute on the "embedding" function:

```
GRANT EXECUTE ON FUNCTION embedding TO postgres;
```

### Grant Vertex AI User ROLE to the AlloyDB service account 
From Google Cloud IAM console, grant the AlloyDB service account (that looks like this: service-&lt;&lt;PROJECT_NUMBER&gt;&gt;@gcp-sa-alloydb.iam.gserviceaccount.com) access to the role "Vertex AI User". PROJECT_NUMBER will have your project number.

Alternatively, you can also grant the access using gcloud command:

```
PROJECT_ID=$(gcloud config get-value project)


gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:service-$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")@gcp-sa-alloydb.iam.gserviceaccount.com" \
--role="roles/aiplatform.user"
```

### Alter the table to add a Vector column for storing the Embeddings

Run the below DDL to add the abstract_embeddings field to the table we just created. This column will allow storage for the vector values of the text:

```
ALTER TABLE patents_data ADD column abstract_embeddings vector(768);
```


## Load patent data into the database
The  [Google Patents Public Datasets](https://console.cloud.google.com/launcher/browse?q=google%20patents%20public%20datasets&filter=solution-type:dataset&_ga=2.179551075.-653757248.1714456172) on BigQuery will be used as our dataset. We will use the AlloyDB Studio to run our queries. The  [alloydb-pgvector](https://github.com/AbiramiSukumaran/alloydb-pgvector) repository includes the  [`insert_into_patents_data.sql`](https://github.com/AbiramiSukumaran/alloydb-pgvector/blob/main/insert_scripts.sql) script we will run to load the patent data.

1. In the Google Cloud console, open the  [**AlloyDB**](https://console.cloud.google.com/alloydb) page.
2. Select your newly created cluster and click the instance.
3. In the AlloyDB Navigation menu, click **AlloyDB Studio**. Sign in with your credentials.
4. Open a new tab by clicking the **New tab** icon on the right.
5. Copy the `insert` query statement from the `insert_into_patents_data.sql` script mentioned above to the editor. You can copy 50-100 insert statements for a quick demo of this use case.
6. Click **Run**. The results of your query appear in the **Results** table.


## Create Embeddings for patents data
First let's test the embedding function, by running the following sample query:

```
SELECT embedding( 'textembedding-gecko@003', 'AlloyDB is a managed, cloud-hosted SQL database service.');
```

This should return the embeddings vector, that looks like an array of floats, for the sample text in the query. Looks like this:

<TODO: Insert image>

### Update the abstract_embeddings Vector field

Run the below DML to update the patent abstracts in the table with the corresponding embeddings:

```
UPDATE patents_data set abstract_embeddings = embedding( 'textembedding-gecko@003', abstract);
```


## Perform Vector search
Now that the table, data, embeddings are all ready, let's perform the real time Vector Search for the user search text. You can test this by running the query below:

```
SELECT id || ' - ' || title as literature FROM patents_data ORDER BY abstract_embeddings <=> embedding('textembedding-gecko@003', 'A new Natural Language Processing related Machine Learning Model')::vector LIMIT 10;
```

In this query,

1. The user search text is: "A new Natural Language Processing related Machine Learning Model".
2. We are converting it to embeddings in the embedding() method using the model: textembedding-gecko@003.
3. "&lt;=&gt;" represents the use of the COSINE SIMILARITY distance method.
4. We are converting the embedding method's result to vector type to make it compatible with the vectors stored in the database.
5. LIMIT 10 represents that we are selecting the 10 closest matches of the search text.

Below is the result:

<TODO: Insert image>

As you can observe in your results, the matches are pretty close to the search text.

## Congratulations



Congratulations! You have successfully performed a similarity search using AlloyDB, pgvector and Vector search. By combining the capabilities of  [AlloyDB](https://cloud.google.com/alloydb/docs),  [Vertex AI](https://cloud.google.com/vertex-ai/docs/start/introduction-unified-platform), and  [Vector Search](https://cloud.google.com/alloydb/docs/ai/work-with-embeddings), we've taken a giant leap forward in making literature searches accessible, efficient, and truly meaning-driven.

