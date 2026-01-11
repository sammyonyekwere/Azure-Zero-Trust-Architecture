// infra/modules/security/firewall.bicep
// --------------------------------------------------------------------------------
// PERIMETER SECURITY & INSPECTION
// --------------------------------------------------------------------------------
// Purpose: Inspect all North-South and East-West traffic.
// Key Zero Trust Concept: "Deep Packet Inspection" and "Threat Intelligence"

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
    name: 'Standard' // Standard SKU required for Firewall Standard/Premium
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// --------------------------------------------------------------------------------
// Firewall Policy
// --------------------------------------------------------------------------------
// We use a Policy rather than classic rules for better management and reuse.
resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-04-01' = {
  name: '${prefix}-fw-policy'
  location: location
  properties: {
    sku: {
      tier: 'Standard' // Standard is used for Demo. 'Premium' required for TLS Inspection.
    }
    // Threat Intelligence: Automatically blocks known malicious IPs/Domains.
    // Mode 'Deny' proactively blocks attacks, fulfilling "Assume Breach".
    threatIntelMode: 'Deny' 
    dnsSettings: {
      enableProxy: true // DNS Proxy allows FQDN filtering in Network Rules
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

// --------------------------------------------------------------------------------
// Diagnostic Settings
// --------------------------------------------------------------------------------
// "Verify Explicitly" requires data. We pipe all firewall logs to Sentinel.
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
