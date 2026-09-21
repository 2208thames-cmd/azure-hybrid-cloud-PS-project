# Azure hybrid cloud architecture project

Hub-and-spoke hybrid architecture built with Terraform. The project is organized as
three isolated environments and is designed to demonstrate Azure networking, governance,
identity, monitoring, backup, and a future CI/CD workflow.

## Layout

```
.
├── environments/
│   ├── dev/                # Development environment
│   ├── test/               # Test environment
│   └── prod/               # Production environment
│       ├── main.tf         # Calls the shared modules
│       ├── variables.tf
│       ├── outputs.tf
│       ├── providers.tf    # Provider and required_providers blocks
│       ├── backend.tf      # Environment-specific remote state
│       ├── terraform.tfvars # Local values; ignored by Git
│       └── terraform.tfvars.example
├── modules/
│   ├── network/            # Virtual WAN, hub, spokes, private endpoints
│   ├── governance/          # Azure Policy, RBAC, Defender for Cloud
│   ├── identity/            # Conditional Access, PIM (via azuread provider)
│   ├── monitoring/          # Log Analytics workspace; alerts follow
│   └── backup/              # Recovery Services vault + backup policy
├── demo/                   # Sanitized recruiter demo with local state
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   └── README.md
├── scripts/
│   └── Bootstrap-Backend.ps1 # Creates a remote-state resource group and storage account
└── README.md
```

## Prerequisites

- PowerShell 7+ (`pwsh`)
- The `Az` PowerShell module: `Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force`
- Terraform CLI
- An authenticated Azure session: `Connect-AzAccount`
- An Azure subscription where the backend resource groups can be created

## Environment and state design

Each environment has its own Azure Storage account, resource group, and Terraform state
key. This prevents one environment from reading or overwriting another environment's
state while keeping the Terraform modules reusable.

| Environment | Backend resource group | Storage account | Container | State key |
|---|---|---|---|---|
| dev | `rg-tfstate-dev01ahcps` | `sttfstatedev01ahcps` | `tfstate` | `dev.terraform.tfstate` |
| test | `rg-tfstate-test01ahcps` | `sttfstatetest01ahcps` | `tfstate` | `test.terraform.tfstate` |
| prod | `rg-tfstate-prod03ahcps` | `sttfstateprod03ahcps` | `tfstate` | `prod.terraform.tfstate` |

The `ahcps` suffix makes the storage account names globally unique while preserving the
environment identifiers `dev01`, `test01`, and `prod03`. Separate storage accounts were
chosen because they provide a clearer security and recovery boundary than sharing one
account for every environment.

## Backend protection

All three Terraform state storage accounts use Azure Blob Storage with:

- HTTPS-only access and TLS 1.2
- Blob public access disabled
- Blob versioning enabled
- Blob soft delete enabled for 30 days
- Container soft delete enabled for 30 days
- Change feed enabled
- A dedicated `tfstate` container

The AzureRM backend provides state locking through Azure Blob leases. The separate state
keys and locking prevent concurrent Terraform operations from corrupting state. State
files must never be edited manually or committed to Git.

Network firewall restrictions and CI/CD identity permissions are intentionally separate
follow-up work. They should be enabled only after the identities that need Terraform
access are confirmed, so the backend is not accidentally locked away from local work or
automation.

## CI/CD plan workflow

The `terraform-plan-dev.yml` workflow is a plan-only GitHub Actions workflow for the
real dev environment. It uses OIDC federation instead of a stored Azure client secret.
The workflow requires these GitHub Actions variables:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

The federated Azure identity must be restricted to this repository and the intended
GitHub Actions subject, and it needs only the permissions required to read the dev
infrastructure and access the dev state storage account. Grant `Storage Blob Data
Contributor` on the dev storage account for state access; grant broader resource access
only if the plan needs it. This workflow runs `plan` only and does not apply or destroy
resources.

## Order of operations

1. Authenticate to Azure with `Connect-AzAccount` in PowerShell.
2. Create a backend with `.\scripts\Bootstrap-Backend.ps1 -Suffix <suffix>` in PowerShell.
3. Put the printed resource group and storage account values in the matching
	`environments/<environment>/backend.tf` and use that environment's state key.
4. Copy `terraform.tfvars.example` to `terraform.tfvars` and review the values.
5. From the environment directory, run:

	```powershell
	terraform init
	terraform validate
	terraform plan
	```

6. Apply only after reviewing the plan and confirming the target environment.

The current environments have all successfully completed `terraform init` and
`terraform validate`. The normal promotion order is dev, then test, then prod.

## Why remote state from day one

Local state (`terraform.tfstate` on disk) is fine for a five-minute test, but it's not
how this is done in production, and an interviewer will ask. Remote state in Azure
Storage provides locking, a shared source of truth, version history, and recovery from
accidental deletion. Azure AD/RBAC authentication is preferred for human and pipeline
access; storage keys and connection strings should not be committed or shared.

## Recruiter demo

The recruiter demo is separate from the real Azure environments. It allows a reviewer
to inspect the Terraform structure and run safe commands such as
`terraform init`, `terraform validate`, and `terraform plan` without access to this
subscription or the real state files.

Recruiters should not receive personal Azure credentials, storage keys, or production
state access. The demo will not require a major change to the real Azure backend.
