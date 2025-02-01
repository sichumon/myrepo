param adxLocation string
param adxClusterName string
param spokeVnetName string
param spokePeSubnetName string
param adxPrivateDnsZoneName string
param adxSkuName string
param adxSkuCapacity int
param adxEnv string
param adxProj string
param skuTier string

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: spokeVnetName
}

resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' existing = {
  parent: vnet
  name: spokePeSubnetName
}

resource adxCluster 'Microsoft.Kusto/clusters@2023-05-02' = {
  name: adxClusterName
  location: adxLocation
  properties: {
    publicNetworkAccess: 'Disabled'
  }
  sku: {
    name: adxSkuName
    tier: skuTier
    capacity: adxSkuCapacity
  }
  tags: {
    env: adxEnv
    proj: adxProj
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${adxClusterName}-privateEndpoint'
  location: adxLocation
  properties: {
    subnet: {
      id: peSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'adxPrivateLink'
        properties: {
          privateLinkServiceId: adxCluster.id
          groupIds: [
            'cluster'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: adxPrivateDnsZoneName
  location: 'global'
}

resource privateDnsZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${adxPrivateDnsZoneName}-vnet-link'
  parent: privateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: 'adxPrivateDnsZoneGroup'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: adxPrivateDnsZoneName
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
