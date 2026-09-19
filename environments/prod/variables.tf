variable "project" {
  description = "Short project name used as a prefix in resource names"
  type        = string
  default     = "hybridcloud"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    project     = "azure-hybrid-cloud"
    environment = "prod"
    managed_by  = "terraform"
  }
}