// infra/main.bicep
targetScope = 'subscription'

param location string = 'eastus'
param prefix string = 'zt-demo'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefix}-rg'
  location: location
}

module logging 'modules/security/logging.bicep' = {
  scope: rg
  name: 'logging-deploy'
  params: {
    location: location
    prefix: prefix
  }
}

module network 'modules/network/vnet.bicep' = {
  scope: rg
  name: 'network-deploy'
  params: {
    location: location
    prefix: prefix
  }
}

module firewall 'modules/security/firewall.bicep' = {
  scope: rg
  name: 'firewall-deploy'
  params: {
    location: location
    prefix: prefix
    vnetName: network.outputs.vnetName
    logWorkspaceId: logging.outputs.workspaceId
  }
  dependsOn: [
    network
  ]
}
