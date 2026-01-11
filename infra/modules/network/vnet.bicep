// infra/modules/network/vnet.bicep
// --------------------------------------------------------------------------------
// NETWORK SEGMENTATION & MICRO-SEGMENTATION
// --------------------------------------------------------------------------------
// Purpose: Create a network where lateral movement is blocked by default.
// Key Zero Trust Concept: "Verify Explicitly" and "Least Privileged Access"
// We achieve this by attaching an NSG with a 'DenyAllInbound' rule to all subnets.

param location string
param prefix string
param vnetAddressPrefix string = '10.0.0.0/16'

// --------------------------------------------------------------------------------
// Network Security Group (NSG)
// --------------------------------------------------------------------------------
// By default, Azure VNets allow intra-VNet traffic. We override this.
// This generic "Default Deny" NSG is applied to subnets to ensure that
// NO traffic flows unless we explicitly write an Allow rule later.
resource defaultNsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${prefix}-default-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4096 // Lowest priority to act as a catch-all
          access: 'Deny'
          direction: 'Inbound'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          description: 'Zero Trust enforced: Deny all traffic by default. Explicit allows required.'
        }
      }
    ]
  }
}

// --------------------------------------------------------------------------------
// Virtual Network
// --------------------------------------------------------------------------------
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${prefix}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          // Firewalls manage their own security; no NSG needed here.
        }
      }
      {
        name: 'WorkloadSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: defaultNsg.id // APPLYING ZERO TRUST DENY POLICY
          }
        }
      }
      {
        name: 'PrivateEndpointSubnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: {
            id: defaultNsg.id // APPLYING ZERO TRUST DENY POLICY
          }
          // Private Network Policies must be disabled to allow Private Endpoints (depending on Azure API version)
          privateEndpointNetworkPolicies: 'Disabled' 
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name
