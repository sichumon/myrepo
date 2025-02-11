using './main.bicep'

// param resourceGroupName = 'meme-test-rg'
param location = 'uksouth'
param tags = {
  environment: 'test'
  project: 'meme'
}
param hubResourceGroupName = 'meme-poc-hub-rg'
param resourceGroupName = 'meme-staging'
param hubVnetName = 'HubVNet'
param hubVnetID = '/subscriptions/0cc20e92-7212-41e7-bf3f-2ebb8b14dcfb/resourceGroups/meme-poc-hub-rg/providers/Microsoft.Network/virtualNetworks/HubVNet'
// param devopssubnet = 'meme-staging-mgmt-subnet'

param vnetName = 'meme-staging-vnet'
param vnetAddressPrefix = '10.0.8.0/23'
param subnets = [
  {
    name: 'meme-staging-mgmt-subnet'
    addressPrefix: '10.0.8.0/28'
  }
  {
    name: 'meme-staging-appgw-subnet'
    addressPrefix: '10.0.8.16/28'
  }
  {
    name: 'meme-staging-ilb-subnet'
    addressPrefix: '10.0.8.32/28'
  }
  {
    name: 'meme-staging-pe-subnet'
    addressPrefix: '10.0.8.64/26'
  }
  {
    name: 'meme-staging-aks-subnet'
    addressPrefix: '10.0.9.0/24'
  }
]
param devopsConfig = {
    vmName: 'DevOpsAgent'
    vmSize: 'Standard_D2s_v3'
    adminUsername: 'azureuser'
    sshPublicKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCi46S03NzCl09w5TDUvBLa40ne+JF0Y0ceZ3hum4o8rvhhEaBGt5HzNn8YqkLUEig9XlKTkc8aig3j7CIx4OyCNyJHB77HZDKCmkJgPFz3+AlDl21pltnloi/KYAh7Skl1cyjKJO+7wc4IUmHpvdKpTATp7j3CUVEVSetsA2j7GRy4ltNofo5KLdPwG92seoyjudBHDK84LYsJww9l4Q8g3OHvwb6lQQDmVWaw8eza/62Y/ervq1Ss5IN/XZzqJnY10KO+RrlWh7+i1Zm//ruDeable4Aeey5VZlYmUb21+oZRAhhD7W2IXWfOJQJF+94yzblDmvWoQv+7J2299z45wxANWPEN5TPrjjuvrtdkLDKRFZ1cbh8RELKQ2+ywqmxdvUKBOVr4TQcBhONj1ej5vTFaKzzgDkTiSEHE8RUxVfogI1dqfkgX7rOamfdMUKKgZX0pHmKvhO8xXcHA/nz7qA14qKPaoICWqn3jHq7nSJENpDFSOoHDbrbG1ptieuc= azureuser@build-vm-3'
  }
// param lawsid = '/subscriptions/0cc20e92-7212-41e7-bf3f-2ebb8b14dcfb/resourceGroups/meme-poc-hub-rg/providers/Microsoft.OperationalInsights/workspaces/meme-poc-hub-laws-01'
// param prefix = 'meme'
// param environment = 'dev'
// param vnetId = '/subscriptions/0cc20e92-7212-41e7-bf3f-2ebb8b14dcfb/resourceGroups/meme-dev-rg/providers/Microsoft.Network/virtualNetworks/meme-dev-vnet'
// param aksSubnetId = '/subscriptions/0cc20e92-7212-41e7-bf3f-2ebb8b14dcfb/resourceGroups/meme-dev-rg/providers/Microsoft.Network/virtualNetworks/meme-dev-vnet/subnets/meme-dev-aks-subnet'
