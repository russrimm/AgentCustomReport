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

**Setup Documentation**: See [USAGE_INSTRUCTIONS.md](USAGE_INSTRUCTIONS.md) for detailed setup guide

## Prerequisites

- PowerShell 7 or higher
- Power Platform admin access

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

   ```

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

**Last Updated**: January 30, 2026
