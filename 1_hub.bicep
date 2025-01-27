@description('Location for the resources.')
param location string = resourceGroup().location

@description('Hub VNet address space.')
param hubVnetAddressSpace array = [
  '10.0.0.0/24'
]

@description('Hub VNet Subnets configuration.')
var hubSubnets = [
  {
    name: 'ManagementSubnet'
    addressPrefix: '10.0.0.0/28'
  }
  {
    name: 'AzureFirewallSubnet'
    addressPrefix: '10.0.0.64/26'  // Changed to /26 to meet Azure Firewall requirements
  }
  {
    name: 'AzureFirewallManagementSubnet'
    addressPrefix: '10.0.0.128/26'  // Also enlarged for consistency
  }
  {
    name: 'AzureBastionSubnet'
    addressPrefix: '10.0.0.192/26'  // Adjusted to fit in remaining space
  }
]

// Hub VNet resource
resource hubVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'HubVNet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: hubVnetAddressSpace
    }
    subnets: [for subnet in hubSubnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

// Public IP for Bastion
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'HubBastionPublicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Bastion resource
resource bastion 'Microsoft.Network/bastionHosts@2021-08-01' = {
  name: 'HubBastion'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'BastionIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}

// Public IP for Azure Firewall
resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'FirewallPublicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Public IP for Firewall Management
resource firewallManagementPublicIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'FirewallManagementPublicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Azure Firewall with Basic SKU
resource azureFirewall 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  name: 'HubFirewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Basic'
    }
    ipConfigurations: [
      {
        name: 'FirewallIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'AzureFirewallSubnet')
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
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'AzureFirewallManagementSubnet')
        }
        publicIPAddress: {
          id: firewallManagementPublicIP.id
        }
      }
    }
  }
}

// // Create User-Assigned Managed Identity
// resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
//   name: 'AzDevOpsIdentity'
//   location: location
// }


// // // Placeholder for Azure DevOps setup (Deployment Scripts require managed identity)
// resource azdoOrgScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'CreateAzdoOrganization'
//   location: location
//   kind: 'AzureCLI'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//      // '/subscriptions/2213e8b1-dbc7-4d54-8aff-b5e315df5e5b/resourcegroups/1-95d24b02-playground-sandbox/providers/Microsoft.ManagedIdentity/userAssignedIdentities/AzDevOpsIdentity': {}
//      // Reference the created managed identity
//      '${managedIdentity.id}': {}
//     }
//   }
//   properties: {
//     azCliVersion: '2.0.81'
//     scriptContent: '''
//       # Install Azure DevOps extension
//       az extension add --name azure-devops  
//       az devops configure --defaults organization=https://dev.azure.com/greencube
//       # Add the user to the organization
//       az devops user add --email-id cloud_user_p_47836fb4@realhandsonlabs.com --license-type express --organization https://dev.azure.com/greencube

//       # Assign the user as a Project Administrator using REST API
//       az rest --method POST \
//         --uri https://dev.azure.com/greencube/MyProject/_apis/securityroles/scopes/Project/roleassignments?api-version=6.0-preview.1 \
//         --body '{
//           "principalName": "cloud_user_p_47836fb4@realhandsonlabs.com",
//           "roleName": "Project Administrators"
//         }'
//     '''
//     forceUpdateTag: 'v4'
//     retentionInterval: 'P1D'
//   }
// }
