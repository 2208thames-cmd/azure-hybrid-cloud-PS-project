# ☁️ Enterprise Azure Hybrid Cloud Platform

Production-Style Azure Networking & Infrastructure Automation with Terraform

![Azure Cloud](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoftazure&logoColor=white) ![Terraform IaC](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white) ![Virtual WAN Networking](https://img.shields.io/badge/Virtual_WAN-Networking-0078D4) ![Entra ID Identity](https://img.shields.io/badge/Entra_ID-Identity-0078D4?logo=microsoftazure&logoColor=white) ![P2S VPN Secure Access](https://img.shields.io/badge/P2S_VPN-Secure_Access-008272) ![NSGs Network Security](https://img.shields.io/badge/NSGs-Network_Security-0078D4) ![Private Endpoints Private Networking](https://img.shields.io/badge/Private_Endpoints-Private_Networking-008272)<br>
![Azure Blob Storage Remote State](https://img.shields.io/badge/Azure_Blob_Storage-Remote_State-0078D4?logo=microsoftazure&logoColor=white) ![Azure RBAC Access Control](https://img.shields.io/badge/Azure_RBAC-Access_Control-0078D4) ![GitHub Actions CI/CD](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions&logoColor=white) ![OIDC Keyless Auth](https://img.shields.io/badge/OIDC-Keyless_Auth-6B4FBB) ![TFLint Validation](https://img.shields.io/badge/TFLint-Validation-5C4EE5) ![Checkov IaC Security](https://img.shields.io/badge/Checkov-IaC_Security-6B4FBB)<br>
![Trivy Security Scanning](https://img.shields.io/badge/Trivy-Security%20Scanning-1904DA?logo=aqua) ![PowerShell Automation](https://img.shields.io/badge/PowerShell-Automation-5391FE?logo=powershell&logoColor=white)

> An enterprise-style Azure hybrid cloud platform demonstrating secure networking, infrastructure-as-code, identity-driven access, environment isolation, remote state management, CI/CD automation, security scanning, and operational troubleshooting.

---

## 🗺️ Architecture Diagram

```mermaid
flowchart LR
    Laptop[Administrator laptop\nAzure VPN Client] -->|Entra ID P2S VPN| P2S[P2S VPN gateway]
    P2S --> Hub[Virtual WAN hub\n10.0.0.0/23]
    Hub --> App[Application spoke VNet\n10.1.0.0/24]
    Hub --> Data[Data spoke VNet\n10.2.0.0/24]
    App --> AppSubnet[App subnet\nNSG protected]
    Data --> DataSubnet[Data subnet\nNSG protected]
    Data --> PESubnet[Private endpoint subnet\nReserved for PaaS endpoints]
    State[Azure Blob remote state\nSeparate account per environment] -. Terraform state .-> IaC[Terraform environments]
    IaC --> Hub
    IaC --> App
    IaC --> Data
```

The Mermaid diagram above reflects the currently implemented topology. A finalized Draw.io or PNG diagram remains a future enhancement.

## Overview

This project demonstrates a reusable Azure infrastructure platform built with Terraform:

- Azure Virtual WAN and Virtual Hub for centralized connectivity
- Application and data spoke workload subnets with NSG protection
- Entra ID-authenticated P2S VPN for administrator access
- Dedicated subnet reserved for future private endpoints
- Separate dev, test, and prod environments with isolated Terraform state
- Governance, managed identity, monitoring, and backup modules
- GitHub Actions validation and OIDC-based plan workflows
- Validation and troubleshooting documentation under `docs/`

The network, VPN control plane, environment isolation, Terraform validation, and plan workflows have been tested. A packet-level workload test remains pending an Azure-side target because the current subscription does not have a suitable VM SKU/quota available in East US.

## Repository Structure

```text
azure-hybrid-cloud-project/
├── .github/
│   └── workflows/
│       ├── terraform-quality.yml
│       ├── terraform-plan.yml
│       ├── terraform-apply.yml
│       ├── terraform-destroy-plan.yml
│       └── terraform-destroy-apply.yml
├── demo/                         # Local-state, sanitized validation entry point
├── docs/
│   ├── troubleshooting.md
│   └── validation/
│       └── test.md
├── environments/
│   ├── dev/                      # Development root module and backend
│   ├── test/                     # Test root module and backend
│   └── prod/                     # Production root module and backend
├── modules/
│   ├── backup/                   # Recovery Services vault and VM policy
│   ├── governance/               # Audit-only environment tag policy
│   ├── identity/                 # User-assigned managed identity
│   ├── monitoring/               # Log Analytics workspace and network diagnostics
│   └── network/                  # Virtual WAN, hub, spokes, VPN, and NSGs
├── scripts/
│   └── Bootstrap-Backend.ps1     # Creates Azure Terraform state storage
├── .gitignore
└── README.md
```

## Getting Started

Choose the path that matches what you want to do:

| Path | Purpose | Terraform state | Best for |
|---|---|---|---|
| Demo | Inspect and validate the Terraform configuration | Local | Recruiters and reviewers |
| Azure environments | Plan or deploy the full platform | Azure Blob Storage | Engineers and real deployments |

### Version Requirements

Terraform and provider version constraints are declared throughout the root configurations and reusable modules:

| Component | Constraint | Applies to |
|---|---|---|
| Terraform CLI | `>= 1.7.0` | All root configurations and modules |
| AzureRM provider | `~> 5.4.0` | Demo, Azure environments, and modules |
| AzureAD provider | `~> 2.53` | Dev, test, and prod environments |

The demo and each Azure environment include a committed `.terraform.lock.hcl` file recording the selected provider versions and checksums. `terraform init` uses those locked selections. Run `terraform init -upgrade` only when intentionally updating providers, and commit the resulting lockfile changes.

### Option 1: Quick Demo

The demo is the fastest way to review the Terraform without configuring Azure remote state.

Prerequisites: Terraform CLI 1.7 or later, Git, and PowerShell 7+ (`pwsh`).

Verify the tools:

```powershell
terraform version
git --version
pwsh --version
```

```powershell
git clone <REPOSITORY_URL>
cd azure-hybrid-cloud-project
cd demo
terraform init
terraform validate
```

To generate a plan, configure Azure CLI authentication and an Azure subscription first. The demo uses local Terraform state and does not require Azure Blob Storage authentication or remote-state RBAC, but the Azure provider still contacts Azure during planning:

```powershell
terraform plan
```

Do not run `terraform apply` or `terraform destroy` against another person's subscription.

### Option 2: Deploy an Azure Environment

Prerequisites: an Azure subscription, Azure CLI, Terraform CLI 1.7 or later, PowerShell 7+, and permission to create the platform resources. Backend bootstrap additionally requires the Azure PowerShell `Az` module:

```powershell
az version
terraform version
pwsh --version
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

1. **Authenticate and select the subscription.** Terraform uses Azure CLI authentication for the configured Blob backend. The bootstrap script uses the separate Azure PowerShell sign-in context.

  ```powershell
  az login
  az account show
  Connect-AzAccount
  ```

  If you have multiple subscriptions, select the intended one in both contexts before continuing:

  ```powershell
  az account set --subscription "<SUBSCRIPTION_ID>"
  Set-AzContext -Subscription "<SUBSCRIPTION_ID>"
  ```

2. **Prepare remote state before initializing Terraform.** The environment backends are configured for separate storage accounts and state keys. The bootstrap script creates a resource group, storage account, and `tfstate` container; it does not grant Blob data permissions or edit Terraform backend files. Run it from the repository root for each backend that needs to be created:

  ```powershell
  .\scripts\Bootstrap-Backend.ps1 -Suffix dev01ahcps -Environment dev
  .\scripts\Bootstrap-Backend.ps1 -Suffix test01ahcps -Environment test
  .\scripts\Bootstrap-Backend.ps1 -Suffix prod03ahcps -Environment prod
  ```

  These suffixes match the backend names documented below. The script is safe to rerun for existing resources. If you use different names, update the corresponding `backend.tf` values to match before running `terraform init`.

  The identity running Terraform also needs the `Storage Blob Data Contributor` role on the state storage account or container. Bootstrap does not assign this role; arrange the assignment separately and allow time for it to take effect.

3. **Initialize and validate development.**

  ```powershell
  cd environments/dev
  terraform init
  terraform validate
  terraform plan
  ```

  Review the plan carefully before applying:

  ```powershell
  terraform apply
  ```

4. **Plan test independently.** Test has its own configuration and remote state:

  ```powershell
  cd ../test
  terraform init
  terraform validate
  terraform plan
  ```

5. **Use the controlled workflow for production.** Production is intentionally separated from dev and test. Use the repository's GitHub Actions workflow rather than treating prod as an unrestricted local deployment. The current repository does not have GitHub-enforced environment reviewer approvals enabled; see [CI/CD](#cicd) for the existing safeguards and limitations.

#### Remote State Troubleshooting

Successfully authenticating to Azure does not automatically grant Terraform permission to access Blob data. Azure separates management-plane access to resources from data-plane access to blobs, and the remote backend requires the latter.

| Error | Meaning | Typical cause |
|---|---|---|
| `401 Unauthorized` | Authentication failed | Missing or invalid authentication |
| `403 AuthorizationPermissionMismatch` | Identity authenticated but lacks data access | Missing Blob data role or role assignment not yet effective |
| `404 Resource Not Found` | Backend resource could not be found | Wrong subscription, resource group, storage account, container, or state key |

Before troubleshooting Terraform itself, verify the active subscription and every backend value. Local development commonly uses Azure CLI authentication; GitHub Actions uses GitHub OIDC through Microsoft Entra ID. These are separate authentication workflows.

The project's core operational lessons are that management-plane access is not Blob data-plane access, authentication is not authorization, and backend configuration must match real resources. Separate state, repeatable bootstrap, environment isolation, validation, and CI/CD help make infrastructure changes reproducible.

## Change Record (2026-09-27)

| Area | Change | Reason |
|---|---|---|
| README and onboarding | Added a project overview, security/tool badges, and separate demo and Azure deployment instructions. | Help reviewers distinguish local configuration validation from a deployment that requires Azure access, remote state, and Blob data permissions. |
| Terraform versions | Changed the AzureRM constraint from `~> 3.100` to `~> 5.4.0` in all root configurations and reusable modules; refreshed the four committed provider lockfiles to select `5.4.0`. | The old constraint allowed only AzureRM 3.x, including the locked `3.117.1`, and excluded the intended 5.4 provider release. |
| Diagnostic settings | Updated the metric block to `enabled_metric` and retained `azurerm_monitor_diagnostic_setting`. | AzureRM 5.4 supports the diagnostic-setting resource but expects the `enabled_metric` block in its schema. |
| Recovery Services vault | Removed the unsupported `soft_delete_enabled` argument. | The AzureRM 5.4 vault resource schema no longer accepts that argument. |
| Version documentation | Documented Terraform and provider constraints and the purpose of committed lockfiles. | Make the supported version ranges and repeatable provider selections clear to contributors. |

### Validation and Independent Testing

The `demo`, `dev`, `test`, and `prod` configurations were initialized with `terraform init -backend=false -upgrade` and passed `terraform validate` using AzureRM `5.4.0`. No Azure-backed plan or apply was run as part of this validation.

A colleague is independently testing the updated configuration against their own Terraform state. This is a separate validation effort; their test results are pending and are not represented here as completed.

## Environment and State Design

Each environment uses a separate Azure Storage account, resource group, container, and state key. This prevents state overlap and creates an independent recovery boundary:

| Environment | Backend resource group | Storage account | Container | State key |
|---|---|---|---|---|
| dev | `rg-tfstate-dev01ahcps` | `sttfstatedev01ahcps` | `tfstate` | `dev.terraform.tfstate` |
| test | `rg-tfstate-test01ahcps` | `sttfstatetest01ahcps` | `tfstate` | `test.terraform.tfstate` |
| prod | `rg-tfstate-prod03ahcps` | `sttfstateprod03ahcps` | `tfstate` | `prod.terraform.tfstate` |

The `ahcps` suffix makes the storage account names globally unique while preserving the environment identifiers `dev01`, `test01`, and `prod03`. Separate storage accounts were chosen because they provide a clearer security and recovery boundary than sharing one account for every environment.

## Backend Protection

The backend bootstrap script configures the following settings:

- StorageV2 account
- Standard LRS redundancy
- HTTPS and TLS 1.2
- Blob public access disabled
- Dedicated `tfstate` container

For production use, enable and verify Blob versioning, blob soft delete, container soft
delete, and change feed on each state storage account.

Authenticate to Azure in PowerShell:

```powershell
Connect-AzAccount
az login
```

Create backend storage separately for each environment:

```powershell
.\scripts\Bootstrap-Backend.ps1 -Suffix dev01ahcps -Environment dev
.\scripts\Bootstrap-Backend.ps1 -Suffix test01ahcps -Environment test
.\scripts\Bootstrap-Backend.ps1 -Suffix prod03ahcps -Environment prod
```

Deploy one environment at a time, starting with `dev` and reviewing each plan:

```powershell
Set-Location .\environments\dev
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init -reconfigure
terraform validate
terraform plan
terraform apply
```

Use the corresponding environment directory for `test` or `prod`. Never run an apply
from the wrong environment directory, and never commit `terraform.tfvars`, state files,
credentials, or storage keys.

The repository has passed formatting, initialization, validation, and plan checks for the
real environments. The local commands are:

```powershell
terraform fmt -check -recursive
terraform init -input=false -reconfigure
terraform validate
terraform plan -input=false -lock-timeout=5m
```

### P2S Control-Plane Validation

The test environment P2S control plane was validated with Azure VPN Client:

- Entra ID authentication succeeded
- The VPN gateway was reachable and attached
- The laptop received VPN address `172.16.0.130`
- Routes for the hub, app spoke, data spoke, and VPN pool were received
- Azure VPN Client reached `Connected`
- Azure Portal reported the active P2S session when refreshed promptly

See [docs/validation/test.md](docs/validation/test.md) for the recorded evidence and procedure.

### End-to-End Traffic Validation

End-to-end packet flow requires an Azure-side private target, such as a VM or private endpoint. The temporary VM attempt was removed after East US capacity, SKU availability, and quota restrictions prevented deployment. The P2S control-plane result is confirmed; workload traffic validation is documented as future work.

- Pull requests and pushes to `main` run formatting, backend-free validation for `demo`,
  `dev`, `test`, and `prod`, TFLint, advisory Checkov, and Trivy scans. Cloud-backed plans
  remain manual so pull-request code does not run with Azure credentials
- Scheduled daily drift detection for `dev`, `test`, and `prod` that opens or updates a
  GitHub issue when the live environment differs from configuration, and auto-closes it
  once reconciled
- Automatic GitHub issue creation when a `Terraform Apply` or `Terraform Destroy Apply`
  run fails, linking to the failed run
- Optional SonarCloud analysis when the repository variable `SONAR_ORGANIZATION`,
  repository variable `SONAR_PROJECT_KEY`, and secret `SONAR_TOKEN` are configured
- Manual environment plans for dev, test, and prod using OIDC
- Production apply and destroy require a successful Terraform Quality run for the exact
  source commit, require the workflow definition from `main`, and verify the matching
  successful plan workflow run/artifact before execution
- Saved binary Terraform plan artifacts with seven-day retention
- Plan text written to the GitHub Actions job summary
- Apply checks out and verifies the exact source commit recorded with the plan
- Shared per-environment concurrency groups serialize plans, applies, drift checks, and
  destroys so workflows cannot operate on the same state concurrently
- Manual environment selection for dev, test, and prod
- An apply workflow that downloads and applies the exact saved plan artifact
- Separate manual destroy-plan and destroy-apply workflows using reviewed artifacts
- Typed `DESTROY` confirmation for destructive operations
- Entra federation configured for the GitHub environments used by each workflow
- Separate state access through `Storage Blob Data Contributor`

Manual apply confirmation is implemented through the required `APPLY` or `CANCEL`
workflow input. Main branch protection is not enabled because GitHub only offers branch
protection rules on private repositories with a Pro, Team, or Enterprise plan; this
repository is currently on the Free plan. GitHub Environment required reviewers require
an Enterprise plan for private repositories. Confirmed by attempting to configure branch
protection through the GitHub API, which returned `403 Upgrade to GitHub Pro or make this
repository public to enable this feature`.
The apply workflow should be run only with the environment, plan run ID, and exact source
commit that were reviewed. It verifies the commit recorded in the plan artifact before
applying and never generates a new plan during apply.

Destroy is never triggered by a push or pull request. The destroy process requires a
successful manual destroy plan, review of its saved artifact, the matching plan run ID
and source commit, and an explicit `DESTROY` confirmation in the destroy-apply workflow.

The repository should not be presented as having independently approval-gated production
deployment. That remains pending a paid GitHub plan or a repository visibility/configuration
change that supports the required controls.

See [docs/rollback-runbook.md](docs/rollback-runbook.md) for the incident response and
rollback procedure covering failed applies, failed destroys, and detected drift.

Trivy scans this Terraform repository directly. Cosign is not included yet because this
repository does not build or publish a container image; Cosign should be added alongside a
container build workflow so it can sign and verify an actual image digest.

## Troubleshooting

See [docs/troubleshooting.md](docs/troubleshooting.md) for Azure VPN Client diagnostics, P2S session checks, quota failures, and the future end-to-end traffic test procedure.

## Future Enhancements

- Add a supported private workload target for packet-level VPN validation
- Add private endpoint resources and private DNS integration
- Restrict backend network access after all required identities are known
- Enable GitHub-enforced branch and environment approval gates for production apply after
  upgrading to a paid GitHub plan or changing repository visibility/configuration
- Add alert rules to the monitoring module
- Add VM backup association when a protected VM exists
- Add CAF and Well-Architected Framework mapping
- Add a finalized Draw.io architecture diagram
