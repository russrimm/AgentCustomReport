<#
.SYNOPSIS
    Complete Copilot Studio Agent Report - Single Script Solution (v1.0)
    
.DESCRIPTION
    Retrieves comprehensive agent data from multiple sources:
    - Power Platform Admin API: Environments metadata
    - Dataverse API: Agent metadata (name, environment, owner, timestamps, solution ID)
    - Licensing API: Credits consumption (billed and non-billed) with 365-day lookback
    
    Returns comprehensive agent data in a single CSV report with automatic authentication handling.
    
    Uses Azure Resource Graph API with direct KQL queries (official Microsoft API) instead of
    the Power Platform Inventory API which has recent issues with KQLOM JSON format.
    
.PARAMETER TenantId
    Azure AD Tenant ID (required)
    Default: f33d7d7f-d7a8-49c9-9dfe-af8c9ca30123
    
.PARAMETER ClientId
    Azure AD Application (Client) ID for service principal authentication
    Required for unattended execution
    
.PARAMETER ClientSecret
    Azure AD Application Client Secret for service principal authentication
    Required for unattended execution
    
.PARAMETER LookbackDays
    Number of days to look back for credits consumption data
    Default: 365 days (recommended for complete historical data)
    
.EXAMPLE
    .\Get-CompleteCopilotReport.ps1 -ClientId "<app-id>" -ClientSecret "<secret>"
    Generates complete report using 365-day lookback
    
.EXAMPLE
    .\Get-CompleteCopilotReport.ps1 -ClientId "<app-id>" -ClientSecret "<secret>" -LookbackDays 90
    Generates report with 90-day credits lookback
    
.NOTES
    Version: 1.0
    Author: Agent Custom Report Solution
    Last Updated: 2026-01-16
    
    Authentication: OAuth 2.0 Client Credentials Flow (unattended)
    - Licensing API: https://licensing.powerplatform.microsoft.com scope
    - Dataverse: https://api.crm.dynamics.com scope
    
    Required Service Principal Permissions:
    - Power Platform: Power Platform Administrator role
    
    Output: CopilotAgents_CompleteReport_TIMESTAMP.csv
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$false)]
    [string]$ClientSecret,
    
    [Parameter(Mandatory=$false)]
    [int]$LookbackDays = 365
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ErrorActionPreference = "Continue"

Write-Host @"

╔══════════════════════════════════════════════════════════════════════╗
║   COMPLETE COPILOT STUDIO AGENT REPORT                              ║
║   Single Script Solution - All Available Fields                     ║
╚══════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# ============================================================================
# SERVICE PRINCIPAL SETUP
# ============================================================================

# Check if credentials are provided
if (-not $ClientId -or -not $ClientSecret) {
    Write-Host "`n⚠️  No service principal credentials provided" -ForegroundColor Yellow
    
    # Prompt for TenantId if not provided
    if (-not $TenantId) {
        Write-Host "`n📋 Enter your Azure AD Tenant ID" -ForegroundColor Cyan
        Write-Host "   (Find this in Azure Portal → Azure Active Directory → Properties)" -ForegroundColor Gray
        $TenantId = Read-Host "Tenant ID"
        
        if ([string]::IsNullOrWhiteSpace($TenantId)) {
            Write-Host "`n❌ Tenant ID is required" -ForegroundColor Red
            exit 1
        }
    }
    
    Write-Host "`nDo you need to create a new service principal? (Y/N)" -ForegroundColor Cyan
    $createSP = Read-Host "Choice"
    
    if ($createSP -eq "Y" -or $createSP -eq "y") {
        Write-Host "`n🔧 SERVICE PRINCIPAL SETUP" -ForegroundColor Yellow
        Write-Host "   Checking for Power Platform CLI..." -ForegroundColor Gray
        
        # Check if pac CLI is installed
        $pacInstalled = $null -ne (Get-Command pac -ErrorAction SilentlyContinue)
        
        if (-not $pacInstalled) {
            Write-Host "   ❌ Power Platform CLI (pac) is not installed" -ForegroundColor Red
            Write-Host "   Installing Power Platform CLI...`n" -ForegroundColor Yellow
            
            # Try winget first
            $wingetInstalled = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)
            
            if ($wingetInstalled) {
                Write-Host "   Using winget to install pac CLI..." -ForegroundColor Gray
                winget install Microsoft.PowerPlatformCLI --silent --accept-source-agreements --accept-package-agreements
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   ✓ Power Platform CLI installed successfully" -ForegroundColor Green
                    Write-Host "   ⚠ Please restart this PowerShell session and run the script again.`n" -ForegroundColor Yellow
                    exit 0
                } else {
                    Write-Host "   ❌ Failed to install via winget" -ForegroundColor Red
                }
            } else {
                Write-Host "   ❌ winget is not available" -ForegroundColor Red
            }
            
            Write-Host "`nManual installation required:" -ForegroundColor Yellow
            Write-Host "   1. Install winget: https://aka.ms/getwinget" -ForegroundColor Cyan
            Write-Host "   2. Or download pac CLI: https://aka.ms/PowerPlatformCLI`n" -ForegroundColor Cyan
            exit 1
        }
        
        Write-Host "   ✓ Power Platform CLI found`n" -ForegroundColor Green
        
        # Check if authenticated
        Write-Host "   Checking Power Platform authentication..." -ForegroundColor Gray
        $authCheck = pac auth list 2>&1 | Out-String
        
        if ($authCheck -notmatch "ACTIVE") {
            Write-Host "   ⚠ Not authenticated to Power Platform" -ForegroundColor Yellow
            Write-Host "   Initiating authentication...`n" -ForegroundColor Gray
            
            pac auth create
            
            if ($LASTEXITCODE -ne 0) {
                Write-Host "`n   ❌ Authentication failed" -ForegroundColor Red
                exit 1
            }
        }
        
        Write-Host "   ✓ Authenticated to Power Platform`n" -ForegroundColor Green
        
        # List environments
        Write-Host "   Fetching available environments..." -ForegroundColor Gray
        $envListRaw = pac admin list 2>&1 | Out-String
        
        # Display environments
        Write-Host "`n   Available Environments:" -ForegroundColor Cyan
        Write-Host "$envListRaw" -ForegroundColor White
        
        # Prompt for environment ID
        Write-Host "Enter the Environment ID to create/register service principal:" -ForegroundColor Yellow
        $environmentId = Read-Host "Environment ID"
        
        if ([string]::IsNullOrWhiteSpace($environmentId)) {
            Write-Host "`n❌ Environment ID is required" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "`n   Creating service principal for environment: $environmentId..." -ForegroundColor Gray
        $spOutput = pac admin create-service-principal --environment $environmentId 2>&1 | Out-String
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "`n   ❌ Failed to create service principal" -ForegroundColor Red
            Write-Host "   Output: $spOutput" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "`n$spOutput" -ForegroundColor Green
        
        # Parse output for ClientId and Secret
        $ClientId = $null
        $ClientSecret = $null
        
        if ($spOutput -match "Application \(client\) ID:\s*([a-f0-9-]+)") {
            $ClientId = $matches[1]
        }
        if ($spOutput -match "Client Secret:\s*(.+)") {
            $ClientSecret = $matches[1].Trim()
        }
        
        if (-not $ClientId -or -not $ClientSecret) {
            Write-Host "Please copy the Application (client) ID and Client Secret from above.`n" -ForegroundColor Yellow
            
            $ClientId = Read-Host "Enter Application (client) ID"
            $secureSecret = Read-Host "Enter Client Secret" -AsSecureString
            $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureSecret)
            $ClientSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
        
        Write-Host "`n╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║   SERVICE PRINCIPAL CREATED                                          ║" -ForegroundColor Green
        Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host "`n📋 Save these credentials for future use:" -ForegroundColor Cyan
        Write-Host "`n   Tenant ID:     $TenantId" -ForegroundColor White
        Write-Host "   Client ID:     $ClientId" -ForegroundColor White
        Write-Host "   Client Secret: $ClientSecret" -ForegroundColor White
        Write-Host "`n💡 Future runs can use these credentials:" -ForegroundColor Yellow
        Write-Host "   .\Get-CompleteCopilotReport.ps1 ``" -ForegroundColor Gray
        Write-Host "       -TenantId `"$TenantId`" ``" -ForegroundColor Gray
        Write-Host "       -ClientId `"$ClientId`" ``" -ForegroundColor Gray
        Write-Host "       -ClientSecret `"$ClientSecret`"`n" -ForegroundColor Gray
        
        # Ask if user wants to register to additional environments
        Write-Host "Do you want to register this service principal to additional environments? (Y/N)" -ForegroundColor Cyan
        $registerMore = Read-Host "Choice"
        
        if ($registerMore -eq "Y" -or $registerMore -eq "y") {
            Write-Host "`n📋 Registering service principal to additional environments..." -ForegroundColor Yellow
            
            # List environments again
            $envListRaw = pac admin list 2>&1 | Out-String
            Write-Host "`n   Available Environments:" -ForegroundColor Cyan
            Write-Host "$envListRaw" -ForegroundColor White
            
            $continueRegistering = $true
            while ($continueRegistering) {
                Write-Host "`nEnter Environment ID (or press Enter to finish):" -ForegroundColor Yellow
                $additionalEnvId = Read-Host "Environment ID"
                
                if ([string]::IsNullOrWhiteSpace($additionalEnvId)) {
                    $continueRegistering = $false
                    break
                }
                
                Write-Host "   Registering service principal to environment: $additionalEnvId..." -ForegroundColor Gray
                $additionalOutput = pac admin create-service-principal --environment $additionalEnvId 2>&1 | Out-String
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   ✓ Successfully registered to environment: $additionalEnvId" -ForegroundColor Green
                } else {
                    Write-Host "   ⚠ Failed to register to environment: $additionalEnvId" -ForegroundColor Yellow
                    Write-Host "   Error: $additionalOutput" -ForegroundColor Red
                }
                
                Write-Host "`nRegister to another environment? (Y/N)" -ForegroundColor Cyan
                $continueChoice = Read-Host "Choice"
                if ($continueChoice -ne "Y" -and $continueChoice -ne "y") {
                    $continueRegistering = $false
                }
            }
            
            Write-Host "`n✅ Service principal registration complete`n" -ForegroundColor Green
        }
        
        Write-Host "Press any key to continue with report generation..." -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Write-Host ""
        
    } else {
        Write-Host "`n❌ Service principal credentials are required" -ForegroundColor Red
        Write-Host "`nOptions:" -ForegroundColor Yellow
        Write-Host "   1. Run the script again and choose 'Y' to create a service principal" -ForegroundColor Cyan
        Write-Host "   2. Provide existing credentials:" -ForegroundColor Cyan
        Write-Host "      .\Get-CompleteCopilotReport.ps1 -TenantId `"..`" -ClientId `"..`" -ClientSecret `"..`"`n" -ForegroundColor Gray
        exit 1
    }
}

# Use these credentials for Dataverse as well
$DataverseTenantId = $TenantId
$DataverseClientId = $ClientId
$DataverseClientSecret = $ClientSecret

Write-Host "✅ Using service principal credentials" -ForegroundColor Green
Write-Host "   Client ID: $ClientId`n" -ForegroundColor Cyan

# ============================================================================
# AUTHENTICATION FUNCTIONS
# ============================================================================

function Get-AuthToken {
    param(
        [string]$Resource,
        [string]$DisplayName
    )
    
    Write-Host "`n🔐 Authenticating to $DisplayName..." -ForegroundColor Yellow
    
    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    
    $body = @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = "$Resource/.default"
        grant_type    = "client_credentials"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
        Write-Host "   ✓ Authenticated to $DisplayName (expires in $($response.expires_in)s)`n" -ForegroundColor Green
        
        return $response.access_token
    }
    catch {
        Write-Host "   ❌ Authentication failed: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "   Response: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        throw
    }
}

# ============================================================================
# STEP 1: POWER PLATFORM - GET ALL AGENTS
# ============================================================================

function Get-DataverseToken {
    param(
        [string]$Resource,
        [string]$DisplayUrl
    )
    
    $tokenUrl = "https://login.microsoftonline.com/$DataverseTenantId/oauth2/v2.0/token"
    $scope = "$Resource/.default"
    
    $body = @{
        client_id     = $DataverseClientId
        client_secret = $DataverseClientSecret
        scope         = $scope
        grant_type    = "client_credentials"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
        return $response.access_token
    }
    catch {
        return $null
    }
}

function Get-AllAgentsViaPowerPlatform {
    param([string]$Token)
    
    Write-Host "📦 STEP 1: Retrieving agents via Power Platform Admin API..." -ForegroundColor Cyan
    Write-Host "   ℹ️ Using Power Platform API (better service principal support)" -ForegroundColor Gray
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type"  = "application/json"
        "Accept"        = "application/json"
    }
    
    $allAgents = @()
    
    try {
        # First, get all environments
        Write-Host "   🌍 Fetching Power Platform environments..." -ForegroundColor Gray
        $envUrl = "https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments?api-version=2020-10-01"
        $envResponse = Invoke-RestMethod -Uri $envUrl -Method GET -Headers $headers
        $environments = $envResponse.value
        
        Write-Host "   ✓ Found $($environments.Count) environments`n" -ForegroundColor Green
        
        # For each environment, get Copilot Studio agents
        $envCount = 0
        foreach ($env in $environments) {
            $envCount++
            $envId = $env.name
            $envName = $env.properties.displayName
            
            Write-Host "   [$envCount/$($environments.Count)] $envName" -ForegroundColor Gray
            
            try {
                # Get Dataverse-specific token for this environment
                $instanceUrl = $env.properties.linkedEnvironmentMetadata.instanceUrl
                if (-not $instanceUrl) {
                    Write-Host "      ⚠ No Dataverse URL available" -ForegroundColor Yellow
                    continue
                }
                
                # Extract base Dataverse URL and remove .api. subdomain
                # Convert: https://org123.api.crm.dynamics.com -> https://org123.crm.dynamics.com
                $dataverseResource = $instanceUrl -replace '/+$', ''  # Remove trailing slash
                $dataverseResource = $dataverseResource -replace '\.api\.', '.'  # Remove .api. subdomain
                
                $dataverseToken = Get-DataverseToken -Resource $dataverseResource -DisplayUrl $instanceUrl
                
                if (-not $dataverseToken) {
                    continue
                }
                
                # Use Dataverse-specific token
                $dataverseHeaders = @{
                    "Authorization" = "Bearer $dataverseToken"
                    "Accept"        = "application/json"
                    "OData-MaxVersion" = "4.0"
                    "OData-Version" = "4.0"
                    "Prefer" = 'odata.include-annotations="OData.Community.Display.V1.FormattedValue"'
                }
                
                # Query bots from Dataverse (matching working app pattern)
                $dataverseUrl = "$dataverseResource/api/data/v9.2/bots?`$select=botid,name,schemaname,runtimeprovider,publishedon,statecode,statuscode,_ownerid_value,_createdby_value,createdon,modifiedon,solutionid&`$orderby=name asc"
                
                $agentResponse = Invoke-RestMethod -Uri $dataverseUrl -Method GET -Headers $dataverseHeaders -ErrorAction Stop
                
                if ($agentResponse.value) {
                    Write-Host "      ✓ Found $($agentResponse.value.Count) agents" -ForegroundColor Green
                    
                    # Get system users to map created by IDs to full names
                    $userLookup = @{}
                    try {
                        $usersUrl = "$dataverseResource/api/data/v9.2/systemusers?`$select=systemuserid,fullname"
                        $usersResponse = Invoke-RestMethod -Uri $usersUrl -Method GET -Headers $dataverseHeaders -ErrorAction SilentlyContinue
                        
                        if ($usersResponse.value) {
                            foreach ($user in $usersResponse.value) {
                                if ($user.systemuserid) {
                                    $userLookup[$user.systemuserid] = $user.fullname
                                }
                            }
                        }
                    }
                    catch {
                        # Silently continue if users can't be retrieved
                    }
                    
                    foreach ($agent in $agentResponse.value) {
                        # Get bot components for this agent
                        $componentCount = 0
                        $components = @()
                        try {
                            $componentsUrl = "$dataverseResource/api/data/v9.2/botcomponents?`$select=botcomponentid,name,componenttype,category,language,description,content,data&`$filter=_parentbotid_value eq '$($agent.botid)'&`$orderby=name asc"
                            $componentsResponse = Invoke-RestMethod -Uri $componentsUrl -Method GET -Headers $dataverseHeaders -ErrorAction SilentlyContinue
                            
                            if ($componentsResponse.value) {
                                $componentCount = $componentsResponse.value.Count
                                $components = $componentsResponse.value
                            }
                        }
                        catch {
                            # Silently continue if components can't be retrieved
                        }
                        
                        # Resolve owner name from user lookup (using createdby)
                        $ownerName = if ($agent._createdby_value -and $userLookup.ContainsKey($agent._createdby_value)) {
                            $userLookup[$agent._createdby_value]
                        } else {
                            $agent._createdby_value  # Fallback to ID if name not found
                        }
                        
                        $allAgents += [PSCustomObject]@{
                            AgentId           = $agent.botid
                            AgentName         = $agent.name
                            EnvironmentId     = $envId
                            EnvironmentName   = $envName
                            EnvironmentRegion = $env.location
                            CreatedOn         = if ($agent.createdon) { (Get-Date $agent.createdon).ToString("yyyy-MM-dd HH:mm:ss") } else { $null }
                            ModifiedOn        = if ($agent.modifiedon) { (Get-Date $agent.modifiedon).ToString("yyyy-MM-dd HH:mm:ss") } else { $null }
                            PublishedOn       = if ($agent.publishedon) { (Get-Date $agent.publishedon).ToString("yyyy-MM-dd HH:mm:ss") } else { $null }
                            OwnerId           = $agent._ownerid_value
                            Owner             = $ownerName
                            CreatedIn         = "Copilot Studio"
                            SolutionId        = $agent.solutionid
                            Description       = $null
                            SchemaName        = $agent.schemaname
                            RuntimeProvider   = $agent.runtimeprovider
                            StateCode         = $agent.statecode
                            StatusCode        = $agent.statuscode
                            ComponentCount    = $componentCount
                            Components        = $components
                        }
                    }
                }
            }
            catch {
                $statusCode = $_.Exception.Response.StatusCode.value__
                
                # Handle 403 Forbidden - Service Principal doesn't have access
                if ($statusCode -eq 403) {
                    Write-Host "      ⚠ The Service Principal doesn't have access to $envName ($instanceUrl)" -ForegroundColor Yellow
                }
                # Show detailed error for 400 Bad Request
                elseif ($statusCode -eq 400 -and $_.ErrorDetails.Message) {
                    Write-Host "      ⚠ Error ($statusCode): $($_.Exception.Message)" -ForegroundColor Yellow
                    Write-Host "        Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
                }
                # Generic error handling
                else {
                    Write-Host "      ⚠ Error ($statusCode): $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
        }
        
        Write-Host "`n   ✓ Retrieved $($allAgents.Count) agents total`n" -ForegroundColor Green
        return $allAgents
    }
    catch {
        Write-Host "   ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "   Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        }
        throw
    }
}

# ============================================================================
# STEP 2: LICENSING API - GET CREDITS
# ============================================================================

function Get-CreditsData {
    param(
        [string]$Token,
        [array]$Agents,
        [datetime]$FromDate,
        [datetime]$ToDate
    )
    
    Write-Host "💰 STEP 2: Retrieving credits consumption..." -ForegroundColor Cyan
    Write-Host "   Date Range: $($FromDate.ToString('yyyy-MM-dd')) to $($ToDate.ToString('yyyy-MM-dd')) ($LookbackDays days)" -ForegroundColor Gray
    Write-Host ""
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "Accept"        = "application/json"
    }
    
    $fromStr = $FromDate.ToString("MM-dd-yyyy")
    $toStr = $ToDate.ToString("MM-dd-yyyy")
    
    # Get unique environments
    $environments = $Agents | Select-Object EnvironmentId, EnvironmentName -Unique
    
    $creditsLookup = @{}
    $envCount = 0
    
    foreach ($env in $environments) {
        $envCount++
        Write-Host "   [$envCount/$($environments.Count)] $($env.EnvironmentName)" -ForegroundColor Gray
        
        $url = "https://licensing.powerplatform.microsoft.com/v0.1-alpha/tenants/$TenantId/entitlements/MCSMessages/environments/$($env.EnvironmentId)/resources?fromDate=$fromStr&toDate=$toStr"
        
        try {
            $response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers
            
            if ($response.value -and $response.value[0].resources) {
                $resources = $response.value[0].resources
                Write-Host "      ✓ Found $($resources.Count) resource entries" -ForegroundColor Green
                
                foreach ($resource in $resources) {
                    $agentId = $resource.resourceId
                    
                    if (-not $creditsLookup.ContainsKey($agentId)) {
                        $creditsLookup[$agentId] = @{
                            BilledCredits = 0
                            NonBilledCredits = 0
                        }
                    }
                    
                    $creditsLookup[$agentId].BilledCredits += $resource.consumed
                    $creditsLookup[$agentId].NonBilledCredits += $resource.metadata.NonBillableQuantity
                }
            }
        }
        catch {
            Write-Host "      ⚠ No data available" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n   ✓ Credits data collected for $($creditsLookup.Count) agents`n" -ForegroundColor Green
    return $creditsLookup
}

# ============================================================================
# STEP 3: MERGE ALL DATA
# ============================================================================

function Merge-AllData {
    param(
        [array]$Agents,
        [hashtable]$CreditsLookup,
        [hashtable]$DataverseLookup
    )
    
    Write-Host "🔗 STEP 4: Merging all data sources..." -ForegroundColor Cyan
    
    $completeReport = foreach ($agent in $Agents) {
        $agentId = $agent.AgentId
        
        # Get credits
        $credits = $CreditsLookup[$agentId]
        $billedCredits = if ($credits) { [math]::Round($credits.BilledCredits, 2) } else { 0 }
        $nonBilledCredits = if ($credits) { [math]::Round($credits.NonBilledCredits, 2) } else { 0 }
        
        # Get Dataverse data
        $dataverse = $DataverseLookup[$agentId]
        $solutionId = if ($dataverse) { $dataverse.SolutionId } else { $null }
        $description = if ($dataverse) { $dataverse.Description } else { $null }
        
        [PSCustomObject]@{
            "Agent ID"              = $agentId
            "Agent Name"            = $agent.AgentName
            "Agent Description"     = $description
            "Environment ID"        = $agent.EnvironmentId
            "Environment Name"      = $agent.EnvironmentName
            "Environment Region"    = $agent.EnvironmentRegion
            "Solution ID"           = $agent.SolutionId
            "Owner ID"              = $agent.OwnerId
            "Owner"                 = $agent.Owner
            "Created On"            = $agent.CreatedOn
            "Modified On"           = $agent.ModifiedOn
            "Published On"          = $agent.PublishedOn
            "Created In"            = $agent.CreatedIn
            "Billed Credits (MB)"   = $billedCredits
            "Non-Billed Credits (MB)" = $nonBilledCredits
            "Total Credits (MB)"    = [math]::Round($billedCredits + $nonBilledCredits, 2)
            "Has Usage"             = if ($billedCredits -gt 0 -or $nonBilledCredits -gt 0) { "Yes" } else { "No" }
        }
    }
    
    Write-Host "   ✓ Merged $($completeReport.Count) agent records`n" -ForegroundColor Green
    return $completeReport
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    $startTime = Get-Date
    
    # Step 1: Authenticate to Power Platform and get agents
    $ppToken = Get-AuthToken -Resource "https://api.bap.microsoft.com" -DisplayName "Power Platform Admin API"
    $agents = Get-AllAgentsViaPowerPlatform -Token $ppToken
    
    if ($agents.Count -eq 0) {
        throw "No agents found via Power Platform API"
    }
    
    # Step 2: Get credits
    $licensingToken = Get-AuthToken -Resource "https://licensing.powerplatform.microsoft.com" -DisplayName "Licensing API"
    $toDate = Get-Date
    $fromDate = $toDate.AddDays(-$LookbackDays)
    $creditsLookup = Get-CreditsData -Token $licensingToken -Agents $agents -FromDate $fromDate -ToDate $toDate
    
    # Step 3: Merge everything
    $completeReport = Merge-AllData -Agents $agents -CreditsLookup $creditsLookup -DataverseLookup @{}
    
    # Create Reports directory if it doesn't exist (at repository root level)
    $reportsDir = Join-Path (Split-Path $scriptDir -Parent) "Reports"
    if (-not (Test-Path $reportsDir)) {
        Write-Host "`n📁 Creating Reports directory..." -ForegroundColor Gray
        New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
        Write-Host "   ✓ Reports directory created: $reportsDir`n" -ForegroundColor Green
    }
    
    # Export to CSV in Reports directory
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outputFile = Join-Path $reportsDir "CopilotAgents_CompleteReport_${timestamp}.csv"
    $completeReport | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
    
    # Summary
    $duration = (Get-Date) - $startTime
    
    Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║   REPORT COMPLETE                                                    ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    $withUsage = ($completeReport | Where-Object { $_."Has Usage" -eq "Yes" }).Count
    $withSolutionId = ($completeReport | Where-Object { $_."Solution ID" -ne $null }).Count
    $withDescription = ($completeReport | Where-Object { $_."Agent Description" -ne $null }).Count
    
    $totalBilled = ($completeReport | Measure-Object "Billed Credits (MB)" -Sum).Sum
    $totalNonBilled = ($completeReport | Measure-Object "Non-Billed Credits (MB)" -Sum).Sum
    
    Write-Host "📊 Summary:" -ForegroundColor Cyan
    Write-Host "   Total Agents: $($completeReport.Count)" -ForegroundColor White
    Write-Host "   Agents with Usage: $withUsage" -ForegroundColor White
    Write-Host "   Agents with Solution ID: $withSolutionId" -ForegroundColor White
    Write-Host ""
    Write-Host "💰 Credits:" -ForegroundColor Cyan
    Write-Host "   Billed: $([math]::Round($totalBilled, 2)) MB" -ForegroundColor White
    Write-Host "   Non-Billed: $([math]::Round($totalNonBilled, 2)) MB" -ForegroundColor White
    Write-Host "   Total: $([math]::Round($totalBilled + $totalNonBilled, 2)) MB" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Fields Retrieved:" -ForegroundColor Cyan
    Write-Host "   ✅ All available fields from Power Platform Admin API and Dataverse" -ForegroundColor Green
    Write-Host "   ❌ Active Users (not available in any API)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💾 Report saved: $(Split-Path $outputFile -Leaf)" -ForegroundColor Cyan
    Write-Host "   Location: $scriptDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "⏱️  Execution time: $([math]::Round($duration.TotalMinutes, 1)) minutes`n" -ForegroundColor Gray
    
    Write-Host "═══════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "✅ Report generation completed successfully!" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════════════`n" -ForegroundColor Green
}
catch {
    Write-Host "`n❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}
