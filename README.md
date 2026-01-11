# Azure Zero Trust Architecture

This repository contains the Infrastructure as Code (IaC) and policy definitions to deploy a **Zero Trust** environment in Azure.

## 📌 Core Components

This solution implements the Zero Trust pillars (Verify Explicitly, Use Least Privileged Access, Assume Breach) using:

1.  **Identity (Microsoft Entra ID)**
    - Conditional Access Policies (Signal-based access)
    - Privileged Identity Management (PIM) for Just-In-Time (JIT) access.

2.  **Network Security**
    - **Azure Firewall Premium**: Inspects traffic (IDPS, TLS inspection).
    - **NSGs**: Micro-segmentation with "Deny All" default posture.
    - **Private Endpoints**: Secure connectivity to PaaS services (Storage, SQL, etc.) avoiding public internet.

3.  **Observability & Threat Detection**
    - **Log Analytics Workspace**: Centralized log repository.
    - **Microsoft Sentinel**: SIEM/SOAR for threat detection and automated response.

## 📂 Repository Structure

```text
/
├── .github/workflows/   # CI/CD Pipelines
├── infra/               # Bicep IaC Code
│   ├── modules/         # Reusable modules (Network, Security, etc.)
│   └── main.bicep       # Main deployment orchestrator
├── scripts/             # PowerShell scripts for Entra/PIM
└── README.md
```

## 🚀 Getting Started

### Prerequisites
- Azure Subscription
- Azure CLI / Bicep CLI
- GitHub Actions permissions to deploy to Azure (OIDC recommended)

### Deployment

1.  **Login to Azure**
    ```bash
    az login
    ```

2.  **Deploy Infrastructure**
    ```bash
    az deployment sub create --location eastus --template-file infra/main.bicep
    ```
