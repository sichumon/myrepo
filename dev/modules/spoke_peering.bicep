param spokeVnetName string
param hubVnetId string

resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: spokeVnetName
}

resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: spokeVnet
  name: 'SpokeToHubPeering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}