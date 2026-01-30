# Usage Instructions for Get-CompleteCopilotReport.ps1

## Quick Start

### First Run (Interactive Setup)
```powershell
cd scripts
.\Get-CompleteCopilotReport.ps1
```

Follow the interactive prompts:
1. **Create service principal?** → Y (first time only)
2. **Authenticate to Power Platform** → Follow pac auth prompts
3. **Select environment** → Choose from list
4. **Register to more environments?** → Y/N (optional)
5. **Save credentials displayed** → For future automated runs

### Subsequent Runs (Automated with Saved Credentials)
```powershell
.\Get-CompleteCopilotReport.ps1 -TenantId "..." -ClientId "..." -ClientSecret "..."
```

### Using Environment Variables (Recommended for Automation)
```powershell
# Set once
[System.Environment]::SetEnvironmentVariable('COPILOT_TENANT_ID', 'your-tenant-id', 'User')
[System.Environment]::SetEnvironmentVariable('COPILOT_CLIENT_ID', 'your-client-id', 'User')
[System.Environment]::SetEnvironmentVariable('COPILOT_CLIENT_SECRET', 'your-secret', 'User')

# Run anytime
.\Get-CompleteCopilotReport.ps1 `
  -TenantId $env:COPILOT_TENANT_ID `
  -ClientId $env:COPILOT_CLIENT_ID `
  -ClientSecret $env:COPILOT_CLIENT_SECRET
```

## What the Script Does

### Setup Phase (First Run Only)

1. **Checks for Power Platform CLI**
   - Detects if pac CLI is installed
   - Auto-installs via winget if not found
   - Prompts to restart PowerShell if installation needed

2. **Prompts for Service Principal Creation**
   - "Do you need to create a new service principal? (Y/N)"
   - If Y: Proceeds with automated setup
   - If N: Exits with instructions to provide credentials

3. **Authenticates to Power Platform**
   - Runs `pac auth create` (interactive browser login)
   - Verifies authentication with `pac auth list`

4. **Lists and Selects Environment**
   - Displays all environments with IDs
   - Prompts: "Enter the Environment ID"
   - Creates service principal for selected environment

5. **Creates Service Principal**
   - Runs: `pac admin create-service-principal --environment {id}`
   - Automatically creates Azure AD app registration
   - Generates client secret
   - Grants all necessary API permissions (Power Platform Admin, Dataverse, Licensing)

6. **Parses and Displays Credentials**
   - Extracts ClientId and ClientSecret from pac output
   - Displays formatted credentials with example command:
   ```
   ✅ Service Principal Created Successfully!
   
   📋 CREDENTIALS (save these securely):
   
   Tenant ID:     your-tenant-id
   Client ID:     your-client-id
   Client Secret: your-client-secret
   
   💡 For future runs, use:
   .\Get-CompleteCopilotReport.ps1 -TenantId "..." -ClientId "..." -ClientSecret "..."
   ```

7. **Multi-Environment Registration (Optional)**
   - Prompts: "Register to additional environments? (Y/N)"
   - If Y: Loops through environment IDs
   - Registers same service principal to each environment
   - Continues until user enters "N"

### Data Collection Phase (Every Run)

1. **Authenticates with Service Principal**
   - Gets token for Power Platform Admin API
   - Gets token for Licensing API
   - Prepares for per-environment Dataverse tokens

2. **Queries Power Platform Admin API**
   - Endpoint: `https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments`
   - Retrieves all environments in tenant
   - Returns: Environment ID, name, region, type, organization URL

3. **Queries Dataverse API (Per Environment)**
   - For each environment's organization URL
   - Gets environment-specific authentication token
   - Queries three endpoints:
     - `/api/data/v9.2/bots` - Agent metadata
     - `/api/data/v9.2/systemusers` - Owner and creator details
     - `/api/data/v9.2/botcomponents` - Component information
   - Returns: Bot ID, name, description, solution ID, timestamps, owner, creator

4. **Queries Licensing API**
   - Endpoint: `https://licensing.powerplatform.microsoft.com/v0.1-alpha/tenants/{tenantId}/entitlements/MCSMessages`
   - Retrieves credits consumption data
   - Returns: Billed and non-billed credits in MB

5. **Merges All Data**
   - Joins agents with environments
   - Joins with owner/creator names
   - Joins with credits consumption
   - Creates comprehensive dataset

6. **Exports to CSV**
   - Filename: `Reports/CopilotAgents_CompleteReport_YYYYMMDD_HHMMSS.csv`
   - Saved to repository root's Reports directory
   - All fields populated with complete data
   - Timestamped for version tracking

## Expected Output

### Console Output (First Run - Setup)
```
╔══════════════════════════════════════════════════════════════════════╗
║   COMPLETE COPILOT STUDIO AGENT REPORT                              ║
║   Single Script Solution - All Available Fields                     ║
╚══════════════════════════════════════════════════════════════════════╝

⚠️  No service principal credentials provided

Do you need to create a new service principal? (Y/N)
Choice: Y

🔧 SERVICE PRINCIPAL SETUP
   Checking for Power Platform CLI...
   ✓ Power Platform CLI found

   Checking Power Platform authentication...
   Creating new authentication profile...
   
   [Browser opens for pac auth create]
   ✓ Authentication successful

   Listing available environments...
   
   📋 AVAILABLE ENVIRONMENTS:
   
   1. Production Environment
      ID: 00000000-0000-0000-0000-000000000001
      
   2. Development Environment
      ID: 00000000-0000-0000-0000-000000000002
   
   Enter the Environment ID to create service principal for: 00000000-0000-0000-0000-000000000001
   
   Creating service principal for environment...
   ✓ Service principal created successfully
   
   ✅ Service Principal Created Successfully!
   
   📋 CREDENTIALS (save these securely):
   
   Tenant ID:     your-tenant-id
   Client ID:     7a3560b1-e5bb-453b-9480-9bc10c5b7696
   Client Secret: Yx~8Q~-0QGyMWJ3yXlXEGd2MLvhYAd8ZYaMzYaew
   
   💡 For future runs, use:
   .\Get-CompleteCopilotReport.ps1 -TenantId "..." -ClientId "..." -ClientSecret "..."
   
   Do you want to register this service principal to additional environments? (Y/N): Y
   
   Enter Environment ID (or 'N' to finish): 00000000-0000-0000-0000-000000000002
   Registering service principal to environment...
   ✓ Successfully registered
   
   Enter Environment ID (or 'N' to finish): N
   Continuing with data collection...
```

### Console Output (Data Collection)
```
🔐 Authenticating to Power Platform Admin API...
   ✓ Successfully authenticated

🔐 Authenticating to Licensing API...
   ✓ Successfully authenticated

📊 Step 1/4: Fetching environments from Power Platform Admin API...
   ✓ Found 8 environments

📊 Step 2/4: Fetching agents from Dataverse (per environment)...
   Environment: Production Environment
     ✓ Found 45 agents
   Environment: Development Environment
     ✓ Found 28 agents
   [... continues for all environments ...]
   ✓ Total agents found: 115

📊 Step 3/4: Fetching credits consumption from Licensing API...
   ✓ Found consumption data for 34 agents

📊 Step 4/4: Merging data and building report...
   ✓ Merged agents with environments
   ✓ Merged owner and creator information
   ✓ Merged credits consumption data

💾 Exporting to CSV: Reports/CopilotAgents_CompleteReport_20260130_143527.csv
   ✓ Export complete

╔══════════════════════════════════════════════════════════════════════╗
║                            SUCCESS!                                  ║
╚══════════════════════════════════════════════════════════════════════╝

📊 EXECUTION SUMMARY:
   Total Agents:           115
   Agents with Credits:    34
   Agents without Credits: 81
   Total Environments:     8
   
   Total Credits (MB):     5,505.82
   Billed Credits (MB):    3,479.58
   Non-Billed Credits (MB): 2,026.24

🌍 TOP ENVIRONMENTS BY AGENT COUNT:
   Production Environment     45 agents
   Development Environment    28 agents
   Test Environment          18 agents
```

### CSV File Structure
```csv
Bot ID,Bot Name,Display Name,Description,Solution ID,Environment,Environment ID,Environment Region,Owner,Created By,Created On,Modified On,Billed Credits (MB),Non-Billed Credits (MB),Total Credits (MB)
00000000-0000-0000-0000-000000000001,CustomerSupport,Customer Support Bot,Handles customer inquiries,{solution-id},Production,{env-id},unitedstates,John Doe,Jane Smith,2025-01-15,2025-01-28,125.50,45.20,170.70
```

### Fields Included (12 Total)
1. Bot ID (Primary Key)
2. Bot Name
3. Display Name
4. Description
5. Solution ID
6. Environment (Name)
7. Environment ID
8. Environment Region
9. Owner (Full Name)
10. Created By (Full Name)
11. Created On (Timestamp)
12. Modified On (Timestamp)
13. Billed Credits (MB)
14. Non-Billed Credits (MB)
15. Total Credits (MB)

## Troubleshooting

### Issue: "Power Platform CLI not found"
**Cause:** pac CLI not installed

**Solution:**
1. Script attempts auto-install via winget
2. If winget unavailable, install manually:
   ```powershell
   winget install Microsoft.PowerPlatformCLI
   ```
3. Restart PowerShell and re-run script

### Issue: "Authentication failed: 401 Unauthorized"
**Cause:** Invalid or expired client secret

**Solution:**
1. Create new service principal by running script without parameters
2. Choose Y when prompted to create service principal
3. Save new credentials displayed
4. Verify credentials are correct (no extra spaces/characters)

### Issue: "Service Principal doesn't have access to environment"
**Cause:** Service principal not registered to that specific environment

**Solution:**
1. Run script with existing credentials:
   ```powershell
   .\Get-CompleteCopilotReport.ps1 -TenantId "..." -ClientId "..." -ClientSecret "..."
   ```
2. When prompted, choose Y to register to additional environments
3. Enter the environment ID that's missing access

### Issue: Script creates new service principal every time
**Cause:** Not providing credentials as parameters

**Solution:**
After first run, always provide credentials:
```powershell
.\Get-CompleteCopilotReport.ps1 -TenantId "..." -ClientId "..." -ClientSecret "..."
```

### Issue: "You need to be a Power Platform Administrator"
**Cause:** Missing required role for service principal creation

**Solution:**
1. Contact your tenant administrator
2. Request Power Platform Administrator role assignment
3. Alternative: Have admin create service principal for you
4. Admin can run script and provide you with credentials

### Issue: "No agents found in environment"
**Cause:** Environment has no Copilot Studio bots, or permissions issue

**Solution:**
- Verify environment has agents in Power Platform Admin Center
- Check service principal has Dataverse access (automatic via pac CLI)
- Confirm environment URL is accessible

### Issue: Empty credits data
**Cause:** Agents have no usage, or licensing API not returning data

**Solution:**
- This is expected if agents haven't been used
- Credits only appear for agents with actual conversations
- Check agents have been published and used by end users

### Issue: pac auth create opens browser but doesn't complete
**Cause:** Browser authentication issue or conditional access policy

**Solution:**
1. Use different browser
2. Clear browser cache and cookies
3. Check with IT admin about conditional access policies
4. Try authentication in private/incognito mode

## API Details

### 1. Power Platform Admin API
**Endpoint:**
```
GET https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments
```

**Purpose:** Enumerate all environments in tenant

**Authentication:** OAuth 2.0 Client Credentials Flow with service principal

**Scope:** `https://api.bap.microsoft.com/.default`

**Returns:**
```json
{
  "value": [
    {
      "id": "environment-id",
      "name": "environment-name",
      "properties": {
        "displayName": "Production Environment",
        "environmentSku": "Production",
        "azureRegionHint": "unitedstates",
        "linkedEnvironmentMetadata": {
          "instanceUrl": "https://org.crm.dynamics.com"
        }
      }
    }
  ]
}
```

### 2. Dataverse API (Per Environment)
**Endpoint:**
```
GET https://{org}.crm.dynamics.com/api/data/v9.2/bots?
  $select=botid,name,publishedby,displayname,schemaname,solutionid,
          description,overriddencreatedon,modifiedon,_ownerid_value,_createdby_value
  &$expand=ownerid($select=fullname),createdby($select=fullname)
```

**Purpose:** Retrieve detailed bot/agent metadata

**Authentication:** OAuth 2.0 Client Credentials Flow (per-environment token)

**Scope:** `https://{org}.crm.dynamics.com/.default`

**Returns:**
```json
{
  "value": [
    {
      "botid": "agent-guid",
      "name": "bot_internal_name",
      "displayname": "Customer Support Bot",
      "description": "Handles customer inquiries",
      "solutionid": "solution-guid",
      "overriddencreatedon": "2025-01-15T10:30:00Z",
      "modifiedon": "2025-01-28T14:20:00Z",
      "_ownerid_value": "owner-guid",
      "_createdby_value": "creator-guid",
      "ownerid": {
        "fullname": "John Doe"
      },
      "createdby": {
        "fullname": "Jane Smith"
      }
    }
  ]
}
```

### 3. Licensing API (Undocumented)
**Endpoint:**
```
GET https://licensing.powerplatform.microsoft.com/v0.1-alpha/tenants/{tenantId}/entitlements/MCSMessages
```

**Purpose:** Retrieve credits consumption data

**Authentication:** OAuth 2.0 Client Credentials Flow

**Scope:** `https://licensing.powerplatform.microsoft.com/.default`

**⚠️ Important:** This is a **v0.1-alpha** endpoint (pre-release, undocumented, unsupported)

**Returns:**
```json
{
  "resources": [
    {
      "resourceId": "agent-guid",
      "totalBillable": 125.50,
      "totalNonBillable": 45.20,
      "channels": [...],
      "features": [...]
    }
  ]
}
```

## Service Principal Setup Details

### What pac admin create-service-principal Does

The `pac admin create-service-principal` command:

1. **Creates Azure AD App Registration**
   - Automatically registers app in Azure Active Directory
   - Generates application (client) ID
   - Creates and stores client secret

2. **Grants API Permissions**
   - Power Platform Admin API access
   - Dataverse API access for specified environment
   - Licensing API access

3. **Registers to Environment**
   - Associates service principal with Dataverse environment
   - Enables authentication to environment's organization URL
   - Required once per environment

### Manual Service Principal Creation (Alternative)

If you prefer manual setup or need to script outside the main report:

```powershell
# Install pac CLI
winget install Microsoft.PowerPlatformCLI

# Authenticate
pac auth create

# List environments
pac admin list

# Create service principal for first environment
pac admin create-service-principal --environment {environment-id}

# Save displayed ClientId and ClientSecret

# Register to additional environments (same service principal)
pac admin create-service-principal --environment {another-environment-id}
```

### Credential Storage Best Practices

**Option 1: Environment Variables (Recommended)**
```powershell
[System.Environment]::SetEnvironmentVariable('COPILOT_TENANT_ID', 'your-tenant-id', 'User')
[System.Environment]::SetEnvironmentVariable('COPILOT_CLIENT_ID', 'your-client-id', 'User')
[System.Environment]::SetEnvironmentVariable('COPILOT_CLIENT_SECRET', 'your-secret', 'User')
```

**Option 2: Azure Key Vault (Most Secure)**
```powershell
# Store
az keyvault secret set --vault-name "your-vault" --name "copilot-client-id" --value "..."
az keyvault secret set --vault-name "your-vault" --name "copilot-client-secret" --value "..."

# Retrieve
$clientId = az keyvault secret show --vault-name "your-vault" --name "copilot-client-id" --query value -o tsv
$clientSecret = az keyvault secret show --vault-name "your-vault" --name "copilot-client-secret" --query value -o tsv
```

**Option 3: Secure Configuration File**
```powershell
# Create encrypted config
$creds = @{
    TenantId = "your-tenant-id"
    ClientId = "your-client-id"
    ClientSecret = "your-secret"
}
$creds | ConvertTo-Json | ConvertTo-SecureString -AsPlainText -Force | 
    ConvertFrom-SecureString | Out-File "config.secure"

# Load config
$secureString = Get-Content "config.secure" | ConvertTo-SecureString
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
$json = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
$creds = $json | ConvertFrom-Json
```

## Automation Examples

### Task Scheduler (Windows)
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File C:\scripts\Get-CompleteCopilotReport.ps1 -TenantId '$env:COPILOT_TENANT_ID' -ClientId '$env:COPILOT_CLIENT_ID' -ClientSecret '$env:COPILOT_CLIENT_SECRET'"

$trigger = New-ScheduledTaskTrigger -Daily -At 6am

Register-ScheduledTask -TaskName "Daily Copilot Report" -Action $action -Trigger $trigger
```

### Azure DevOps Pipeline
```yaml
trigger: none

schedules:
- cron: "0 6 * * *"
  displayName: Daily Report
  branches:
    include:
    - main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  inputs:
    filePath: 'scripts/Get-CompleteCopilotReport.ps1'
    arguments: '-TenantId $(TENANT_ID) -ClientId $(CLIENT_ID) -ClientSecret $(CLIENT_SECRET)'
  env:
    TENANT_ID: $(COPILOT_TENANT_ID)
    CLIENT_ID: $(COPILOT_CLIENT_ID)
    CLIENT_SECRET: $(COPILOT_CLIENT_SECRET)

- task: PublishBuildArtifacts@1
  inputs:
    PathtoPublish: '$(Build.SourcesDirectory)/output'
    ArtifactName: 'reports'
```

### GitHub Actions
```yaml
name: Daily Copilot Report

on:
  schedule:
    - cron: '0 6 * * *'
  workflow_dispatch:

jobs:
  generate-report:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Generate Report
        shell: pwsh
        run: |
          cd scripts
          .\Get-CompleteCopilotReport.ps1 `
            -TenantId ${{ secrets.TENANT_ID }} `
            -ClientId ${{ secrets.CLIENT_ID }} `
            -ClientSecret ${{ secrets.CLIENT_SECRET }}
      
      - name: Upload Report
        uses: actions/upload-artifact@v3
        with:
          name: copilot-report
          path: output/*.csv
```

## Permissions Required

### For Service Principal Creation
- **Power Platform Administrator** role (required)
  - Needed to run `pac admin create-service-principal`
  - Cannot be delegated to non-admin users
  - Contact tenant administrator if you don't have this role

### For Running the Script (with existing credentials)
- **No special permissions required**
  - Service principal handles all authentication
  - Any user can run script with valid credentials
  - Suitable for delegated/automated scenarios

### Service Principal Permissions (Automatic)
The `pac admin create-service-principal` command automatically grants:
- Power Platform Admin API access (environment enumeration)
- Dataverse API access (per registered environment)
- Licensing API access (credits consumption data)

No manual API permission configuration needed in Azure Portal.

## Rate Limits and Performance

### API Rate Limits
- **Power Platform Admin API**: Standard throttling applies
- **Dataverse API**: Per-environment throttling (typically generous)
- **Licensing API**: Unknown (undocumented API)

### Performance Considerations
- **Small tenant** (1-5 environments, <50 agents): ~30-60 seconds
- **Medium tenant** (5-20 environments, 50-200 agents): 2-5 minutes  
- **Large tenant** (20+ environments, 200+ agents): 5-15 minutes

Per-environment queries are sequential, not parallel (to respect rate limits).

## Data Accuracy and Freshness

### Timestamps
- All timestamps in UTC
- Created On: Original bot creation date
- Modified On: Last bot modification
- Credits data: Historical based on actual usage

### Credits Data
- **Billed Credits**: Consumption that counts toward license limits
- **Non-Billed Credits**: Free tier or non-billable usage
- **Totals**: Sum of billed and non-billed
- **Empty values**: Agent has no usage (expected for unused bots)

### Environment Data
- Real-time from Power Platform Admin API
- Environment names, regions, types always current
- Deleted environments will not appear (agents orphaned)

## Next Steps

After running Get-CompleteCopilotReport.ps1:

### 1. Analyze in Excel
```powershell
# Open CSV in Excel (from repository root)
Start-Process "Reports\CopilotAgents_CompleteReport_*.csv"

# Create pivot tables:
# - Agents by Environment
# - Credits by Owner
# - Usage trends over time
```

### 2. Import to Power BI
- Use "Get Data" → "Text/CSV"
- Create visualizations:
  - Bar chart: Agents per environment
  - Pie chart: Billed vs non-billed credits
  - Table: Top agents by consumption

### 3. Schedule Regular Reports
- Use Task Scheduler (Windows)
- Use Azure DevOps Pipelines
- Use GitHub Actions
- Store credentials in Key Vault for security

### 4. Register to Additional Environments
If you need to add more environments later:
```powershell
.\Get-CompleteCopilotReport.ps1 -TenantId "..." -ClientId "..." -ClientSecret "..."
# When prompted, choose Y to register to additional environments
```

## Support and Additional Resources

### Documentation
- **Setup Guide**: [docs/ENTRA-APP-SETUP.md](docs/ENTRA-APP-SETUP.md)
- **Script README**: [scripts/README.md](scripts/README.md)
- **Technical Details**: [README.md](README.md)

### Official Microsoft Documentation
- Power Platform Admin API: https://learn.microsoft.com/power-platform/admin/
- Dataverse Web API: https://learn.microsoft.com/power-apps/developer/data-platform/webapi/overview
- Power Platform CLI: https://learn.microsoft.com/power-platform/developer/cli/introduction

### Common Questions

**Q: Can I use the same service principal across multiple tenants?**  
A: No, service principals are tenant-specific. Each tenant requires its own service principal.

**Q: How long are the credentials valid?**  
A: Client secrets typically expire after 1-2 years (configurable in Azure AD). Script will fail with 401 when expired. Create new service principal when this happens.

**Q: Can I rotate the secret without recreating the service principal?**  
A: Yes, but requires manual Azure Portal access. Easier to create new service principal via script.

**Q: What happens if I delete the service principal?**  
A: Script will fail with 401 Unauthorized. Create new service principal by running script without parameters.

**Q: Can non-admin users run the report?**  
A: Yes, if you provide them with the credentials. Service principal creation requires admin, but running with existing credentials does not.

**Q: How do I know which environments the service principal has access to?**  
A: It only has access to environments you explicitly registered it to. If you get errors for specific environments, re-run setup and register to those environments.

**Q: Is this officially supported by Microsoft?**  
A: The Power Platform Admin API and Dataverse API are official and supported. The Licensing API is undocumented (v0.1-alpha) and unsupported, discovered via browser developer tools.

### Troubleshooting Resources

For additional help:
1. Check the [Troubleshooting](#troubleshooting) section above
2. Review [docs/ENTRA-APP-SETUP.md](docs/ENTRA-APP-SETUP.md) for setup issues
3. Verify your Power Platform Administrator role assignment
4. Test pac CLI manually: `pac admin list`
5. Check Azure AD app registration in Azure Portal

### Version Information

- **Current Version**: 2.0
- **Last Updated**: January 30, 2026
- **Script**: Get-CompleteCopilotReport.ps1
- **Compatibility**: PowerShell 5.1+ on Windows

### Important Disclaimers

⚠️ **Licensing API**: The credits consumption endpoint is undocumented and in alpha (v0.1-alpha). It may change or break without notice.

⚠️ **Service Principal Management**: Keep credentials secure. Treat them like passwords. Do not commit to source control.

⚠️ **Automation**: When scheduling automated runs, ensure credentials are stored securely (Key Vault, encrypted config, or secure environment variables).

---

**For issues, questions, or contributions:**
- GitHub Issues: https://github.com/sayedpfe/AgentCustomReport/issues
- Technical Documentation: [README.md](README.md)
- Executive Summary: [EXECUTIVE_SUMMARY.md](EXECUTIVE_SUMMARY.md)
