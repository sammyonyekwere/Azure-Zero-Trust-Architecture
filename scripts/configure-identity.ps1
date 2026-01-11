# scripts/configure-identity.ps1
# --------------------------------------------------------------------------------
# ZERO TRUST IDENTITY CONFIGURATION (GUIDANCE)
# --------------------------------------------------------------------------------
# Purpose: To automate the configuration of Identity as the new Security Perimeter.
# Key Zero Trust Concept: "Verify Explicitly"
# We never trust a user just because they have the correct password. We verify:
# 1. Strong Authentication (MFA)
# 2. Least Privilege (PIM)

# Requires 'Microsoft.Graph.Identity.SignIns' and 'Microsoft.Graph.Identity.Governance' modules

Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "PrivilegedAccess.Read.AzureADGroup"

# --------------------------------------------------------------------------------
# 1. Conditional Access Policy: Administrator Protection
# --------------------------------------------------------------------------------
# Why: Administrators are High Value Targets (HVTs). 
# Policy: If a user has an Admin role, they MUST perform MFA, regardless of location.
# This prevents "Password Spray" attacks from succeeding against admin accounts.

$caPolicyName = "Zero Trust - Require MFA for Admins"
$existingPolicy = Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq '$caPolicyName'"

if ($null -eq $existingPolicy) {
    Write-Host "Creating CA Policy: $caPolicyName"
    
    $conditions = @{
        "applications" = @{ "includeApplications" = @("All") }; # Protects Azure Portal, CLI, PowerShell, etc.
        "users" = @{ "includeRoles" = @("62e90394-69f5-4237-9190-012177145e10") }; # Global Admin Role ID (Example)
        "locations" = @{ "includeLocations" = @("All") }; # Zero Trust: Location is not a trust signal alone.
        "clientAppTypes" = @("all");
    }

    $grantControls = @{
        "operator" = "OR";
        "builtInControls" = @("mfa"); # The explicit verification requirement
    }

    $params = @{
        "displayName" = $caPolicyName;
        "state" = "enabled";
        "conditions" = $conditions;
        "grantControls" = $grantControls;
    }

    # New-MgIdentityConditionalAccessPolicy -BodyParameter $params
    Write-Host "NOTE: Review the script to uncomment the creation line. Running in Safe Mode (Guidance Only)."
    Write-Host "Standard CA Policy Definition created in Variable `$params"
} else {
    Write-Host "Policy $caPolicyName already exists."
}

# --------------------------------------------------------------------------------
# 2. Privileged Identity Management (PIM) Guidance
# --------------------------------------------------------------------------------
# Key Zero Trust Concept: "Use Least Privileged Access"
# Admins should not have "Standing Access". They should be "Eligible" and request access
# only when needed (Just-In-Time).
#
# Action Item:
# 1. Go to Azure Portal -> PIM -> Azure AD Roles.
# 2. Change assignments from 'Active' to 'Eligible'.
# 3. Enforce 'Justification' on activation.

Write-Host "`n--- Privileged Identity Management (PIM) ---"
Write-Host "Ensure that all High Privilege roles (Global Admin, Security Admin) are set to 'Eligible' instead of 'Active'."
Write-Host "You can audit this via the Azure Portal -> PIM -> Azure AD Roles -> Assignments."
