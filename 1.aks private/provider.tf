terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "example-resources"
    storage_account_name = "terraformstore465"
    container_name       = "terraform"
    key                  = "aks.tfstate"
    subscription_id      = "8f07d993-44bb-4a71-a8be-817e9ce1029f"
  }  
}
#terraform init -backend=true -backend-config="tenant_id=${{ env.ARM_TENANT_ID }}" -backend-config="subscription_id=${{ env.CORE_SUBSCRIPTION_ID }}" -backend-config="key=${{ env.CLUSTER_NAME }}.terraform.tfstate"
/*
terraform {
  backend "azurerm" {
    resource_group_name  = "myresourcegroup"
    storage_account_name = "saterraformstate2309" # UPDATE HERE.
    container_name       = "aks-series"           # UPDATE HERE.
    # key                = Specify via terraform init e.g. -backend-config="key=env-prd.tfstate"
    # access_key         = Ensure $env:ARM_ACCESS_KEY is set locally
    subscription_id      = "mysubscriptionid"
  }
}
*/

# 2. Configure the AzureRM Provider
provider "azurerm" {
  subscription_id = "8f07d993-44bb-4a71-a8be-817e9ce1029f"
  # The AzureRM Provider supports authenticating using via the Azure CLI, a Managed Identity
  # and a Service Principal. More information on the authentication methods supported by
  # the AzureRM Provider can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure

  # The features block allows changing the behaviour of the Azure Provider, more
  # information can be found here:
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block
  features {}
}

/*
provider "azurerm" {
  features {}
  subscription_id = <your subscription id>
  tenant_id = <your tenant id>
  client_id = <your client id>
  client_secret = <your client password>
  # client_secret = Ensure $env:ARM_CLIENT_SECRET is set locally
  # $env:ARM_ACCESS_KEY = "ENTER YOUR VALUE HERE"
  # $env:ARM_CLIENT_SECRET = "ENTER YOUR VALUE HERE"  
}


# https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli

#az login
#We can now return to VSCode, and this will show the Subscriptions we have access to. If you need to select a specific Subscription, use the following command:
#az account set --subscription "subscription name"
#az account show
https://learn.microsoft.com/en-us/azure/virtual-machines/regions
https://holori.com/list-of-all-azure-regions-and/
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli
https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure-with-service-principle?tabs=bash
https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id
https://jeffbrown.tech/terraform-azure-authentication/
https://github.com/jakewalsh90/Terraform-Azure/blob/main/.github/workflows/apply.yml
https://stackoverflow.com/questions/59140782/how-can-i-see-a-list-of-all-users-and-the-roles-assigned-to-them-in-azure
https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively

https://azurelessons.com/create-service-principal-in-azure/

https://www.gislen.com/developerblog/managed-identities-in-azure-a-comprehensive-guide/
https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/how-manage-user-assigned-managed-identities?pivots=identity-mi-methods-azp

https://medium.com/@asad_leo94/creating-managed-identities-in-azure-a-step-by-step-guide-to-granting-identity-contributor-role-at-8aeda7830055
https://learn.microsoft.com/en-us/azure/operator-service-manager/how-to-create-user-assigned-managed-identity
https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity
https://learn.microsoft.com/en-us/cli/azure/identity?view=azure-cli-latest#az-identity-create
https://stackoverflow.com/questions/77271706/how-to-create-a-user-managed-identity-assign-to-key-vault-service-bus-by-bas

*/