// modules/bastion.bicep
param location string
param bastionHostName string
param bastionSubnetId string

resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: '${bastionHostName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-08-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'BastionIpConfig'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}
