// modules/network.bicep
@description('Location for the resources.')
param location string

@description('Name of the virtual network')
param spokevnetName string

@description('Address prefix for the virtual network')
param spokeaddressPrefix array




// Spoke VNet resource
resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: spokevnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: spokeaddressPrefix
    }
  }
}

// Outputs
output vnetId string = spokeVnet.id
output vnetName string = spokeVnet.name
