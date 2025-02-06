// main.bicep
targetScope = 'resourceGroup'

// Parameters
@description('Location for all resources.')
param location string
@description('Hub network configuration')
param hubNetworkConfig object
@description('Bastion configuration')
param bastionConfig object
@description('Firewall configuration')
// param firewallConfig object
// @description('DevOps agent configuration')
// param devopsConfig object
@description('Spoke network configuration')
param spokeNetworkConfig object


// Modules
module hubNetwork 'modules/hubnetwork.bicep' = {
  name: 'hubNetworkDeployment'
  params: {
    location: location
    vnetName: hubNetworkConfig.vnetName
    addressPrefix: hubNetworkConfig.addressPrefix
    subnets: hubNetworkConfig.subnets
  }
}

module spokeNetwork 'modules/spokenetwork.bicep' = {
  name: 'spokeNetworkDeployment'
  params: {
    location: location
    spokevnetName: spokeNetworkConfig.vnetName
    spokeaddressPrefix: spokeNetworkConfig.addressPrefix
  }
}

module vnetPeering 'modules/peering.bicep' = {
  name: 'vnetPeeringDeployment'
  params: {
    hubVnetName: hubNetworkConfig.vnetName
    spokeVnetName: spokeNetworkConfig.vnetName
  }
}

module bastionHost 'modules/bastion.bicep' = {
  name: 'bastionDeployment'
  params: {
    location: location
    bastionHostName: bastionConfig.name
    bastionSubnetId: '${hubNetwork.outputs.vnetId}/subnets/AzureBastionSubnet'
  }
}

// module firewall 'modules/firewall.bicep' = {
//   name: 'firewallDeployment'
//   params: {
//     location: location
//     firewallName: firewallConfig.name
//     skuTier: firewallConfig.skuTier
//     firewallSubnetId: '${hubNetwork.outputs.vnetId}/subnets/AzureFirewallSubnet'
//     managementSubnetId: '${hubNetwork.outputs.vnetId}/subnets/AzureFirewallManagementSubnet'
//   }
// }

// module devopsAgent 'modules/devops-agent.bicep' = {
//   name: 'devopsAgentDeployment'
//   params: {
//     location: location
//     vmName: devopsConfig.vmName
//     vmSize: devopsConfig.vmSize
//     adminUsername: devopsConfig.adminUsername
//     sshPublicKey: devopsConfig.sshPublicKey
//     subnetId: '${hubNetwork.outputs.vnetId}/subnets/DevOpsSubnet'
//   }
// }


