@description('Environment tag')
param env string

@description('Project tag')
param proj string

@description('Name of the storage account')
param storageAccountName string

@description('Name of the resource group for the storage account')
param resourceGroupName string

@description('Location of the storage account')
param location string

@description('Name of the virtual network')
param virtualNetworkName string

@description('Name of the subnet for private endpoint')
param subnetName string

param skuName string
param storageKind string
param minimumTlsVersion string
param enableEncryption bool
param privateDnsZoneName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: storageKind
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: minimumTlsVersion
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'None'
    }
    encryption: {
      services: {
        blob: {
          enabled: enableEncryption
        }
        file: {
          enabled: enableEncryption
        }
        table: {
          enabled: enableEncryption
        }
        queue: {
          enabled: enableEncryption
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
  tags: {
    env: env
    proj: proj
  }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  parent: blobServices
  name: 'myblobcontainer'
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: '${storageAccountName}-pe'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'storage'
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

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vnet-link'
  parent: privateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
    registrationEnabled: false
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: privateDnsZoneName
        privateDnsZoneId: privateDnsZone.id
      }
    ]
  }
}

resource storageAccountLock 'Microsoft.Authorization/locks@2020-05-01' = {
  name: '${storageAccountName}-lock'
  properties: {
    level: 'CanNotDelete'
    notes: 'This lock protects the storage account from accidental deletion.'
  }
  scope: storageAccount
}
