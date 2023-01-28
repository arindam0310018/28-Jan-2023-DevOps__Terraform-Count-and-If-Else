# COUNT AND IF ELSE WITH TERRAFORM AND DEVOPS:-

Greetings my fellow Technology Advocates and Specialists.

In this Session, I will demonstrate, __Count and If Else with Terraform and DevOps by deploying Azure Managed Grafana.__

| __REQUIREMENTS:-__ |
| --------- |

1. Azure Subscription.
2. Azure DevOps Organisation and Project.
3. Service Principal with Required RBAC ( __Contributor__) applied on Subscription or Resource Group(s).
4. Azure Resource Manager Service Connection in Azure DevOps.
5. Microsoft DevLabs Terraform Extension Installed in Azure DevOps and in Local System (VS Code Extension).


| __OUT OF SCOPE:-__ |
| --------- |
| __Azure DevOps Pipeline Code Snippet Explanation.__ |
| __If you are interested to understand the Pipeline Code Snippet, please refer my blogs in [Terraform](https://dev.to/arindam0310018/series/20638) Series.__ |


| __HOW DOES MY CODE PLACEHOLDER LOOKS LIKE:-__ |
| --------- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/kt1w0qtratxgv2dfk3k8.png) |


| PIPELINE CODE SNIPPET:- | 
| --------- |

| AZURE DEVOPS YAML PIPELINE (azure-pipelines-az-managed-grafana-v1.0.yml):- | 
| --------- |

```
trigger:
  none

######################
#DECLARE PARAMETERS:-
######################
parameters:
- name: SubscriptionID
  displayName: Subscription ID Details Follow Below:-
  default: 210e66cb-55cf-424e-8daa-6cad804ab604
  values:
  -  210e66cb-55cf-424e-8daa-6cad804ab604

- name: ServiceConnection
  displayName: Service Connection Name Follows Below:-
  default: amcloud-cicd-service-connection
  values:
  -  amcloud-cicd-service-connection

######################
#DECLARE VARIABLES:-
######################
variables:
  TfVars: "az-managed-grafana.tfvars"
  PlanOutput: "tfplan"
  ResourceGroup: "tfpipeline-rg"
  StorageAccount: "tfpipelinesa"
  Container: "terraform"
  TfstateFile: "AMG/AzManagedGrafana.tfstate"
  BuildAgent: "windows-latest"
  WorkingDir: "$(System.DefaultWorkingDirectory)/Az-Managed-Grafana"
  Target: "$(build.artifactstagingdirectory)/AMTF"
  Environment: "NonProd"
  Artifact: "AM"

#########################
# Declare Build Agents:-
#########################
pool:
  vmImage: $(BuildAgent)

###################
# Declare Stages:-
###################
stages:

- stage: PLAN
  jobs:
  - job: PLAN
    displayName: PLAN
    steps:
# Install Terraform Installer in the Build Agent:-
    - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
      displayName: INSTALL TERRAFORM VERSION - LATEST
      inputs:
        terraformVersion: 'latest'
# Terraform Init:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM INIT
      inputs:
        provider: 'azurerm'
        command: 'init'
        workingDirectory: '$(workingDir)' # Az DevOps can find the required Terraform code
        backendServiceArm: '${{ parameters.ServiceConnection }}' 
        backendAzureRmResourceGroupName: '$(ResourceGroup)' 
        backendAzureRmStorageAccountName: '$(StorageAccount)'
        backendAzureRmContainerName: '$(Container)'
        backendAzureRmKey: '$(TfstateFile)'
# Terraform Validate:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM VALIDATE
      inputs:
        provider: 'azurerm'
        command: 'validate'
        workingDirectory: '$(workingDir)'
        environmentServiceNameAzureRM: '${{ parameters.ServiceConnection }}'
# Terraform Plan:-
    - task: TerraformTaskV2@2
      displayName: TERRAFORM PLAN
      inputs:
        provider: 'azurerm'
        command: 'plan'
        workingDirectory: '$(workingDir)'
        commandOptions: "--var-file=$(TfVars) --out=$(PlanOutput)"
        environmentServiceNameAzureRM: '${{ parameters.ServiceConnection }}'
    
# Copy Files to Artifacts Staging Directory:-
    - task: CopyFiles@2
      displayName: COPY FILES ARTIFACTS STAGING DIRECTORY
      inputs:
        SourceFolder: '$(workingDir)'
        Contents: |
          **/*.tf
          **/*.tfvars
          **/*tfplan*
        TargetFolder: '$(Target)'
# Publish Artifacts:-
    - task: PublishBuildArtifacts@1
      displayName: PUBLISH ARTIFACTS
      inputs:
        targetPath: '$(Target)'
        artifactName: '$(Artifact)' 

- stage: DEPLOY
  condition: succeeded()
  dependsOn: PLAN
  jobs:
  - deployment: 
    displayName: Deploy
    environment: $(Environment)
    pool:
      vmImage: '$(BuildAgent)'
    strategy:
      runOnce:
        deploy:
          steps:
# Download Artifacts:-
          - task: DownloadBuildArtifacts@0
            displayName: DOWNLOAD ARTIFACTS
            inputs:
              buildType: 'current'
              downloadType: 'single'
              artifactName: '$(Artifact)'
              downloadPath: '$(System.ArtifactsDirectory)' 
# Install Terraform Installer in the Build Agent:-
          - task: ms-devlabs.custom-terraform-tasks.custom-terraform-installer-task.TerraformInstaller@0
            displayName: INSTALL TERRAFORM VERSION - LATEST
            inputs:
              terraformVersion: 'latest'
# Terraform Init:-
          - task: TerraformTaskV2@2 
            displayName: TERRAFORM INIT
            inputs:
              provider: 'azurerm'
              command: 'init'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF/' # Az DevOps can find the required Terraform code
              backendServiceArm: '${{ parameters.ServiceConnection }}' 
              backendAzureRmResourceGroupName: '$(ResourceGroup)' 
              backendAzureRmStorageAccountName: '$(StorageAccount)'
              backendAzureRmContainerName: '$(Container)'
              backendAzureRmKey: '$(TfstateFile)'
# Terraform Apply:-
          - task: TerraformTaskV2@2
            displayName: TERRAFORM APPLY # The terraform Plan stored earlier is used here to apply only the changes.
            inputs:
              provider: 'azurerm'
              command: 'apply'
              workingDirectory: '$(System.ArtifactsDirectory)/$(Artifact)/AMTF'
              commandOptions: '--var-file=$(TfVars)' # The terraform Plan stored earlier is used here to apply. 
              environmentServiceNameAzureRM: '${{ parameters.ServiceConnection }}'

```

| __TERRAFORM CODE SNIPPET:-__ |
| --------- |


| __TERRAFORM (main.tf):-__ |
| --------- |

```
terraform {

  required_version = ">= 1.3.3"
  
  backend "azurerm" {
    resource_group_name  = "tfpipeline-rg"
    storage_account_name = "tfpipelinesa"
    container_name       = "terraform"
    key                  = "AMG/AzGrafana.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.32.0"
    }
    
  }
}
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

```


| __EXPLANATION:-__ |
| --------- |
| The __"main.tf"__ file contains:- |
| 1. __Terraform version.__ |
| 2. __Backend terraform state filename and location.__ |
| 3. __Required terraform providers.__ |


| __TERRAFORM (az-managed-grafana.tf):-__ |
| --------- |

```
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
  count				    = length(var.az-grafana-name)
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

```

| __EXPLANATION:-__ |
| --------- |
| The __"az-managed-grafana.tf"__ file contains:- |
| 1. __Create one or more AAD Group using terraform "count" and "length". The Names of the group are passed as an array - list(string).__ |
| 2. __The owners of the AAD Group(s) are referenced in Terraform Data block as they already exists. |
| 3. __Create a single resource group.__  |
| 4. __Create one or more Azure Managed Grafana using terraform "count" and "length". The Names of the Azure Managed Grafana are passed as an array - list(string).__ |
| 5. __The resource group under which one or more Azure Managed Grafana gets deployed is referenced as implicit dependency.__ |
| 6. __If else block is used for - "zone redundancy", "api key", "outbound IP" and "public network access".__ |
| 7. __The id of each Azure Managed Grafana Instance and Object id of each AAD Group is stored as terraform output. RBAC was then created by counting output ids of Azure Managed Grafana which is the scope. Role definition defined here is static (For Example - "Grafana Admin") which is mapped to Object id of the Azure AD Group referenced here as array index.__ |


| __IF ELSE EXAMPLE AND EXPLANATION:-__ |
| --------- |

```
zone_redundancy_enabled = var.az-grafana-zone-redundancy != "" ? var.az-grafana-zone-redundancy : "true"

```

__If the variable "var.az-grafana-zone-redundancy" is equal to NULL, then the value is "true". If not, then the value is what is defined for the variable.__


| __TERRAFORM (data.tf):-__ |
| --------- |

```
# Data source to retrieve User object ID
data "azuread_users" "az-aad-grp-owner" {
  user_principal_names = var.az-aad-group-owner
  ignore_missing       = true
}

```

| __NOTE:-__ |
| --------- |
| __Terraform Data block to retrieve already existing User Principal name(s).__ |


| __TERRAFORM (output.tf):-__ |
| --------- |

```
output "az-grafana-id" {
  value = azurerm_dashboard_grafana.az-grafana.*.id
}

output "az-aad-group-id" {
  value = azuread_group.az-aad-group.*.id
}

```

| __NOTE:-__ |
| --------- |
| __Terraform output block to retrieve the id(s) of one or more Azure Managed Grafana Instances and object id(s) of one or more Azure AD Group(s).__ |


| __TERRAFORM (variables.tf):-__ |
| --------- |

```
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

```

| __NOTE:-__ |
| --------- |
| __This is Self-Explanatory.__ |


| __TERRAFORM (az-managed-grafana.tfvars):-__ |
| --------- |

```
az-aad-group-name               = ["am-grafana-admin-aad-grp", "am-grafana-editor-aad-grp", "am-grafana-viewer-aad-grp"]
az-aad-group-owner              = ["U1@mitra008.onmicrosoft.com", "U2@mitra008.onmicrosoft.com"]
rg-name                         = "am-grafana-rg"
location                        = "west europe"
az-grafana-name                 = ["am-grafana-04", "am-grafana-05"]
az-grafana-zone-redundancy      = ""
az-grafana-api-key              = ""
az-grafana-outbound-ip          = ""
az-grafana-public-access        = ""
az-grafana-identity             = "SystemAssigned"

```

| __NOTE:-__ |
| --------- |
| __This is Self-Explanatory except where the value of the variables are NULL. This is where we have used Terraform If else which is explained above.__ |


| __TEST RESULTS:-__ |
| --------- |
| __Pipeline Execution:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/15y77v2m3dhnhw40xt2b.jpg) |
| __Azure Managed Grafana Deployed:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/0gepovolv9pnpzmg2dm2.jpg) |
| __Azure Managed Grafana Configuration:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/gaokzaxjn6ualpr0ax0k.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/9ya4w6l6z4txjapi5lg6.jpg) |
| __Azure AAD Group Deployed:-__ |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/wfokcbbep0gun76vr4qm.jpg) |
| __Role Assignments:- |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/9hoxzkghuhx2zqqskxft.jpg) |
| ![Image description](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/osam05lk0sa82zgi49no.jpg) |


__Hope You Enjoyed the Session!!!__

__Stay Safe | Keep Learning | Spread Knowledge__
