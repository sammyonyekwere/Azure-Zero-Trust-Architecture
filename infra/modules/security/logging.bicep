// infra/modules/security/logging.bicep
// --------------------------------------------------------------------------------
// OBSERVABILITY & SIEM
// --------------------------------------------------------------------------------
// Purpose: Centralized logging and threat detection.
// Key Zero Trust Concept: "Assume Breach"
// By enabling Sentinel immediately, we start building a baseline of "normal" 
// behavior so we can detect anomalies (breaches) faster.

param location string
param prefix string
param retentionInDays int = 30

// --------------------------------------------------------------------------------
// Log Analytics Workspace
// --------------------------------------------------------------------------------
// The "Data Lake" for all security logs (Firewall, NSG, KeyVault, etc.)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${prefix}-log-workspace'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
}

// --------------------------------------------------------------------------------
// Microsoft Sentinel
// --------------------------------------------------------------------------------
// Enable Security Insights (Sentinel) on top of Log Analytics.
resource sentinel 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
  location: location
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
  plan: {
    name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}

output workspaceId string = logAnalyticsWorkspace.id
