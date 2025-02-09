param hubVnetName string
param hubvnetID string
param spokeVnetName string
// param hubResourceGroupName string
// param resourceGroupNamex string

// Reference existing Hub VNet
resource hubVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: hubVnetName
  // scope: resourceGroup(hubResourceGroupName)

}

// Reference existing Spoke VNet
resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: spokeVnetName
  // scope: resourceGroup(resourceGroupNamex)
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
      id: hubvnetID
    }
  }
}
