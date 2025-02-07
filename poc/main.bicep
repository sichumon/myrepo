// main.bicep
targetScope = 'resourceGroup'

// Parameters
@description('Location for all resources.')
param location string
@description('Spoke network configuration')
param spokeNetworkConfig object



module spokeSubnets 'modules/spokenetworkpeering.bicep' = {
  name: 'spokeNetworkPeeringDeployment'
  params: {
    location: location
    spokevnetName: spokeNetworkConfig.vnetName
    spokeaddressPrefix: spokeNetworkConfig.addressPrefix
    spokesubnets: spokeNetworkConfig.subnets
  }
}
