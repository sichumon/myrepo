# Deploy with parameter override

# creat a sshkey pair for Devops agent
ssh-keygen -f sshkey

az group create  --name  meme-poc-hub-rg
az group create  --name  meme-poc-spoke-rg
# get the rg value
export RG=$(az group list --output table|grep sandbox|awk '{print $1}')

# Run the deployment

az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters @parameters.json
