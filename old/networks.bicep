
@description('Location for all resources.')
param location string = resourceGroup().location

@description('IP address range for the Hub VNet.')
param hubAddressSpace array = [
  '10.0.0.0/16'
]

@description('IP address range for the Spoke VNet hosting AKS.')
param aksSpokeAddressSpace array = [
  '10.1.0.0/16'
]

@description('Name of the Hub VNet.')
param hubVnetName string = 'HubVNet'

@description('Name of the Spoke VNet for AKS.')
param aksSpokeVnetName string = 'AKSClusterSpokeVNet'

@description('Subnet configuration for the Hub VNet.')
var hubSubnets = [
  {
    name: 'ManagementSubnet'
    addressPrefix: '10.0.1.0/24'
  }
  {
    name: 'AzureFirewallSubnet'
    addressPrefix: '10.0.2.0/24'
  }
]

@description('Subnet configuration for the Spoke VNet (AKS).')
var aksSpokeSubnets = [
  {
    name: 'AKSNodeSubnet'
    addressPrefix: '10.1.1.0/24'
  }
  {
    name: 'IngressSubnet'
    addressPrefix: '10.1.2.0/24'
  }
  {
    name: 'PrivateLinkSubnet'
    addressPrefix: '10.1.3.0/24'
  }
]

@description('Enable or disable DDoS Protection for Hub VNet.')
param enableDdosProtection bool = false

// Hub VNet Resource
resource hubVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: hubAddressSpace
    }
    subnets: [for subnet in hubSubnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

// Spoke VNet Resource for AKS
resource aksSpokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: aksSpokeVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: aksSpokeAddressSpace
    }
    subnets: [for subnet in aksSpokeSubnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

// Hub-to-Spoke Peering
resource hubToAksSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: 'HubToAksSpoke'
  parent: hubVnet
  properties: {
    remoteVirtualNetwork: {
      id: aksSpokeVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
  }
}

// Spoke-to-Hub Peering
resource aksSpokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: 'AksSpokeToHub'
  parent: aksSpokeVnet
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: false
  }
}

// Optional: Azure Firewall (if needed)
resource firewall 'Microsoft.Network/azureFirewalls@2021-08-01' = if(enableDdosProtection) {
  name: 'HubFirewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'FirewallIpConfig'
        properties: {
          subnet: {
            id: hubVnet.properties.subnets[1].id // AzureFirewallSubnet
          }
        }
      }
    ]
  }
}

output hubVnetId string = hubVnet.id
output aksSpokeVnetId string = aksSpokeVnet.id
