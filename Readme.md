
# Terraform Kubernetes Infrastructure Setup

This repository contains Terraform configurations to provision and manage a Kubernetes environment on **Azure Kubernetes Service (AKS)**. It sets up namespaces, secrets, deployments, and services for multiple microservices used in this project.

---

## Features

- **Terraform Cloud Integration**: Remote state management with Terraform Cloud.
- **Azure Kubernetes Service (AKS)**: Connects to an existing AKS cluster.
- **Kubernetes Provider**: Manages Kubernetes resources via Terraform.
- **Namespace Management**: Dedicated `ms` namespace for microservices.
- **Secrets Management**: Securely stores SMTP credentials as Kubernetes Secrets.
- **Service Deployments**: Configures multiple microservices with appropriate services.

---

## Prerequisites

Make sure you have the following installed:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Azure CLI (`az`) configured and authenticated
- Access to an existing AKS cluster
- Terraform Cloud account and organization configured

---

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone <your-repo-url>
   cd <repo-directory>
   ```

2. **Login to Terraform Cloud**
   ```bash
   terraform login
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review the Plan**
   ```bash
   terraform plan
   ```

5. **Apply Changes**
   ```bash
   terraform apply
   ```

---

## Kubernetes Resources Managed

### 1. Namespace
- **Namespace:** `ms`
- This is where all deployments and services are created.

### 2. Secrets
- **Secret Name:** `secretsvc`
- Stores sensitive SMTP credentials for the `emailservice`.

Example snippet:
```hcl
resource "kubernetes_secret" "secret" {
  metadata {
    name      = "secretsvc"
    namespace = kubernetes_namespace.ns.metadata[0].name
  }
  data = {
    "SMTP_PASS" = "<base64-encoded-password>"
  }
}
```
Encode password:
```bash
echo -n 'your-app-password' | base64
```

### 3. Deployments and Services

#### a. **Email Service**
- **Deployment Name:** `emailservice`
- **Image:** `aditya090/projectk8s:msemailsvc`
- **Description:** Handles email notifications and communication for the system.
- **Service:** Exposes email service internally within the namespace.

#### b. **Shipping Service**
- **Deployment Name:** `shippingservice`
- **Image:** `aditya090/projectk8s:msshippingsvc`
- **Description:** Manages shipping operations, delivery tracking, and status updates.
- **Service:** ClusterIP service for internal communication.

#### c. **Frontend Service**
- **Deployment Name:** `frontend`
- **Image:** `aditya090/projectk8s:msfrontend`
- **Description:** Main frontend of the application, serves as the entry point for users.
- **Service:** Exposed via a LoadBalancer to make it accessible externally.

#### d. **Payment Service**
- **Deployment Name:** `paymentservice`
- **Image:** `aditya090/projectk8s:mspaymentsvc`
- **Description:** Processes and manages all payment transactions.
- **Service:** Internal ClusterIP service for secure backend communication.

#### e. **Recommendation Service**
- **Deployment Name:** `recommendationservice`
- **Image:** `aditya090/projectk8s:msrecommendationsvc`
- **Description:** Provides recommendations to users based on behavior and analytics.
- **Service:** Internal service for API-based recommendations.

#### f. **Product Catalog Service**
- **Deployment Name:** `productcatalogservice`
- **Image:** `aditya090/projectk8s:msproductcatalogsvc`
- **Description:** Stores and retrieves product catalog details for the system.
- **Service:** Internal service for other microservices to fetch product details.

#### g. **Cart Service**
- **Deployment Name:** `cartservice`
- **Image:** `aditya090/projectk8s:mscartsvc`
- **Description:** Handles cart functionality for users.
- **Service:** Internal service for cart operations.

---

## Destroying the Infrastructure

To destroy the created resources (namespace, secrets, deployments, services):

```bash
terraform destroy
```

> ⚠️ **Important:** Destroying the infrastructure will also delete secrets from the cluster. Backup sensitive data before running `terraform destroy`.

---

## Troubleshooting

- **Invalid Credentials (535 error):**
  Ensure SMTP username/password is correct and base64 encoded.

- **kubectl Access Issues:**
  Run `az aks get-credentials` to refresh kubeconfig access.

---

## Architecture Overview

```text
+-------------------+
|   Terraform Cloud |
+-------------------+
          |
          v
+-------------------+
| Azure AKS Cluster |
+-------------------+
          |
          v
+-------------------------------------------------------------+
| Namespace: ms                                               |
|                                                             |
| +-----------+   +-------------+   +-------------+           |
| | Frontend  |<->| Recommendation|<->| Product   |           |
| |  Service  |   |   Service    |   | Catalog   |           |
| +-----------+   +-------------+   +-------------+           |
|      |                    |                 |               |
|  +-----------+      +-----------+     +-----------+         |
|  | Cart Svc  |      | Shipping  |     | Payment   |         |
|  +-----------+      +-----------+     +-----------+         |
|                                                             |
|                    +-------------+                         |
|                    | Email Svc   |                         |
|                    +-------------+                         |
+-------------------------------------------------------------+
```

---

## Author
- **Aditya** - Microservices Terraform Infrastructure Project
