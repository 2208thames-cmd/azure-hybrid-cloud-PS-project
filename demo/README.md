# Demo Environment

This folder is a sanitized, local-state entry point for reviewing the Terraform design.
It reuses the shared network module but has no Azure remote backend and no committed
credentials or environment values.

## Safe review

```powershell
terraform init
terraform validate
```

A real `terraform plan` requires Azure authentication and an Azure subscription because
Terraform must resolve the Azure provider and plan Azure resources. If you have your own
sandbox subscription, copy `terraform.tfvars.example` to `terraform.tfvars`, sign in with
Azure CLI or PowerShell, and run:

```powershell
terraform plan
```

Do not run `terraform apply` or `terraform destroy` against another person's subscription.
This demo is separate from the real `dev`, `test`, and `prod` remote-state backends.

## GitHub Actions

The repository workflow runs `terraform fmt -check`, initializes without a remote
backend, and runs `terraform validate` for this demo on pushes and pull requests. It
does not need Azure credentials and does not run `apply`, `destroy`, or an Azure-backed
plan. A future deployment workflow can add an OIDC identity after the real Azure
deployment process is ready.
