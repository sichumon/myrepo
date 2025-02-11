@description('The name of the AKS cluster')
param clusterName string

@description('The location for the AKS cluster')
param location string = resourceGroup().location

@description('The ID of the VNet containing the subnets')
param vnetId string

@description('The ID of the subnet where AKS nodes will be deployed')
param aksSubnetId string

@description('The ID of the existing Key Vault')
param keyVaultId string = '/subscriptions/0cc20e92-7212-41e7-bf3f-2ebb8b14dcfb/resourceGroups/meme-dev-rg/providers/Microsoft.KeyVault/vaults/meme-dev-keyvlt-01'

@description('The ID of the existing Azure Container Registry')
param acrId string

@description('The ID of the existing Log Analytics workspace')
param logAnalyticsWorkspaceId string

// @description('The ID of the disk encryption set')
// param diskEncryptionSetId string = ''

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
      nodeOSUpgradeChannel: 'NodeImage'
    }

    // Add maintenance window configuration
    // maintenanceWindow: {
    //   allowed: [
    //     {
    //       day: 'Saturday'
    //       hours: [
    //         1
    //         2
    //         3
    //         4
    //       ]
    //     }
    //     {
    //       day: 'Sunday'
    //       hours: [
    //         1
    //         2
    //         3
    //         4
    //       ]
    //     }
    //   ]
    //   notAllowed: []
    // }
    
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
    
    oidcIssuerProfile: {
      enabled: true
    }

    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
    
    agentPoolProfiles: [
      {
        name: systemNodePoolName
        count: 3
        vmSize: 'standard_d4s_v3'
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
      }
      {
        name: userNodePoolName
        count: 3
        vmSize: 'standard_d8s_v3'
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
      }
    ]
    
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }
      }
      azurepolicy: {
        enabled: true
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
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
