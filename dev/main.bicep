// main.bicep
targetScope = 'resourceGroup'

// Parameters
param tags object
@description('Location for all resources.')
param location string
@description('Hub network configuration')
param hubResourceGroupName string
param hubVnetName string
// param hubVnetID string
param resourceGroupName string
@description('VNET configuration')
param vnetAddressPrefix string
param subnets array
param vnetName string
@description('DevOps agent configuration')
param devopsConfig object
// param devopssubnet string
// param lawsid string
// @description('AKS configuration')
// param vnetId string
// param aksSubnetId string
// param prefix string
// param environment string

// Modules
module vnetConfig 'modules/networking.bicep' = {
  name: 'vNetDeployment'
  params: {
    location: location
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnets: subnets
    tags: tags
  }
}

module vnetPeering 'modules/peering.bicep' = {
  name: 'vnetPeeringDeployment'
  scope: subscription()
  params: {
    hubResourceGroupName: hubResourceGroupName
    hubVnetName: hubVnetName
    spokeResourceGroupName: resourceGroupName
    spokeVnetName: vnetName
  }
  dependsOn: [
    vnetConfig
 ]
}

module devopsAgent 'modules/devops-agent.bicep' = {
  name: 'devopsAgentDeployment'
  params: {
    location: location
    vmName: devopsConfig.vmName
    vmSize: devopsConfig.vmSize
    adminUsername: devopsConfig.adminUsername
    sshPublicKey: devopsConfig.sshPublicKey
    // subnetId: '${vnetConfig.outputs.vnetId}/subnets/${devopssubnet}'
    subnetId: '/subscriptions/0cc20e92-7212-41e7-bf3f-2ebb8b14dcfb/resourceGroups/meme-dev-rg/providers/Microsoft.Network/virtualNetworks/meme-dev-vnet/subnets/meme-dev-mgmt-subnet'
    tags: tags
  }
}

// param acrName string = 'memedevacr01'
// param acrResourceGroup string = 'meme-dev-rg'

// resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
//   name: acrName
//   scope: resourceGroup(acrResourceGroup)
// }

// param keyVaultName string = 'meme-dev-keyvlt-01'
// param keyVaultResourceGroup string = 'meme-dev-rg'

// resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
//   name: keyVaultName
//   scope: resourceGroup(keyVaultResourceGroup)
// }

// Deploy AKS using module
// module aks 'modules/aks-private-cluster.bicep' = {
//   name: 'aks-deployment'
//   params: {
//     clusterName: '${prefix}-${environment}-aks'
//     location: location
//     vnetId: vnetId
//     aksSubnetId: aksSubnetId
//     keyVaultId: keyVault.id        // Reference KV resource id
//     acrId: acr.id           // Reference ACR resource id
//     logAnalyticsWorkspaceId: lawsid // Reference Log Analytics resource id
//   }
//   dependsOn: [
//     acr
//     keyVault
//   ]
// }

// Outputs
// output keyVaultResourceId string = keyVault.id
// output acrResourceId string = acr.id
// output aksClusterName string = aks.outputs.clusterName
// output aksIdentityPrincipalId string = aks.outputs.clusterIdentityPrincipalId
