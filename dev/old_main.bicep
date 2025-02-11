targetScope = 'subscription'

// Load parameters
param resourceGroupName string
param location string
param tags object
param vnetName string
param vnetAddressPrefix string
param subnets array

// Deploy Resource Group
module rg 'modules/resourceGroup.bicep' = {
  name: 'resourceGroupDeployment'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    tags: tags
  }
}

// Deploy Networking (VNet and Subnets)
module networking 'modules/networking.bicep' = {
  name: 'networkingDeployment'
  scope: resourceGroup(rg.outputs.resourceGroupId)
  params: {
    vnetName: vnetName
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    subnets: subnets
    tags: tags
  }
}

// Outputs
output resourceGroupId string = rg.outputs.resourceGroupId
output vnetId string = networking.outputs.vnetId
output subnetIds array = networking.outputs.subnetIds
