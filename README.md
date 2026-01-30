# Copilot Studio Agent Reporting Solution (v2.0)

This repository provides PowerShell scripts to generate comprehensive usage and consumption reports for Copilot Studio agents across Power Platform environments using **Power Platform Admin API**, **Dataverse API**, and **Power Platform Licensing API**.

## Overview

This solution uses service principal authentication to retrieve agent metadata, owner details, and consumption data across all environments. The main script automates service principal creation using Power Platform CLI and queries three APIs to create a consolidated report with comprehensive agent information.

## Quick Start

**Single comprehensive script with automated setup (recommended):**
```powershell
# First run - interactive setup
.\scripts\Get-CompleteCopilotReport.ps1

# Follow prompts to create service principal and authenticate
# Script handles pac CLI installation and multi-environment registration

# Future runs - with saved credentials
.\scripts\Get-CompleteCopilotReport.ps1 -TenantId "..." -ClientId "..." -ClientSecret "..."
```

This retrieves all available agent data in a single execution with automated service principal setup.

## Available Data Fields (12/12)

| # | Field | Available | Source | Notes |
|---|-------|-----------|--------|-------|
| 1 | Agent Identifier (Primary Key) | ✅ Yes | Dataverse API | Bot GUID |
| 2 | Environment ID | ✅ Yes | Power Platform Admin API | Environment identifier |
| 3 | Agent Name | ✅ Yes | Dataverse API | Bot name and display name |
| 4 | Agent Description | ✅ Yes | Dataverse API | Bot description |
| 5 | Created At (timestamp) | ✅ Yes | Dataverse API | Creation timestamp |
| 6 | Modified At (timestamp) | ✅ Yes | Dataverse API | Last modified timestamp |
| 7 | Solution ID | ✅ Yes | Dataverse API | Associated solution |
| 8 | Agent Owner | ✅ Yes | Dataverse API | Owner name (via systemusers join) |
| 9 | Created By | ✅ Yes | Dataverse API | Creator name (via systemusers join) |
| 10 | Environment Details | ✅ Yes | Power Platform Admin API | Name, region, type |
| 11 | Billed Copilot Credits | ✅ Yes | Licensing API* | Consumption in MB |
| 12 | Non-Billed Credits | ✅ Yes | Licensing API* | Non-billable consumption in MB |

**\* Licensing API discovered via browser developer tools - no official documentation available**

## API Endpoints Used

### 1. Power Platform Admin API (Official)
- **Endpoint**: `https://api.bap.microsoft.com/providers/Microsoft.BusinessAppPlatform/scopes/admin/environments`
- **Method**: GET
- **Documentation**: [Power Platform Admin API](https://learn.microsoft.com/power-platform/admin/)
- **Authentication**: OAuth 2.0 with service principal (Client Credentials Flow)
- **Purpose**: Enumerates all environments in the tenant
- **Returns**: Environment ID, name, region, type, organization URL
- **Scope**: `https://api.bap.microsoft.com/.default`

### 2. Dataverse API (Per-Environment)
- **Endpoint**: `https://{org}.crm.dynamics.com/api/data/v9.2/`
- **Resources**: 
  - `bots` - Agent/bot metadata
  - `systemusers` - Owner and creator details
  - `botcomponents` - Bot component information
- **Method**: GET with OData queries
- **Documentation**: [Dataverse Web API](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/overview)
- **Authentication**: OAuth 2.0 with service principal registered to environment
- **Purpose**: Detailed bot data including description, solution ID, timestamps, owners
- **Setup**: Service principal must be registered via `pac admin create-service-principal --environment {environmentId}`

**Sample Query**:
```
https://{org}.crm.dynamics.com/api/data/v9.2/bots?
  $select=botid,name,publishedby,displayname,schemaname,solutionid,
          description,overriddencreatedon,modifiedon,_ownerid_value,_createdby_value
  &$expand=ownerid($select=fullname),createdby($select=fullname)
```

### 3. Licensing API - Credits Consumption (Undocumented)
- **Endpoint**: `https://licensing.powerplatform.microsoft.com/v0.1-alpha/tenants/{tenantId}/entitlements/MCSMessages/environments/{environmentId}/resources?fromDate={MM-DD-YYYY}&toDate={MM-DD-YYYY}`
- **Method**: GET
- **Documentation**: ⚠️ **None - Discovered via browser developer tools**
- **Authentication**: OAuth 2.0 (Device Code Flow)
- **Client ID**: `51f81489-12ee-4a9e-aaae-a2591f45987d`
- **Purpose**: Retrieves actual consumption data including billed and non-billed credits
- **Date Requirements**: 
  - Dates are **MANDATORY** (API returns empty without them)
  - Format: `MM-DD-YYYY`
  - Recommended range: **365 days** for complete historical data
  - Testing showed 365-day range returns 13x more data than 30-day range (1495 MB vs 112 MB)

**Important Notes**:
- This API is **version 0.1-alpha** (pre-release/unsupported)
- No official Microsoft documentation exists
- Discovered by inspecting network traffic in PPAC browser developer tools (F12)
- May change or be deprecated without notice
- Returns consumption broken down by:
  - Channel (M365 Copilot, Teams, Autonomous)
  - Feature type (Classic answer, Agent flow actions, Generative AI tools)
  - Billable vs Non-billable consumption

## Scripts

### Get-CompleteCopilotReport.ps1 (Recommended - All-in-One Solution)
Comprehensive script with automated service principal setup that retrieves all available data.

**Features**:
- ✅ **Zero-parameter execution** - automated service principal creation
- ✅ Power Platform CLI auto-installation via winget
- ✅ Interactive environment selection and multi-environment registration
- ✅ Queries three APIs: Power Platform Admin, Dataverse (per-environment), Licensing
- ✅ Comprehensive agent data: metadata, owners, descriptions, timestamps, credits
- ✅ Single service principal works across all registered environments
- ✅ Smart data merging from multiple sources
- ✅ Detailed progress indicators and execution summary
- ✅ Timestamped CSV output

**Parameters**:
- `-TenantId`: Azure AD Tenant ID (optional for first run, stored in credentials)
- `-ClientId`: Service principal application ID (optional, prompts if not provided)
- `-ClientSecret`: Service principal secret (optional, prompts if not provided)

**Usage**:
```powershell
# First run - interactive setup with service principal creation
.\Get-CompleteCopilotReport.ps1
# Follow prompts: Create SP? → Select environment → Register to more environments?
# Script displays credentials to save for future runs

# Subsequent runs - automated with saved credentials
.\Get-CompleteCopilotReport.ps1 -TenantId "..." -ClientId "..." -ClientSecret "..."

# Scheduled/automated execution
.\Get-CompleteCopilotReport.ps1 `
  -TenantId $env:COPILOT_TENANT_ID `
  -ClientId $env:COPILOT_CLIENT_ID `
  -ClientSecret $env:COPILOT_CLIENT_SECRET
```

**Output**: `CopilotAgents_CompleteReport_YYYYMMDD_HHMMSS.csv`
- All agents with 12/12 available fields
- Environment details (name, region, type)
- Owner and creator names
- Credits consumption (billed + non-billed)
- Execution summary with statistics

**Setup Documentation**: See [docs/ENTRA-APP-SETUP.md](docs/ENTRA-APP-SETUP.md) for detailed setup guide

### Legacy Scripts (Optional - Individual Components)

<details>
<summary>Click to expand legacy scripts</summary>

#### Get-AllAgents-InventoryAPI-v2.ps1
Original script using Power Platform Inventory API (Note: KQLOM format may be deprecated).

**Note**: This script may fail due to recent API changes. Use `Get-CompleteCopilotReport.ps1` instead.

#### Get-CopilotCredits-v2.ps1
Standalone credits retrieval using the Licensing API.

**Parameters**:
- `-TenantId`: Azure AD Tenant ID
- `-LookbackDays`: Number of days (default: 365)

**Usage**:
```powershell
.\Get-CopilotCredits-v2.ps1 -LookbackDays 365
```

#### Merge-InventoryAndCredits.ps1
Merges separately generated Inventory and Credits CSV files.

**Usage**:
```powershell
.\Merge-InventoryAndCredits.ps1
```

</details>

## Prerequisites

- PowerShell 5.1 or higher
- Power Platform admin access
- Permissions to authenticate to:
  - `https://api.powerplatform.com`
  - `https://licensing.powerplatform.microsoft.com`

## Authentication

### Get-CompleteCopilotReport.ps1 - Service Principal (Automated)
Uses **OAuth 2.0 Client Credentials Flow** with service principal:

**First Run (Interactive Setup)**:
1. Script checks for pac CLI, auto-installs if needed
2. Prompts: "Do you need to create a new service principal? (Y/N)"
3. If Y: Authenticates to Power Platform (`pac auth create`)
4. Lists environments, prompts for selection
5. Creates service principal: `pac admin create-service-principal --environment {id}`
6. Displays credentials (ClientId, ClientSecret) with example command
7. Optionally registers service principal to additional environments
8. Proceeds with data collection

**Subsequent Runs (Automated)**:
- Provide credentials as parameters
- Script authenticates silently using service principal
- No user interaction required (suitable for automation)

**Required Role**: Power Platform Administrator (for service principal creation)

### Legacy Scripts - Device Code Flow
Older scripts use **OAuth 2.0 Device Code Flow**:
1. Script displays a device code
2. Browser opens to `https://microsoft.com/devicelogin`
3. Enter the code and authenticate
4. Script continues after authentication

## Workflow

### Recommended: Single Script with Automated Setup
```powershell
cd scripts
.\Get-CompleteCopilotReport.ps1
```

This handles everything automatically:

**Setup Phase** (first run only):
1. Checks for Power Platform CLI (installs if needed)
2. Prompts to create service principal
3. Authenticates to Power Platform
4. Lists available environments
5. Creates service principal for selected environment
6. Parses and displays credentials
7. Optionally registers to additional environments

**Data Collection Phase** (every run):
1. Authenticates using service principal (3 tokens: Admin API, Dataverse, Licensing)
2. Queries Power Platform Admin API → All environments
3. For each environment: Queries Dataverse API → Bots, owners, creators
4. Queries Licensing API → Credits consumption data
5. Merges all datasets (agents + environments + owners + credits)
6. Generates timestamped CSV report with execution summary

### Alternative: Legacy 3-Step Process

<details>
<summary>Click for manual 3-step workflow</summary>

1. **Run Inventory API script**:
   ```powershell
   .\Get-AllAgents-InventoryAPI-v2.ps1
   ```

2. **Run Credits API script**:
   ```powershell
   .\Get-CopilotCredits-v2.ps1
   ```

3. **Merge the datasets**:
   ```powershell
   .\Merge-InventoryAndCredits.ps1
   ```

**Note**: The Inventory API script may fail due to recent API changes. Use the comprehensive script instead.

</details>

## Limitations & Considerations

### Current Limitations

1. **Service Principal Registration Required**
   - Service principal must be registered to each environment individually
   - Registration done via `pac admin create-service-principal --environment {id}`
   - Script supports multi-environment registration during setup
   - Future environments require manual registration or re-running setup

2. **Active Users Metric**
   - Not available in any API endpoint
   - Microsoft Analytics API only shows aggregate tenant metrics
   - Individual agent user counts not exposed via any known API

3. **Per-Environment API Calls**
   - Dataverse API requires separate call per environment
   - Large tenants with many environments may have longer execution times
   - Rate limiting considerations for environments with many agents

4. **Credits Data Availability**
   - Only available for agents with actual usage
   - Historical data limited to lookback period
   - Licensing API is undocumented (v0.1-alpha) and may change

### Tested but Non-Working Approaches

The following approaches were tested but did not provide the required data:

1. **Power Platform Inventory API (KQLOM JSON format)**
   - Initially worked, then broke with API changes
   - Returns "KQLOM format is wrong or it cannot be null" error
   - Microsoft documentation examples also fail
   - **Solution**: Switched to Azure Resource Graph with direct KQL

2. **Official Licensing API** (`/entitlements/MCSMessages/summary`)
   - Returns license capacity (50,000 messages)
   - Does NOT return actual consumption data

3. **Microsoft.PowerPlatform.SDK**
   - .NET SDK does not expose credits/consumption APIs
   - Compilation issues with current SDK version

4. **PPAC Export API** (`/api/PowerPlatform/Environment/Export`)
   - Returns 405 Method Not Allowed
   - Not accessible via public authentication

## Testing Results

### Date Range Impact (Credits API)
| Range | Resources Found | Billed (MB) | Non-Billed (MB) | Total (MB) |
|-------|----------------|-------------|-----------------|------------|
| No dates | 0 | 0 | 0 | 0 |
| 7 days | 0 | 0 | 0 | 0 |
| 30 days | 10 | 14.38 | 98.16 | 112.54 |
| 60 days | 10 | 14.38 | 98.16 | 112.54 |
| 90 days | 10 | 14.38 | 98.16 | 112.54 |
| **365 days** | **29** | **665.58** | **829.81** | **1495.39** |

**Recommendation**: Use 365-day lookback for complete historical data.

### Actual Test Results
- **Total Agents**: 115 (Inventory API)
- **Agents with Usage**: 34 (Credits API)
- **Agents without Usage**: 81
- **Total Consumption**: 5,505.82 MB (3,479.58 billed + 2,026.24 non-billed)
- **Environments**: 8

## Troubleshooting

### Script Errors

**400 Bad Request (Inventory API)**
- Ensure query format matches exact schema
- Do not add `-ContentType` parameter separately (already in headers)

**Empty Results (Credits API)**
- Ensure `fromDate` and `toDate` parameters are included
- Use `MM-DD-YYYY` format
- Try increasing lookback days to 365

**Authentication Fails**
- Ensure you have Power Platform admin access
- Check if conditional access policies are blocking device code flow
- Try using a different browser for authentication

### Common Issues

1. **Credits API returns 404**
   - This is a v0.1-alpha endpoint (unsupported)
   - Endpoint may change without notice
   - Verify endpoint URL matches current PPAC behavior

2. **Different agent counts**
   - Inventory API: Returns ALL agents (115)
   - Credits API: Returns only agents with usage (34)
   - This is expected behavior

3. **Date range confusion**
   - Credits API requires explicit date parameters
   - Default script uses 365-day lookback
   - Adjust `-LookbackDays` parameter as needed

## Data Structure

### Complete Report Schema
```csv
Agent ID, Agent Name, Environment, Environment ID, Environment Type, 
Environment Region, Created On, Modified On, Published On, Owner, 
Created In, Billed Credits (MB), Non-Billed Credits (MB), 
Total Credits (MB), Has Usage
```

### Credits Breakdown
Credits are tracked per:
- **Channel**: M365 Copilot, Teams, Autonomous
- **Feature**: Classic answer, Agent flow actions, Text and generative AI tools
- **Type**: Billed vs Non-billable

## Important Disclaimers

⚠️ **Licensing API Status**
- The Credits API endpoint is **undocumented and unsupported**
- Discovered via browser developer tools (PPAC network traffic)
- Version `0.1-alpha` indicates pre-release status
- May change, break, or be deprecated without notice
- Use at your own risk for production scenarios

⚠️ **Data Accuracy**
- Credits data is point-in-time based on date range
- Historical data may be incomplete for agents created after the lookback period
- Zero credits may indicate no usage OR data not yet available

⚠️ **API Limitations**
- No official SLA or support from Microsoft
- Rate limiting unknown (not documented)
- Tenant-specific data only (no cross-tenant queries)

## Future Improvements

To achieve 12/12 fields, the following would be required:

1. **Dataverse Direct Query** for Solution ID
   - Requires per-environment authentication
   - Query: `dataverse://environments/{env}/tables/bot/rows/{agentId}?columns=solutionid`

2. **Agent Description** 
   - No known API endpoint
   - May require Microsoft to expose this field in Inventory API

3. **Active Users**
   - No known API endpoint
   - Would require Microsoft Analytics API enhancement

## Support

This is a community solution based on reverse-engineered APIs. For official support:
- Power Platform Admin Center: https://admin.powerplatform.microsoft.com
- Power Platform API documentation: https://learn.microsoft.com/power-platform/admin/

## License

MIT License - Use at your own risk

## Version History

- **v2.0** (2026-01-30): Service principal automation and complete field coverage
  - Automated service principal creation via pac CLI
  - Power Platform Admin API integration
  - Dataverse API per-environment queries
  - 12/12 fields available (all requested fields except Active Users)
  - Multi-environment registration support
  - Zero-parameter interactive setup
  - Removed Environment Type column (was always blank)
  - Fixed error handling and SecureString conversion issues

- **v1.0** (2026-01-11): Initial release
  - Azure Resource Graph integration
  - Credits API integration
  - 8/12 fields available

---

**Documentation Files:**
- README.md - Technical documentation and API reference
- scripts/README.md - Script usage and workflow diagram
- docs/ENTRA-APP-SETUP.md - Service principal setup guide
- EXECUTIVE_SUMMARY.md - Executive summary
- GITHUB_CHECKLIST.md - Implementation guide
- USAGE_INSTRUCTIONS.md - User guide

**Last Updated**: January 30, 2026
