# Terraform module: Azure Kubernetes Service (AKS)
terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.87"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.13"
    }
  }
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "px-aks"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
  default     = "pxaks"
}

variable "node_count" {
  description = "Initial node count"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Node VM size"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = var.dns_prefix
  tags                = var.tags

  default_node_pool {
    name       = "npwin"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "host" {
  value       = azurerm_kubernetes_cluster.this.fqdn
  sensitive   = true
}
