Readme.MD

Steps to Retrieve the Resource ID
Create the Managed Identity:

az identity create --name AzDevOpsIdentity --resource-group my-resource-group

List Managed Identities to Retrieve the Resource ID:

az identity show --name AzDevOpsIdentity --resource-group my-resource-group --query id -o tsv

This will output the resource ID, which you can use directly in the script.


List the resource Group 

az group list --output table

export RG=$(az group list --output table|grep sandbox|awk '{print $1}')

Deployment Validation

Validate the script:

az bicep build --file hub.bicep

Deploy the updated script:

az deployment group create --resource-group $RG --template-file hub.bicep


az deployment group create \
  --resource-group your-resource-group \
  --template-file template.bicep \
  --parameters @parameters.json# myrepo
