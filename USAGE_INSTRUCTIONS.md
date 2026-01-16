# Usage Instructions for Get-CopilotAgents-Official.ps1

## Quick Start

### Basic Usage (Auto-detect tenant)
```powershell
cd scripts
.\Get-CopilotAgents-Official.ps1
```

### Specify Output Path
```powershell
.\Get-CopilotAgents-Official.ps1 -OutputPath ".\my-agents.csv"
```

### Specify Tenant ID
```powershell
.\Get-CopilotAgents-Official.ps1 -TenantId "your-tenant-id-here"
```

### Full Example
```powershell
.\Get-CopilotAgents-Official.ps1 -OutputPath ".\reports\agents.csv" -TenantId "b22f8675-8375-455b-941a-67bee4cf7747"
```

## What the Script Does

1. **Authenticates** using OAuth 2.0 Device Code Flow
   - Opens browser to https://microsoft.com/devicelogin
   - You enter the code displayed
   - Script waits for authentication

2. **Queries Copilot Studio Agents** using official Inventory API
   - Resource type: `'microsoft.copilotstudio/agents'`
   - Returns all agents across all environments

3. **Queries Power Platform Environments**
   - Gets environment names, types, regions
   - Joins with agent data

4. **Exports to CSV** with 18 fields:
   - Agent ID, Name, Type, Description
   - Environment ID, Name, Type, Region, Default status
   - Owner ID and Name
   - Created By ID and Name
   - Created At, Modified At, Published On
   - Is Published (Yes/No)
   - Resource ID, Location

## Expected Output

### Console Output
```
╔══════════════════════════════════════════════════════════════════════╗
║         COPILOT STUDIO AGENTS - INVENTORY API (OFFICIAL)            ║
╚══════════════════════════════════════════════════════════════════════╝

Configuration:
  API Endpoint: https://api.powerplatform.com
  API Version:  2024-10-01
  Output Path:  CopilotAgents_Inventory.csv

🔐 Authenticating to https://api.powerplatform.com...

   ╔═══════════════════════════════════════════════════════════════╗
   ║  🌐 Open: https://microsoft.com/devicelogin                  ║
   ║  📋 Code: ABC123XYZ                                          ║
   ╚═══════════════════════════════════════════════════════════════╝

   ✅ Authentication successful!

📊 Querying Copilot Studio agents...
   ✅ Found 115 agents
   Total records: 115

🌍 Querying Power Platform environments...
   ✅ Found 8 environments

🔗 Joining agent and environment data...
   ✅ Successfully joined 115 agents with environment data

💾 Exporting to CSV...
   ✅ Exported to: CopilotAgents_Inventory.csv

╔══════════════════════════════════════════════════════════════════════╗
║                            SUCCESS!                                  ║
╚══════════════════════════════════════════════════════════════════════╝

📊 SUMMARY:
   Total Agents:        115
   Total Environments:  8
   Published Agents:    89
   Unpublished Agents:  26

🌍 TOP 10 ENVIRONMENTS BY AGENT COUNT:
   Production Environment                   45 agents
   Development Environment                  28 agents
   Test Environment                         18 agents
   ...
```

### CSV File Structure
```csv
Agent ID,Agent Name,Agent Type,Description,Environment ID,...
00000000-0000-0000-0000-000000000001,Customer Support Bot,Copilot Studio,...
```

## Troubleshooting

### Issue: "No agents found"
**Possible causes:**
- No Copilot Studio agents exist in your tenant
- Insufficient permissions
- Wrong authentication account

**Solution:**
- Verify you're a Power Platform admin
- Check you authenticated with the correct account
- Try specifying explicit tenant ID

### Issue: Authentication fails
**Possible causes:**
- Conditional access policies blocking device code flow
- Network/firewall restrictions
- Expired device code

**Solution:**
- Check with your IT admin about conditional access
- Try different browser for authentication
- Re-run script if code expires

### Issue: "Results truncated"
**Meaning:** More than 1000 agents exist

**Solution:** Script handles this automatically with pagination (future enhancement needed for >1000 agents)

### Issue: "Agents have no matching environment"
**Meaning:** Some agents couldn't be matched to environments

**Possible causes:**
- Environment was deleted
- Agent in personal environment
- Environment not yet synchronized

**Solution:** This is informational only - agent data still exports with "Unknown" environment

## API Details

### Endpoint
```
POST https://api.powerplatform.com/resourcequery/resources/query?api-version=2024-10-01
```

### Query Structure
```json
{
  "TableName": "PowerPlatformResources",
  "Clauses": [
    {
      "$type": "where",
      "FieldName": "type",
      "Operator": "==",
      "Values": ["'microsoft.copilotstudio/agents'"]
    }
  ],
  "Options": {
    "Top": 1000,
    "Skip": 0
  }
}
```

### Response Format
```json
{
  "totalRecords": 115,
  "count": 115,
  "resultTruncated": 0,
  "data": [
    {
      "id": "...",
      "name": "agent-guid",
      "type": "microsoft.copilotstudio/agents",
      "location": "unitedstates",
      "properties": {
        "displayName": "Agent Name",
        "environmentId": "env-guid",
        "createdAt": "2025-01-01T00:00:00Z",
        ...
      }
    }
  ]
}
```

## Differences from Old Script

| Aspect | Old Script | New Script (Official) |
|--------|-----------|----------------------|
| Resource Type | `Microsoft.PowerPlatform/copilots` | `'microsoft.copilotstudio/agents'` |
| Operator | `in~` | `==` |
| Query Structure | Basic | Uses `project` and `orderby` |
| Authentication | Manual polling | Auto-polling with timeout |
| Error Handling | Basic | Comprehensive with guidance |
| Output Fields | 13 fields | 18 fields |
| Documentation | Based on testing | Based on Microsoft docs |

## Permissions Required

- **Power Platform Administrator** role
- **Global Administrator** role (alternative)
- **Dynamics 365 Administrator** role (alternative)

## Rate Limits

The Inventory API has rate limits (not publicly documented):
- Recommended: Don't run more than once per minute
- The script includes a single request per resource type
- No known hard limits for reasonable usage

## Data Freshness

- Data is typically updated within minutes
- Some properties may have a delay (e.g., usage statistics)
- Timestamps are in UTC

## Next Steps

After getting the inventory, you can:

1. **Get Credits Consumption**
   ```powershell
   .\Get-CopilotCredits-v2.ps1
   ```

2. **Merge Reports**
   ```powershell
   .\Merge-InventoryAndCredits.ps1
   ```

3. **Analyze in Excel/Power BI**
   - Open the CSV file
   - Create pivot tables
   - Build dashboards

## Support

For issues or questions:
- Check the troubleshooting section above
- Review the official documentation: https://learn.microsoft.com/en-us/power-platform/admin/inventory-api
- Open an issue on GitHub: https://github.com/sayedpfe/AgentCustomReport/issues
