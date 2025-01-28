# Deploy with parameter override
# creat a sshkey pair for Devops agent
ssh-keygen -f sshkey
# get the rg value
export RG=$(az group list --output table|grep sandbox|awk '{print $1}')
# RUn the deployment
az deployment group create \
  --resource-group $RG \
  --template-file main.bicep \
  --parameters @parameters.json \
  --parameters devopsConfig.sshPublicKey="$(cat sshkey.pub)"