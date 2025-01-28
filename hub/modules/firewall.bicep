// modules/firewall.bicep
param location string
param firewallName string
param skuTier string
param firewallSubnetId string
param managementSubnetId string

resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: '${firewallName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallManagementPublicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: '${firewallName}-mgmt-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: skuTier
    }
    ipConfigurations: [
      {
        name: 'FirewallIpConfig'
        properties: {
          subnet: {
            id: firewallSubnetId
          }
          publicIPAddress: {
            id: firewallPublicIP.id
          }
        }
      }
    ]
    managementIpConfiguration: {
      name: 'FirewallManagementIpConfig'
      properties: {
        subnet: {
          id: managementSubnetId
        }
        publicIPAddress: {
          id: firewallManagementPublicIP.id
        }
      }
    }
  }
}
