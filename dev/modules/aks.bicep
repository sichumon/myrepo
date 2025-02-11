@description('The name of the AKS cluster')
param clusterName string

@description('The location for the AKS cluster')
param location string = resourceGroup().location

@description('The ID of the VNet containing the subnets')
param vnetId string

@description('The ID of the subnet where AKS nodes will be deployed')
param aksSubnetId string

@description('The ID of the existing Key Vault')
param keyVaultId string

@description('The ID of the existing Azure Container Registry')
param acrId string

@description('The ID of the existing Log Analytics workspace')
param logAnalyticsWorkspaceId string

@description('The ID of the disk encryption set')
param diskEncryptionSetId string = ''

@description('The service CIDR for kubernetes services')
param serviceCidr string = '172.16.0.0/16'

@description('The DNS service IP address')
param dnsServiceIP string = '172.16.0.10'

// Variables
var systemNodePoolName = 'systempool'
var userNodePoolName = 'userpool'
var privateDnsZoneName = 'privatelink.${location}.azmk8s.io'
var vnetName = split(vnetId, '/')[8]

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${vnetName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.30.7'
    dnsPrefix: '${clusterName}-dns'
    enableRBAC: true
    
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: privateDnsZone.id
      enablePrivateClusterPublicFQDN: false
    }
    
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'  // Enable Azure Network Policy
      loadBalancerSku: 'Standard'
      outboundType: 'userDefinedRouting'  // For Azure Firewall integration
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIP
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: 1
        }
      }
    }
    
    autoUpgradeProfile: {
      upgradeChannel: 'stable'
      enableAutoUpgrade: true
    }

    // Add maintenance window configuration
    maintenanceWindow: {
      allowed: [
        {
          day: 'Saturday'
          hours: [
            1
            2
            3
            4
          ]
        }
        {
          day: 'Sunday'
          hours: [
            1
            2
            3
            4
          ]
        }
      ]
      notAllowed: []
    }
    
    securityProfile: {
      defender: {
        logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceId
        securityMonitoring: {
          enabled: true
        }
      }
      workloadIdentity: {
        enabled: true
      }
      imageCleaner: {
        enabled: true
        intervalHours: 48
      }
    }
    
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
    
    agentPoolProfiles: [
      {
        name: systemNodePoolName
        count: 3
        vmSize: 'Standard_DS4_v3'
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        maxPods: 110
        vnetSubnetID: aksSubnetId
        enableAutoScaling: false
        type: 'VirtualMachineScaleSets'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        diskEncryptionSetID: !empty(diskEncryptionSetId) ? diskEncryptionSetId : null
        podDisruptionBudget: {
          enabled: true
          minAvailable: 1
        }
      }
      {
        name: userNodePoolName
        count: 3
        vmSize: 'Standard_DS8_v3'
        mode: 'User'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        maxPods: 110
        vnetSubnetID: aksSubnetId
        enableAutoScaling: true
        minCount: 3
        maxCount: 5
        type: 'VirtualMachineScaleSets'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        diskEncryptionSetID: !empty(diskEncryptionSetId) ? diskEncryptionSetId : null
        podDisruptionBudget: {
          enabled: true
          minAvailable: 1
        }
      }
    ]
    
    addonProfiles: {
      kedaAddon: {
        enabled: true
      }
      daprAddon: {
        enabled: true
      }
      azureKeyvaultSecretsProviderAddon: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }
      }
      azurepolicyAddon: {
        enabled: true
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
      azureDefender: {
        enabled: true
      }
    }
  }
}

resource acrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksCluster.id, acrId, 'acrpull')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: aksCluster.identity.principalId
    principalType: 'ServicePrincipal'
  }
  scope: resourceGroup()
}

resource kvSecretsUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksCluster.id, keyVaultId, 'secrets-user')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: aksCluster.identity.principalId
    principalType: 'ServicePrincipal'
  }
  scope: resourceGroup()
}

output clusterName string = aksCluster.name
output clusterIdentityPrincipalId string = aksCluster.identity.principalId
output privateDnsZoneId string = privateDnsZone.id
---------
// main.bicep

// Common parameters
param location string = resourceGroup().location
param environment string
param prefix string

// ACR parameters
param acrSku string = 'Premium'

// Key Vault parameters
param kvSku string = 'standard'

// AKS parameters
param aksVersion string = '1.30.7'
param aksSubnetId string
param vnetId string

// Create ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: '${prefix}${environment}acr'
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Disabled'
  }
}

// Create Key Vault
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${prefix}${environment}kv'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: kvSku
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
  }
}

// Create Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${prefix}${environment}law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Deploy AKS using module
module aks './aks-private-cluster.bicep' = {
  name: 'aks-deployment'
  params: {
    clusterName: '${prefix}${environment}aks'
    location: location
    vnetId: vnetId
    aksSubnetId: aksSubnetId
    keyVaultId: kv.id        // Reference KV resource id
    acrId: acr.id           // Reference ACR resource id
    logAnalyticsWorkspaceId: logAnalytics.id  // Reference Log Analytics resource id
  }
  dependsOn: [
    acr
    kv
    logAnalytics
  ]
}

// Outputs
output acrLoginServer string = acr.properties.loginServer
output aksClusterName string = aks.outputs.clusterName
output aksIdentityPrincipalId string = aks.outputs.clusterIdentityPrincipalId
---
// main.bicepparam

using './main.bicep'

param prefix = 'proj'
param environment = 'prod'
param location = 'eastus'

// Network parameters
param vnetId string = '/subscriptions/sub-id/resourceGroups/rg-name/providers/Microsoft.Network/virtualNetworks/vnet-name'
param aksSubnetId string = '/subscriptions/sub-id/resourceGroups/rg-name/providers/Microsoft.Network/virtualNetworks/vnet-name/subnets/aks-subnet'

// Optional parameters with defaults defined in main.bicep
param acrSku = 'Premium'
param kvSku = 'standard'
param aksVersion = '1.30.7'
