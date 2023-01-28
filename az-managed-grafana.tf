#####################
## Azure AD Group:-
#####################

resource "azuread_group" "az-aad-group" {
  count                   = length(var.az-aad-group-name)
  display_name            = var.az-aad-group-name[count.index]
  owners                  = data.azuread_users.az-aad-grp-owner.object_ids
  prevent_duplicate_names = false
  security_enabled        = true
}

#####################
## Resource Group:-
#####################

resource "azurerm_resource_group" "rg" {
  name      = var.rg-name
  location  = var.location
}

##############################
## Azure Managed Grafana:-
##############################

resource "azurerm_dashboard_grafana" "az-grafana" {
  count				                      = length(var.az-grafana-name)
  name                              = var.az-grafana-name[count.index]
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = var.location
  zone_redundancy_enabled           = var.az-grafana-zone-redundancy != "" ? var.az-grafana-zone-redundancy : "true"
  api_key_enabled                   = var.az-grafana-api-key != "" ? var.az-grafana-api-key : "true"
  deterministic_outbound_ip_enabled = var.az-grafana-outbound-ip != "" ? var.az-grafana-outbound-ip : "true"
  public_network_access_enabled     = var.az-grafana-public-access != "" ? var.az-grafana-public-access : "false"

  identity {
    type = var.az-grafana-identity
  }

}

#######################################
## Role Based Access Control (RBAC):-
#######################################

resource "azurerm_role_assignment" "az-rbac-grafana-admin" {
  count                = length(azurerm_dashboard_grafana.az-grafana.*.id)
  scope                = azurerm_dashboard_grafana.az-grafana[count.index].id
  role_definition_name = "Grafana Admin"
  principal_id         = azuread_group.az-aad-group[0].id 
}

resource "azurerm_role_assignment" "az-rbac-grafana-editor" {
  count                = length(azurerm_dashboard_grafana.az-grafana.*.id)
  scope                = azurerm_dashboard_grafana.az-grafana[count.index].id
  role_definition_name = "Grafana Editor"
  principal_id         = azuread_group.az-aad-group[1].id 
}

resource "azurerm_role_assignment" "az-rbac-grafana-viewer" {
  count                = length(azurerm_dashboard_grafana.az-grafana.*.id)
  scope                = azurerm_dashboard_grafana.az-grafana[count.index].id
  role_definition_name = "Grafana Viewer"
  principal_id         = azuread_group.az-aad-group[2].id 
}