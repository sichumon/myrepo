@description('The location where resources will be deployed')
param location string = resourceGroup().location

@description('The name of the AKS cluster')
param resourceName string

@description('The upgrade channel for the AKS cluster')
param upgradeChannel string = 'stable'

@description('Enable paid SKU for SLA')
param AksPaidSkuForSLA bool = true

@description('The type of system pool')
param SystemPoolType string = 'Standard'

@description('Maximum agent count')
param agentCountMax int = 20

@description('Enable custom VNET')
param custom_vnet bool = true

@description('Enable Azure Bastion')
param bastion bool = true

@description('Enable Azure AD integration')
param enable_aad bool = true

@description('Disable local accounts')
param AksDisableLocalAccounts bool = true

@description('Enable Azure RBAC')
param enableAzureRBAC bool = true

@description('Admin Principal ID')
param adminPrincipalId string

@description('ACR SKU')
param registries_sku string = 'Premium'

@description('Principal ID for ACR Push Role')
param acrPushRolePrincipalId string

@description('Enable ACR Trust Policy')
param enableACRTrustPolicy bool = true

@description('Enable Azure Firewall')
param azureFirewalls bool = true

@description('Enable Private Links')
param privateLinks bool = true

@description('Key Vault IP allowlist')
param keyVaultIPAllowlist array

@description('Enable telemetry')
param enableTelemetry bool = false

@description('Enable OMS agent')
param omsagent bool = true

@description('Log retention in days')
param retentionInDays int = 30

@description('Network policy')
param networkPolicy string = 'azure'

@description('Azure policy')
param azurepolicy string = 'deny'

@description('Availability zones')
param availabilityZones array = ['1', '2', '3']

@description('Enable private cluster')
param enablePrivateCluster bool = true

@description('Enable Application Gateway ingress')
param ingressApplicationGateway bool = true

@description('Application Gateway count')
param appGWcount int = 0

@description('Application Gateway SKU')
param appGWsku string = 'WAF_v2'

@description('Application Gateway max count')
param appGWmaxCount int = 10

@description('Enable App Gateway Key Vault integration')
param appgwKVIntegration bool = true

@description('AKS outbound traffic type')
param aksOutboundTrafficType string = 'userDefinedRouting'

@description('Enable Key Vault CSI driver')
param keyVaultAksCSI bool = true

@description('Create Key Vault')
param keyVaultCreate bool = true

@description('Key Vault Officer Role Principal ID')
param keyVaultOfficerRolePrincipalId string

@description('Enable Dapr addon')
param daprAddon bool = true

@description('Enable Dapr addon HA')
param daprAddonHA bool = true

@description('Enable ACR private pool')
param acrPrivatePool bool = true

@description('Enable KEDA addon')
param kedaAddon bool = true

resource aks 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
  name: resourceName
  location: location
  sku: {
    name: 'Basic'
    tier: AksPaidSkuForSLA ? 'Paid' : 'Free'
  }
  properties: {
    kubernetesVersion: '1.27.7'
    dnsPrefix: resourceName
    enableRBAC: true
    disableLocalAccounts: AksDisableLocalAccounts
    aadProfile: enable_aad ? {
      managed: true
      enableAzureRBAC: enableAzureRBAC
      adminGroupObjectIDs: [adminPrincipalId]
    } : null
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: networkPolicy
      outboundType: aksOutboundTrafficType
    }
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 3
        vmSize: SystemPoolType
        maxCount: agentCountMax
        availabilityZones: availabilityZones
        enableAutoScaling: true
        vnetSubnetID: custom_vnet ? '${vnet.id}/subnets/SystemSubnet' : null
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: omsagent
        config: {
          logAnalyticsWorkspaceResourceID: omsagent ? workspace.id : null
        }
      }
      ingressApplicationGateway: {
        enabled: ingressApplicationGateway
        config: {
          applicationGatewayCount: appGWcount
          applicationGatewaySku: appGWsku
          applicationGatewayMaxCount: appGWmaxCount
        }
      }
      azureKeyvaultSecretsProvider: {
        enabled: keyVaultAksCSI
      }
      dapr: {
        enabled: daprAddon
        config: {
          enableHA: daprAddonHA ? 'true' : 'false'
        }
      }
      kedaAddon: {
        enabled: kedaAddon
      }
    }
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
    }
  }
}

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (omsagent) {
  name: '${resourceName}-workspace'
  location: location
  properties: {
    retentionInDays: retentionInDays
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = if (custom_vnet) {
  name: '${resourceName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'SystemSubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

output controlPlaneFQDN string = aks.properties.fqdn
output kubeletIdentity string = aks.properties.identityProfile.kubeletidentity.objectId
