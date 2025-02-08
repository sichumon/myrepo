@description('Location for the resources.')
param location string = resourceGroup().location

@description('Spoke VNet address space.')
param spokeVnetAddressSpace array = [
  '10.0.2.0/22'
]

@description('Spoke VNet Subnets configuration.')
var spokeSubnets = [
  {
    name: 'meme_dev_mgmt_subnet'
    addressPrefix: '10.0.2.0/28'
  }
  {
    name: 'meme_dev_appgw_subnet'
    addressPrefix: '10.0.2.16/28'
  }
  {
    name: 'meme_dev_ilb_subnet'
    addressPrefix: '10.0.2.32/28'
  }
  {
    name: 'meme_dev_pe_subnet'
    addressPrefix: '10.0.2.64/26'
  }
  {
    name: 'meme_dev_aks_subnet'
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
