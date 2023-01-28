output "az-grafana-id" {
  value = azurerm_dashboard_grafana.az-grafana.*.id
}

output "az-aad-group-id" {
  value = azuread_group.az-aad-group.*.id
}