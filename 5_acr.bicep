@description('Name of the Azure Container Registry')
@minLength(5)
@maxLength(50)
param acrName string

@description('Location for the resources')
param location string = resourceGroup().location

@description('The name of the existing spoke virtual network')
param spokeVnetName string

@description('The name of the subnet to create private endpoint')
param subnetName string

@description('The SKU of the Azure Container Registry')
@allowed([
  'Premium'
])
param acrSku string = 'Premium'

// Get existing VNet and subnet
resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: spokeVnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: spokeVnet
  name: subnetName
}

// Create Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
    networkRuleBypassOptions: 'None'
    zoneRedundancy: 'Disabled'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
    }
  }
}

// Create Private DNS Zone
resource privateZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

// Link Private DNS Zone to VNet
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateZone
  name: '${spokeVnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnet.id
    }
  }
}

// Create Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${acrName}-pe'
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${acrName}-connection'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

// Create DNS Zone Group
resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = {
  parent: privateEndpoint
  name: 'acrPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateZone.id
        }
      }
    ]
  }
}

// Outputs
output acrId string = acr.id
output acrLoginServer string = acr.properties.loginServer
output privateEndpointId string = privateEndpoint.id
