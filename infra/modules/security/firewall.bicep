// infra/modules/security/firewall.bicep
param location string
param prefix string
param vnetName string
param logWorkspaceId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: vnetName
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${prefix}-fw-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-04-01' = {
  name: '${prefix}-fw-policy'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Deny'
    dnsSettings: {
      enableProxy: true
    }
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: '${prefix}-firewall'
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/AzureFirewallSubnet'
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
  dependsOn: [
    vnet
  ]
}

// Diagnostic Settings to send logs to Sentinel/Log Analytics
resource firewallDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${prefix}-fw-diag'
  scope: firewall
  properties: {
    workspaceId: logWorkspaceId
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
