targetScope = 'subscription'

param resourceGroupName = 'meme-dev-rg'
param location = 'uksouth'
param tags = {
  environment: 'dev'
  project: 'meme'
}
param vnetName = 'meme-dev-vnet'
param vnetAddressPrefix = '10.0.2.0/22'
param subnets = [
  {
    name: 'meme-dev-mgmt-subnet'
    addressPrefix: '10.0.2.0/28'
  }
  {
    name: 'meme-dev-appgw-subnet'
    addressPrefix: '10.0.2.16/28'
  }
  {
    name: 'meme-dev-ilb-subnet'
    addressPrefix: '10.0.2.32/28'
  }
  {
    name: 'meme-dev-pe-subnet'
    addressPrefix: '10.0.2.64/26'
  }
  {
    name: 'meme-dev-aks-subnet'
    addressPrefix: '10.0.3.0/24'
  }
]
