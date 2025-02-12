// az deployment group create --resource-group meme-dev-rg --template-file dapr.bicep --parameters clusterName=meme-dev-aks

@description('The name of the Managed Cluster resource.')
param clusterName string

resource existingManagedClusters 'Microsoft.ContainerService/managedClusters@2023-05-02-preview' existing = {
  name: clusterName
}

resource daprExtension 'Microsoft.KubernetesConfiguration/extensions@2022-11-01' = {
  name: 'dapr'
  scope: existingManagedClusters
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    autoUpgradeMinorVersion: false
    configurationProtectedSettings: {}
    configurationSettings: {
      'global.clusterType': 'managedclusters'
    }
    extensionType: 'microsoft.dapr'
    releaseTrain: 'stable'
    scope: {
      cluster: {
        releaseNamespace: 'dapr-system'
      }
    }
    // version: '1.14.4'
  }
}
