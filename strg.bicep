@description('Environment tag')
param env string

@description('Project tag')
param proj string

@description('Name of the storage account')
param storageAccountName string

//@description('Name of the resource group for the storage account')
//param resourceGroupName string

@description('Location of the storage account')
param location string

@description('Name of the virtual network')
param virtualNetworkName string

@description('Name of the subnet for private endpoint')
param subnetName string

//@description('Log Analytics workspace ID')
//param logAnalyticsWorkspaceId string

//@description('Defender for Cloud Plan ID')
//param defenderPlanId string

param skuName string
param storageKind string
param deleteRetentionPolicy int

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: storageKind
  properties: {
    accessTier: 'Hot'
  }
  tags: {
    env: env
    proj: proj
  }
}

resource privateEndpointBlob 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}-blob-pe'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-blob'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateEndpointFile 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}-file-pe'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-file'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource privateEndpointQueue 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}-queue-pe'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-queue'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

resource privateEndpointTable 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}-table-pe'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-table'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: deleteRetentionPolicy
    }
  }
}
/*
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceId
}

resource defender 'Microsoft.Security/pricings@2021-01-15' = {
  name: defenderPlanId
  properties: {
    pricingTier: 'Standard'
  }
}

resource diagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-diagnostic'
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
        retentionPolicy: {
          enabled: false
        }
      },
      {
        category: 'StorageWrite'
        enabled: true
        retentionPolicy: {
          enabled: false
        }
      },
      {
        category: 'StorageDelete'
        enabled: true
        retentionPolicy: {
          enabled: false
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
        }
      }
    ]
  }
}
*/
resource storageAccountLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: '${storageAccountName}-lock'
  properties: {
    level: 'CanNotDelete'
    notes: 'This lock protects the storage account from accidental deletion.'
  }
  //scope: resourceId('Microsoft.Storage/storageAccounts', storageAccountName)
}

