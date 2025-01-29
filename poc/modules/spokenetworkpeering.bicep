// modules/network.bicep
@description('Location for the resources.')
param location string

@description('Name of the virtual network')
param spokevnetName string

@description('Address prefix for the virtual network')
param spokeaddressPrefix array

@description('Subnet configurations')
param spokesubnets array

// Reference existing Spoke VNet
// resource spokeVnetName 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
//   name: spokeVnetName
// }

// Spoke VNet resource
resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: spokevnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: spokeaddressPrefix
    }
    subnets: [for subnet in spokesubnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

