targetScope = 'subscription'

param hubResourceGroupName string
param spokeResourceGroupName string
param hubVnetName string
param spokeVnetName string

resource hubRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: hubResourceGroupName
}

resource spokeRg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: spokeResourceGroupName
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  scope: hubRg
  name: hubVnetName
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  scope: spokeRg
  name: spokeVnetName
}

module hubPeering 'hub_peering.bicep' = {
  scope: hubRg
  name: 'hubPeering'
  params: {
    hubVnetName: hubVnetName
    spokeVnetId: spokeVnet.id
    spokeVnetName: spokeVnetName
  }
}

module spokePeering 'spoke_peering.bicep' = {
  scope: spokeRg
  name: 'spokePeering'
  params: {
    spokeVnetName: spokeVnetName
    hubVnetId: hubVnet.id
    hubVnetName: hubVnetName
  }
}
