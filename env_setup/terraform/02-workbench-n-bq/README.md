# Workbench and BigQuery Setup (02-workbench-n-bq)

This Terraform module (`02-workbench-n-bq`) is responsible for deploying and configuring Vertex AI Workbench instances and BigQuery resources within a Google Cloud project. It builds upon the base infrastructure defined in the `01-base-infra` module.

## Overview

This module performs the following actions:

1.  **Enables Necessary APIs:** Activates the required Google Cloud APIs for BigQuery and related services.
2.  **Creates BigQuery Reservation:** Sets up a BigQuery reservation to manage slot capacity and optimize query performance.
3.  **Deploys Vertex AI Workbench Instances:** Creates multiple Vertex AI Workbench instances, configured for secure and efficient operation.

## Prerequisites

*   **Terraform:** Terraform must be installed and configured.
*   **Google Cloud Project:** A Google Cloud project must be available.
*   **Base Infrastructure (01-base-infra):** The `01-base-infra` module must be deployed first, as this module depends on its outputs.
* **Authentication:** You must be authenticated to your Google Cloud project using `gcloud auth application-default login` or similar.

## Files

*   **`main.tf`:** Contains the main Terraform configuration for creating the resources.
*   **`variables.tf`:** Defines the input variables for the module (though currently commented out, they are used as outputs from the base module).

## Resources Created

*   **Google Project Services:**
    *   `bigquery.googleapis.com`
    *   `bigquerydatatransfer.googleapis.com`
    *   `bigqueryreservation.googleapis.com`
    *   `bigquerystorage.googleapis.com`
*   **BigQuery Reservation:**
    *   Name: `${resource_prefix}-bq-reservation`
    *   Location: Specified region
    *   Slot Capacity: 100 (configurable)
    * Edition: ENTERPRISE
*   **Vertex AI Workbench Instances:**
    *   Number: 3
    *   Name: `${resource_prefix}-workbench-{index}` (e.g., `ai-takeoff-workbench-0`, `ai-takeoff-workbench-1`, `ai-takeoff-workbench-2`)
    *   Location: Region and random zone from the base module.
    *   Machine Type: `e2-standard-8`
    *   Boot Disk: 150 GB, `PD_BALANCED`
    *   Data Disk: 100 GB, `PD_BALANCED`
    *   Shielded Instance: Secure Boot, Integrity Monitoring, and vTPM enabled.
    *   Network: Private network (no public IP), connected to the VPC created in `01-base-infra`.

## Usage

1.  **Navigate to the Directory:**
    ```bash
    cd 02-workbench-n-bq
    ```

2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

3.  **Review the Plan:**
    ```bash
    terraform plan
    ```

4.  **Apply the Configuration:**
    ```bash
    terraform apply
    ```

5. **Destroy the configuration**
    ```bash
    terraform destroy
    ```

## Configuration Details

### `main.tf`

*   **Remote State:** Uses `terraform_remote_state` to retrieve outputs from the `01-base-infra` module, including:
    *   `project_id`
    *   `region`
    *   `vpc_id`
    *   `random_region`
    *   `random_zone_list`
    *   `resource_prefix`
    *   `project_users`
*   **Local Variables:** Defines local variables based on the remote state outputs.
*   **API Enablement:** Uses `google_project_service` to enable the required BigQuery APIs.
*   **BigQuery Reservation:** Uses `google_bigquery_reservation` to create a reservation with a specified slot capacity, edition, and autoscale settings.
*   **Vertex AI Workbench Instances:** Uses `google_workbench_instance` to create multiple instances with defined configurations, including machine type, disk sizes, shielded instance settings, and network connectivity.

### `variables.tf`

*   This file is currently mostly commented out, as the variables are being passed from the base module. It is kept for potential future use.

## Outputs

This module does not define any outputs, as its primary purpose is to create resources. The outputs from the `01-base-infra` module are used as inputs.
