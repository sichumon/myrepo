// Parameters
param storageAccountName string = 'nkprivstrg12345'
param location string = 'eastus'
param resourceGroupName string = '1-ca1ae188-playground-sandbox'
param virtualNetworkName string = 'nkpractice'
param subnetName string = 'pe-subnet'
param env string = 'dev'
param proj string = 'poc'
param skuName string
param storageKind string
param minimumTlsVersion string
param enableEncryption bool

// Storage Account (Private)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: storageKind
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: minimumTlsVersion
    networkAcls: {
      defaultAction: 'Deny' // Block public access
      bypass: 'AzureServices'
    }
    encryption: {
      services: {
        blob: { enabled: enableEncryption }
        file: { enabled: enableEncryption }
      }
      keySource: 'Microsoft.Storage'
    }
  }
  tags: {
    env: env
    proj: proj
  }
}

// Private DNS Zones (Explicitly Defined)
resource privateDnsBlob 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
}

resource privateDnsFile 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.file.${environment().suffixes.storage}'
  location: 'global'
}

resource privateDnsQueue 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.queue.${environment().suffixes.storage}'
  location: 'global'
}

resource privateDnsTable 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink.table.${environment().suffixes.storage}'
  location: 'global'
}

// Link Private DNS Zones to VNET (Explicit)
resource vnetLinkBlob 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsBlob
  name: '${virtualNetworkName}-blob-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
    registrationEnabled: false
  }
}

resource vnetLinkFile 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsFile
  name: '${virtualNetworkName}-file-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
    registrationEnabled: false
  }
}

resource vnetLinkQueue 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsQueue
  name: '${virtualNetworkName}-queue-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
    registrationEnabled: false
  }
}

resource vnetLinkTable 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsTable
  name: '${virtualNetworkName}-table-dns-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
    }
    registrationEnabled: false
  }
}

// Private Endpoints for Storage Services
resource privateEndpointBlob 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: '${storageAccountName}-pe-blob'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [{
      name: '${storageAccountName}-blob-connection'
      properties: {
        privateLinkServiceId: storageAccount.id
        groupIds: ['blob']
      }
    }]
  }
}

resource privateEndpointFile 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: '${storageAccountName}-pe-file'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [{
      name: '${storageAccountName}-file-connection'
      properties: {
        privateLinkServiceId: storageAccount.id
        groupIds: ['file']
      }
    }]
  }
}

resource privateEndpointQueue 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: '${storageAccountName}-pe-queue'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [{
      name: '${storageAccountName}-queue-connection'
      properties: {
        privateLinkServiceId: storageAccount.id
        groupIds: ['queue']
      }
    }]
  }
}

resource privateEndpointTable 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: '${storageAccountName}-pe-table'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [{
      name: '${storageAccountName}-table-connection'
      properties: {
        privateLinkServiceId: storageAccount.id
        groupIds: ['table']
      }
    }]
  }
}

resource privateDnsZoneGroupBlob 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = {
  name: '${storageAccountName}-blob-dns-zone-group'
  parent: privateEndpointBlob
  properties: {
    privateDnsZoneConfigs: [{
      name: 'blob-dns-zone-config'
      properties: {
        privateDnsZoneId: privateDnsBlob.id
      }
    }]
  }
}
resource privateDnsZoneGroupFile 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = {
  name: '${storageAccountName}-file-dns-zone-group'
  parent: privateEndpointFile
  properties: {
    privateDnsZoneConfigs: [{
      name: 'file-dns-zone-config'
      properties: {
        privateDnsZoneId: privateDnsFile.id
      }
    }]
  }
}

resource privateDnsZoneGroupQueue 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = {
  name: '${storageAccountName}-queue-dns-zone-group'
  parent: privateEndpointQueue
  properties: {
    privateDnsZoneConfigs: [{
      name: 'queue-dns-zone-config'
      properties: {
        privateDnsZoneId: privateDnsQueue.id
      }
    }]
  }
}

resource privateDnsZoneGroupTable 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = {
  name: '${storageAccountName}-table-dns-zone-group'
  parent: privateEndpointTable
  properties: {
    privateDnsZoneConfigs: [{
      name: 'table-dns-zone-config'
      properties: {
        privateDnsZoneId: privateDnsTable.id
      }
    }]
  }
}
