// infra/main.bicep
// --------------------------------------------------------------------------------
// ZERO TRUST ARCHITECTURE - ORCHESTRATOR
// --------------------------------------------------------------------------------
// This Bicep file acts as the master orchestrator. It deploys resources in a strictly
// ordered dependency chain to ensure the "Security First" principle:
// 1. Logging (Observability plane must be ready before resources generate logs)
// 2. Network (Virtual Network backbone with Zero Trust segmentation)
// 3. Security (Firewall to act as the central policy enforcement point)

targetScope = 'subscription'

param location string = 'eastus'
param prefix string = 'zt-demo'

// Resource Group is the logical container for all our Zero Trust assets
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefix}-rg'
  location: location
}

// Module 1: Observability
// Deployed first so we can pass the workspaceId to other resources immediately.
// Zero Trust requires "Assume Breach", which means we must log everything from second zero.
module logging 'modules/security/logging.bicep' = {
  scope: rg
  name: 'logging-deploy'
  params: {
    location: location
    prefix: prefix
  }
}

// Module 2: Network Foundation
// Sets up the VNet with micro-segmented subnets and "Deny-by-Default" NSGs.
module network 'modules/network/vnet.bicep' = {
  scope: rg
  name: 'network-deploy'
  params: {
    location: location
    prefix: prefix
  }
}

// Module 3: Perimeter Security
// Deploys Azure Firewall Premium.
// Depends on Network (needs VNet) and Logging (needs Workspace).
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
