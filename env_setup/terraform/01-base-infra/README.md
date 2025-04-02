# Cloud AI Takeoff - Base Infrastructure

This directory (`01-base-infra`) contains the Terraform configuration for setting up the foundational infrastructure for the Cloud AI Takeoff project. It handles the creation of a base Google Cloud project, VPC network, subnets, and essential service enablement.

## Overview

The Terraform code in this directory performs the following actions:

*   **Project Setup:** Configures a Google Cloud project with the specified ID.
*   **VPC Network:** Creates a Virtual Private Cloud (VPC) network.
*   **Subnets:** Defines and creates subnets within the VPC across multiple regions.
*   **Service Enablement:** Enables a set of core Google Cloud services required for AI/ML workloads.
*   **IAM Bindings:** Grants project owner roles to specified users.
* **Random Region and Zone Selection:** Randomly selects a region and zone for resource deployment.

## File Structure

*   **`providers.tf`:** Defines the Google and Google Beta providers, specifying the required versions and project/region settings.
*   **`main.tf`:** Contains the core resource definitions, including:
    *   Random region and zone selection.
    *   The `tenant` module, which handles VPC network, subnet, and service enablement.
*   **`output.tf`:** Defines output variables that expose important information about the created resources, such as project ID, VPC ID, subnet IPs, and random region/zone.
*   **`iam.tf`:** Defines IAM bindings to grant project owner roles to specified users.
* **`modules/tenant`:** This directory (not shown in the provided files, but referenced in `main.tf`) contains the module that creates the VPC, subnets, and enables services.

## Key Components

### Providers (`providers.tf`)

*   **`google`:** The primary Google Cloud provider.
*   **`google-beta`:** The Google Cloud beta provider, used for preview features.

### Randomization (`main.tf`)

*   **`random_shuffle.region`:** Randomly selects one region from `us-central1`, `europe-west4`, and `asia-southeast1`.
*   **`random_shuffle.zone`:** Randomly shuffles the zones `a`, `b`, and `c`.

### Tenant Module (`main.tf` and `modules/tenant`)

*   **`module.tenant`:** This module is responsible for creating the VPC network, subnets, and enabling the necessary services.
*   **`network_name`:** The name of the VPC network (e.g., `${var.resource_prefix}-vpc`).
*   **`project_id`:** The ID of the Google Cloud project.
*   **`region`:** The default region for resources.
*   **`project_users`:** A list of users to be granted project owner roles.
*   **`resource_prefix`:** A prefix used for naming resources.
*   **`services`:** A list of Google Cloud services to enable.
*   **`subnets`:** A list of subnet configurations, including name, IP range, region, and private access settings.

### Outputs (`output.tf`)

*   **`project_id`:** The ID of the created project.
*   **`vpc_id`:** The ID of the created VPC network.
*   **`vpc_network_name`:** The name of the created VPC network.
*   **`vpc_subnet_ips`:** The IP ranges of the created subnets.
*   **`project_users`:** The list of project users.
*   **`region`:** The default region.
*   **`resource_prefix`:** The resource prefix.
*   **`random_region`:** The randomly selected region.
*   **`random_zone`:** The randomly selected zone.
*   **`random_zone_list`:** The list of randomly shuffled zones.

### IAM (`iam.tf`)

*   **`google_project_iam_binding.project_owners`:** Grants the `roles/owner` role to the users specified in the `project_users` variable.

### Variables (`../deprecated-terrable/variables.tf`)

*   **`project_id`:** The ID of the Google Cloud project.
*   **`region`:** The default region for resources (defaults to `europe-west4`).
*   **`billing_account`:** The billing account ID.
*   **`project_owners`:** A set of usernames to be granted the project owner role (defaults to an empty set).
*   **`resource_id`:** The default ID for shared resources (defaults to `ai-takeoff`).

## Usage

1.  **Prerequisites:**
    *   Terraform installed.
    *   Google Cloud SDK installed and configured.
    *   A Google Cloud project and billing account.

2.  **Configuration:**
    *   Set the required variables in a `terraform.tfvars` file or through environment variables.
    *   Ensure that the `project_users` variable is set correctly.
    *   Ensure that the `project_id`, `billing_account` and `resource_id` are set correctly.

3.  **Initialization:**
    ```bash
    terraform init
    ```

4.  **Planning:**
    ```bash
    terraform plan
    ```

5.  **Deployment:**
    ```bash
    terraform apply
    ```

6. **Destroy**
    ```bash
    terraform destroy
    ```
