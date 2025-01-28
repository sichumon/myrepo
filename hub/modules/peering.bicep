param hubVnetName string = 'HubVNet'
param spokeVnetName string = 'SpokeVNet'

// Reference existing Hub VNet
resource hubVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: hubVnetName
}

// Reference existing Spoke VNet
resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: spokeVnetName
}

// Hub to Spoke peering
resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: hubVnet
  name: 'HubToSpokePeering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
  }
}

// Spoke to Hub peering
resource spokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  parent: spokeVnet
  name: 'SpokeToHubPeering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}
