variable "location" {
  description = "Azure region"
  type = string
  default = "eastus2"
}

variable "project_name" {
  description = "Project name"
  type = string
  default = "order-system"
}

variable "environment" {
  description = "application environment"
  type = string
  default = "development"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
  type = string
}
