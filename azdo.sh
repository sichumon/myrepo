# define variables
export SUBSCRIPTION=$(az account show --query id --output tsv|awk '{print $1}')
export LOCATION=$(az group list -o tsv|awk '{print $2}'|head -1)
export ORG_NAME=$(az account show --query user.name --output tsv)
export RESOURCE_GROUP=$(az group list -o tsv|awk '{print $4}'|head -1)
export ORG_PROPERTIES="{\"location\": \""$LOCATION\"", \"properties\": {\"operationType\": \"Create\"}}"

# set subscription
az account set --subscription "$SUBSCRIPTION"

# create an Azure DevOps Organization
az resource create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ORG_NAME" \
  --resource-type "microsoft.visualstudio/account" \
  --properties "$ORG_PROPERTIES" \
  --is-full-object