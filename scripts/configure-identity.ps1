# scripts/configure-identity.ps1
# Requires 'Microsoft.Graph.Identity.SignIns' and 'Microsoft.Graph.Identity.Governance' modules

Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "PrivilegedAccess.Read.AzureADGroup"

# 1. Create Conditional Access Policy: Require MFA for Administrators
$caPolicyName = "Zero Trust - Require MFA for Admins"
$existingPolicy = Get-MgIdentityConditionalAccessPolicy -Filter "displayName eq '$caPolicyName'"

if ($null -eq $existingPolicy) {
    Write-Host "Creating CA Policy: $caPolicyName"
    
    $conditions = @{
        "applications" = @{ "includeApplications" = @("All") };
        "users" = @{ "includeRoles" = @("62e90394-69f5-4237-9190-012177145e10") }; # Global Admin Role ID (Example)
        "locations" = @{ "includeLocations" = @("All") };
        "clientAppTypes" = @("all");
    }

    $grantControls = @{
        "operator" = "OR";
        "builtInControls" = @("mfa");
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

# 2. PIM Guidance
Write-Host "`n--- Privileged Identity Management (PIM) ---"
Write-Host "Ensure that all High Privilege roles (Global Admin, Security Admin) are set to 'Eligible' instead of 'Active'."
Write-Host "You can audit this via the Azure Portal -> PIM -> Azure AD Roles -> Assignments."
