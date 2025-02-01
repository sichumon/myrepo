param iotLocation string
param iotHubName string
param spokeVnetName string
param spokePeSubnetName string
param iotPrivateDnsZoneName string = 'privatelink.azure-devices.net'
param iotEnv string
param iotProj string
//param iotTlsVersion string = '1.2'
//param iotSkuName string = 'S1'
//param iotSkuCapacity int = 1
//param iotDefenderEnabled bool = true
param iotTlsVersion string
param iotSkuName string
param iotSkuCapacity int
param iotDefenderEnabled bool


resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: spokeVnetName
}

resource peSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' existing = {
  parent: vnet
  name: spokePeSubnetName
}

resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: iotHubName
  location: iotLocation
  properties: {
    publicNetworkAccess: 'Disabled'
    minTlsVersion: iotTlsVersion
    defender: {
      enabled: iotDefenderEnabled
    }
  }
  sku: {
    name: iotSkuName
    capacity: iotSkuCapacity
  }
  tags: {
    env: iotEnv
    proj: iotProj
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: '${iotHubName}-privateEndpoint'
  location: iotLocation
  properties: {
    subnet: {
      id: peSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'iotHubPrivateLink'
        properties: {
          privateLinkServiceId: iotHub.id
          groupIds: [
            'iotHub'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: iotPrivateDnsZoneName
  location: 'global'
}

resource privateDnsZoneVirtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${iotPrivateDnsZoneName}-vnet-link'
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
  name: 'iotHubPrivateDnsZoneGroup'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: iotPrivateDnsZoneName
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
