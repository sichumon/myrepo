param hubVnetName string
param spokeVnetId string
param spokeVnetName string

resource hubVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: hubVnetName
}

resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: hubVnet
  name: '${hubVnetName}-to-${spokeVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
  }
}
