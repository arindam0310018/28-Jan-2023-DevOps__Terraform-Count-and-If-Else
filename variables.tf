variable "az-aad-group-name" {
  type        = list(string)
  description = "Names of the Azure Active Directory Group."
}

variable "az-aad-group-owner" {
  type        = list(string)
  description = "List of Users added as owner of the Azure Active Directory Group."
}

variable "rg-name" {
  type        = string
  description = "Name of the Resource Group."
}

variable "location" {
  type        = string
  description = "Location of the Resource Group and Resources."
}

variable "az-grafana-name" {
  type        = list(string)
  description = "Name of the Azure Managed Grafana."
}

variable "az-grafana-zone-redundancy" {
  type        = string
  description = "Enable zone redundancy setting of the Grafana Instance."  
}

variable "az-grafana-api-key" {
  type        = string
  description = "Enable the api key setting of the Grafana Instance."
}

variable "az-grafana-outbound-ip" {
  type        = string
  description = "Enable the Grafana Instance to use Deterministic outbound IPs."
}

variable "az-grafana-public-access" {
  type        = string
  description = "To enable traffic over the Public Interface."
}

variable "az-grafana-identity" {
  type        = string
  description = "System Assigned Managed Identity"
}
