// main.bicep
targetScope = 'resourceGroup'

// Parameters
param tags object
@description('Location for all resources.')
param location string
// @description('Hub network configuration')
// param hubVnetName string
// param hubVnetID string
// param hubResourceGroupName string
// param resourceGroupName string
// @description('VNET configuration')
// param vnetAddressPrefix string
// param subnets array
// param vnetName string
@description('DevOps agent configuration')
param devopsConfig object
param devopssubnet string

// // Modules
// module vnetConfig 'modules/networking.bicep' = {
//   name: 'vNetDeployment'
//   params: {
//     location: location
//     vnetName: vnetName
//     vnetAddressPrefix: vnetAddressPrefix
//     subnets: subnets
//     tags: tags
//   }
// }

// module vnetPeering 'modules/peering.bicep' = {
//   name: 'vnetPeeringDeployment'
//   params: {
//     // hubResourceGroupName: hubResourceGroupName
//     // resourceGroupNamex: resourceGroupName
//     hubVnetName: hubVnetName
//     hubvnetID: hubVnetID
//     spokeVnetName: vnetName
//   }
// }

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


