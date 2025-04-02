# Cloud AI Takeoff - Terraform Environment Setup

This directory contains Terraform configurations for setting up the infrastructure required for the Cloud AI Takeoff project on Google Cloud Platform (GCP). The setup is divided into several stages, each in its own subdirectory, allowing for modularity and easier management.

## Project Structure

The Terraform configuration is organized into the following stages:

1.  **01-base-infra:** Sets up the foundational infrastructure, including:
    *   Project-level settings.
    *   Virtual Private Cloud (VPC) network.
    *   Subnets in multiple regions.
    *   Enabling core Google Cloud APIs.
    *   Granting project owner roles to specified users.
    *   Randomly selecting a region and zones for resource deployment.

2.  **02-workbench-n-bq:** Configures resources related to Vertex AI Workbench and BigQuery:
    *   Enables BigQuery-related APIs.
    *   Creates BigQuery reservations for managing slot capacity.
    *   Provisions multiple Vertex AI Workbench instances with specific configurations (machine type, disk size, network settings, etc.).
    *   Sets up secure boot, integrity monitoring, and vTPM for the workbench instances.

3.  **03-vertex-ai:** Deploys resources for Vertex AI:
    *   Enables Vertex AI and other related APIs.
    *   Creates a Vertex AI persistent resource using a custom script executed via the `gcloud` CLI.
    *   The persistent resource is created and deleted using the `persistent-resource.sh` script.

4.  **04-alloydb:** Sets up an AlloyDB for PostgreSQL cluster:
    *   Enables AlloyDB and related APIs.
    *   Allocates a private IP range for AlloyDB.
    *   Establishes a service networking connection between the VPC and the AlloyDB service.
    *   Creates an AlloyDB cluster with continuous and automated backups.
    *   Provisions a primary AlloyDB instance.
    *   Configures firewall rules to allow internal traffic to the AlloyDB instance.
    *   Creates AlloyDB users with IAM integration.

## Dependencies

`01-base-infra` is a pre-req for subsequent stages. I.e. `02-workbench-n-bq`, `03-vertex-ai`, and `04-alloydb` depend on the outputs of `01-base-infra`.

## Key Components

### Common Locals

Several common local variables are used across the stages, including:

*   `project_id`: The Google Cloud project ID.
*   `region`: The primary region for resource deployment.
*   `vpc_id`: The ID of the VPC network.
*   `random_region`: A randomly selected region.
*   `random_zone_list`: A list of randomly selected zones.
*   `resource_prefix`: A prefix for resource names.
*   `project_users`: A list of users with project access.

These are either variables or outputs from the `01-base-infra` stage.

### Remote State

Each stage uses Terraform's remote state feature to access outputs from the `01-base-infra` stage. This is done using the `terraform_remote_state` data source.

## How to Use

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
    Run this command in each subdirectory (e.g., `01-base-infra`, `02-workbench-n-bq`, etc.).

2.  **Plan:**
    ```bash
    terraform plan
    ```
    Review the changes that Terraform will make.

3.  **Apply:**
    ```bash
    terraform apply
    ```
    Create the resources.

4.  **Destroy:**
    ```bash
    terraform destroy
    ```
    Delete the resources.

**Important:** Apply the stages in order, starting with `01-base-infra`.

