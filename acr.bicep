param location string
param resourceGroupName string
param acrName string
param acrSku string
param adminUserEnabled bool
//param enableDefender bool
//param logAnalyticsWorkspaceId string
param vnetName string
param subnetName string
param privateEndpointName string

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Disabled'
    policies: {
      softDelete: {
        enabled: true
      }
    }
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: vnetName
  scope: resourceGroup(resourceGroupName)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' existing = {
  name: subnetName
  parent: vnet
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: 'acrPrivateDnsZoneGroup'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'acrPrivateDnsZoneConfig'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
/*
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceId
  scope: resourceGroup(resourceGroupName)
}
*/
/*
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(logAnalyticsWorkspaceId)) {
  name: 'acrDiagnosticSettings'
  scope: acr
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
  }
} 
*/
/*
resource acrDefender 'Microsoft.Security/pricings@2020-01-01-preview' = if (enableDefender) {
  name: '${acrName}-Defender'
  properties: {
    pricingTier: 'Standard'
  }
} 
*/
