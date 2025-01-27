@description('The name of the existing hub virtual network')
param hubVnetName string

@description('The name of the existing subnet where VMs will be deployed')
param subnetName string

@description('Username for the Virtual Machine')
param adminUsername string

@description('Password for the Virtual Machine')
@secure()
param adminPassword string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Size of the virtual machine')
param vmSize string = 'Standard_D2s_v3'

// VM Names
var devopsAgentVMName = 'vm-devops-agent'
var aksManagementVMName = 'vm-aks-mgmt'

// Get existing VNet and subnet
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: hubVnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: hubVnet
  name: subnetName
}

// Network Interfaces
resource devopsAgentNic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${devopsAgentVMName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource aksManagementNic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: '${aksManagementVMName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

// DevOps Agent VM (Now Ubuntu instead of Windows)
resource devopsAgentVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: devopsAgentVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: devopsAgentVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '20.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: devopsAgentNic.id
        }
      ]
    }
  }
}

// DevOps Agent VM Extension for setup
resource devopsAgentExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: devopsAgentVM
  name: 'DevOpsAgentSetup'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/youraccount/scripts/main/setup-devops-agent.sh' // Replace with your script URL
      ]
      commandToExecute: './setup-devops-agent.sh'
    }
  }
}

// AKS Management VM (Remains Ubuntu)
resource aksManagementVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: aksManagementVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: aksManagementVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '20.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: aksManagementNic.id
        }
      ]
    }
  }
}

// AKS Management VM Extension for installing required tools
resource aksManagementExtension 'Microsoft.Compute/virtualMachines/extensions@2023-07-01' = {
  parent: aksManagementVM
  name: 'AKSToolsSetup'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/youraccount/scripts/main/setup-aks-tools.sh' // Replace with your script URL
      ]
      commandToExecute: './setup-devops-agent.sh'
    }
  }
}

output devopsAgentVMId string = devopsAgentVM.id
output aksManagementVMId string = aksManagementVM.id
