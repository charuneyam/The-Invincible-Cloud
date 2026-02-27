# The Invincible Cloud

## Project Overview

**The Invincible Cloud** is a sophisticated cloud engineering project designed to architect and implement an **Automated, Highly Available Container Platform** that spans two distinct public cloud environments (specifically AWS as the primary, and GCP or Azure as the secondary).

The core mission is to solve the "nightmare scenario" where a regional cloud outage causes total application downtime. By deploying identical clusters on separate providers, the system ensures near-zero downtime, high performance, and true vendor independence.

---

## Core Architecture and Methodology

The project utilizes a **"Warm Standby" Disaster Recovery (DR)** architecture. This involves:

- **Multi-Cloud Deployment:** Provisioning production-ready Kubernetes clusters on a primary cloud (AWS EKS) and a secondary cloud (GCP GKE or Azure AKS).
- **Infrastructure as Code (IaC):** Using a single Terraform repository with provider aliases to codify and manage the infrastructure for both clouds simultaneously.
- **Real-Time Synchronization:** Implementing continuous data synchronization using PostgreSQL Logical Replication to ensure the standby cluster has up-to-date stateful data.
- **Multi-Cluster Load Balancing (MCLB):** Configuring a global traffic management system to automatically route user traffic and facilitate seamless failover between clouds.

---

## Technical Stack

The project employs a modern "DevOps Arsenal" to achieve its goals:

| **Component**        | **Technology**               | **Role in Project**                                                           |
| -------------------- | ---------------------------- | ----------------------------------------------------------------------------- |
| **IaC**              | **Terraform**                | Provisioning resources across AWS and Azure/GCP.                              |
| **Orchestration**    | **Python (Boto3/Azure SDK)** | Handling autonomous failover logic and API integration.                       |
| **Containerization** | **Kubernetes (EKS/AKS/GKE)** | Hosting active and standby application clusters.                              |
| **Database**         | **PostgreSQL**               | Managing advanced logical replication for low Recovery Point Objective (RPO). |
| **CI/CD**            | **GitHub Actions**           | Automating the build, push, and deployment of containers to both clusters.    |

---

## Key Project Objectives

The team aims to deliver five specific outcomes:

1. **Multi-Cloud Provisioning:** Use Terraform to configure EKS and GKE/AKS clusters.
2. **Application Portability:** Ensure deployment manifests (YAML) function identically on both cloud environments.
3. **Load Balancing:** Implement an MCLB (e.g., EC2 Load Balancer) for cross-cloud traffic direction.
4. **Automated Data Persistence:** Strategy for keeping stateful application data consistent across clouds.
5. **Zero-Downtime Validation:** Conduct automated tests simulating a primary cluster failure to confirm successful traffic redirection.
