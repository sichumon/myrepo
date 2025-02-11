@description('Location for the resources.')
param location string = resourceGroup().location

@description('Spoke VNet address space.')
param spokeVnetAddressSpace array = [
  '10.0.2.0/23'
]

@description('Spoke VNet Subnets configuration.')
var spokeSubnets = [
  {
    name: 'meme-dev-mgmt-subnet'
    addressPrefix: '10.0.2.0/28'
  }
  {
    name: 'meme-dev-appgw-subnet'
    addressPrefix: '10.0.2.16/28'
  }
  {
    name: 'meme-dev-ilb-subnet'
    addressPrefix: '10.0.2.32/28'
  }
  {
    name: 'meme-dev-pe-subnet'
    addressPrefix: '10.0.2.64/26'
  }
  {
    name: 'meme-dev-aks-subnet'
    addressPrefix: '10.0.3.0/24'
  }
]

// Spoke VNet resource
resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'meme-dev-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: spokeVnetAddressSpace
    }
    subnets: [for subnet in spokeSubnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}
