# Data source to retrieve User object ID
data "azuread_users" "az-aad-grp-owner" {
  user_principal_names = var.az-aad-group-owner
  ignore_missing       = true
}