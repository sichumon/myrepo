param vnetName string
param location string = resourceGroup().location
param vnetAddressPrefix string
param subnets array
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
output subnetIds array = [
  for subnet in subnets: {
    name: subnet.name
    id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnet.name)
  }
]
