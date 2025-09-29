# Snowflake Monitoring on Azure

[![Deploy](https://github.com/minchev91/snowflake-events-monitoring/actions/workflows/deploy.yml/badge.svg)](https://github.com/minchev91/snowflake-events-monitoring/actions)

## 📌 Overview
`snowflake-events-monitoring` is a **standalone monitoring solution** for Snowflake, deployed as an **Azure Function App**.  
It collects logs from your Snowflake environment (ADMIN.UTILS.EVENT_logs) and integrates with Azure monitoring tools, making it easy to track all events in your snowflake account with the correct severity levels. 

This solution is loosely based on an old project that was focused on query history and security logs - [Snowflake log ingestion via Azure Functions](https://medium.com/@enleak/snowflake-log-ingestion-via-azure-functions-b7e575ce4ee2); the current implementation has Function app rewritten completely, as well as a reworked deployment approach described below:

- **Terraform** → Infrastructure provisioning (Function App, Storage, Key Vault, App Insights, etc.)
- **Azure Functions** → Serverless runtime for Snowflake monitoring logic
- **Azure Key Vault** → Secure management of Snowflake credentials and configuration
- **GitHub Actions** → CI/CD pipeline for end-to-end deployment

---

## 🏗 Architecture
```
GitHub Repo
   └── GitHub Actions CI/CD
         ├── Terraform → Provisions Azure Resources
         ├── Azure Key Vault → Stores secrets
         ├── Azure Function App → Runs monitoring code
         └── App Insights / Logs → Observability
```

---

## 📂 Repository Structure
```
sf-mntr/
│
├── .github/workflows/       # CI/CD pipeline
│   └── deploy.yml
│
├── terraform/               # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── versions.tf
│
├── function/                # Azure Function App code
│   ├── __init__.py
│   ├── function.json
│   ├── requirements.txt
│   ├── host.json
│   └── local.settings.json  # (local dev only, excluded from git)
│
└── README.md
```

---

## 🚀 Deployment

### 1. Prerequisites
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.8
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with permissions to create resources
- Snowflake account & credentials

### 2. Setup GitHub Secrets
In your repository settings, configure the following secrets:

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | JSON output from `az ad sp create-for-rbac` |
| `SNOWFLAKE_ACCOUNT` | Your Snowflake account identifier |
| `SNOWFLAKE_USER` | Snowflake username |
| `SNOWFLAKE_PASSWORD` | Snowflake password (sensitive) |
| `SNOWFLAKE_WAREHOUSE` | Target warehouse |
| `SNOWFLAKE_DATABASE` | Target database |
| `SNOWFLAKE_SCHEMA` | Target schema |
| `SNOWFLAKE_ROLE` | (Optional) Role to assume |

### 3. Trigger Deployment
Push to the `main` branch:
```bash
git push origin main
```

This will:
1. Run Terraform to provision all Azure resources.
2. Store Snowflake credentials in **Key Vault**.
3. Configure the Function App with **Key Vault references**.
4. Deploy the function code automatically.

---

## ⚙️ Local Development
You can run the function locally with the [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local):

```bash
cd function
pip install -r requirements.txt
func start
```

For local testing, create a `local.settings.json` (not committed to git):

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "SNOWFLAKE_ACCOUNT": "xxx",
    "SNOWFLAKE_USER": "xxx",
    "SNOWFLAKE_PASSWORD": "xxx",
    "SNOWFLAKE_WAREHOUSE": "xxx",
    "SNOWFLAKE_DATABASE": "xxx",
    "SNOWFLAKE_SCHEMA": "xxx",
    "SNOWFLAKE_ROLE": "xxx"
  }
}
```

---

## 📊 Monitoring
The deployed Function App integrates with:
- **Azure Application Insights** → Logs & metrics
- **Azure Monitor** → Alerts and dashboards (optional extension)
- **Log Analytics Workspace** (optional) for deeper queries

---

## 🛠 Roadmap
- [ ] Add alerting via Azure Monitor
- [ ] Add dashboards for Snowflake cost & performance
- [ ] Support containerized deployment option
- [ ] Extend to multi-environment setup (dev/test/prod)

---

## 🤝 Contributing
Contributions, ideas, and feature requests are welcome!  
Please open an [issue](../../issues) or submit a pull request.

---

## 📜 License
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
