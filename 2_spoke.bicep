@description('Location for the resources.')
param location string = resourceGroup().location

@description('Spoke VNet address space.')
param spokeVnetAddressSpace array = [
  '10.0.1.0/24'
]

@description('Spoke VNet Subnets configuration.')
var spokeSubnets = [
  {
    name: 'green_dev_mgmt_subnet'
    addressPrefix: '10.0.1.0/28'
  }
  {
    name: 'green_dev_appgw_subnet'
    addressPrefix: '10.0.1.16/28'
  }
  {
    name: 'green_dev_aks_subnet'
    addressPrefix: '10.0.1.128/25'
  }
  {
    name: 'green_dev_ilb_subnet'
    addressPrefix: '10.0.1.32/28'
  }
  {
    name: 'green_dev_pe_subnet'
    addressPrefix: '10.0.1.64/26'
  }
]

// Spoke VNet resource
resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'SpokeVNet'
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
