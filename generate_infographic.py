"""
Generate an infographic for the Copilot Studio Agent Reporting Solution
"""

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, Circle, FancyArrowPatch
import numpy as np

# Set up the figure with a clean white background
fig, ax = plt.subplots(figsize=(16, 20))
ax.set_xlim(0, 10)
ax.set_ylim(0, 24)
ax.axis('off')
fig.patch.set_facecolor('white')

# Color scheme
PRIMARY_BLUE = '#0078D4'  # Microsoft Blue
SECONDARY_BLUE = '#50E6FF'
GREEN = '#10B981'
ORANGE = '#F59E0B'
RED = '#EF4444'
GRAY = '#6B7280'
LIGHT_GRAY = '#F3F4F6'
DARK = '#1F2937'

# Title Section
title_box = FancyBboxPatch((0.5, 22), 9, 1.5,
                           boxstyle="round,pad=0.1",
                           edgecolor=PRIMARY_BLUE,
                           facecolor=PRIMARY_BLUE,
                           linewidth=3)
ax.add_patch(title_box)
ax.text(5, 22.75, 'Copilot Studio Agent',
        ha='center', va='center', fontsize=32, fontweight='bold', color='white')
ax.text(5, 22.25, 'Reporting Solution',
        ha='center', va='center', fontsize=28, fontweight='bold', color='white')

# Subtitle
ax.text(5, 21.4, 'PowerShell-based automated reporting for Power Platform agents',
        ha='center', va='center', fontsize=14, color=GRAY, style='italic')

# Problem Statement Box
problem_box = FancyBboxPatch((0.5, 19.2), 9, 1.8,
                             boxstyle="round,pad=0.1",
                             edgecolor=RED,
                             facecolor='#FEE2E2',
                             linewidth=2)
ax.add_patch(problem_box)
ax.text(5, 20.5, '🎯 THE CHALLENGE',
        ha='center', va='center', fontsize=18, fontweight='bold', color=RED)
ax.text(5, 20, 'No unified way to track Copilot Studio agent usage,',
        ha='center', va='center', fontsize=12, color=DARK)
ax.text(5, 19.6, 'consumption, and metadata across all environments',
        ha='center', va='center', fontsize=12, color=DARK)

# Key Features Section (3 columns)
feature_y = 17.5
ax.text(5, 18.2, '✨ KEY FEATURES',
        ha='center', va='center', fontsize=18, fontweight='bold', color=PRIMARY_BLUE)

# Feature 1
feat1_box = FancyBboxPatch((0.5, 15.5), 2.8, 2.3,
                           boxstyle="round,pad=0.08",
                           edgecolor=PRIMARY_BLUE,
                           facecolor=LIGHT_GRAY,
                           linewidth=2)
ax.add_patch(feat1_box)
ax.text(1.9, 17.3, '🔍', ha='center', va='center', fontsize=28)
ax.text(1.9, 16.8, 'Inventory', ha='center', va='center', fontsize=13, fontweight='bold', color=DARK)
ax.text(1.9, 16.5, 'Tracking', ha='center', va='center', fontsize=13, fontweight='bold', color=DARK)
ax.text(1.9, 16.05, 'All agents across', ha='center', va='center', fontsize=9, color=GRAY)
ax.text(1.9, 15.8, 'all environments', ha='center', va='center', fontsize=9, color=GRAY)

# Feature 2
feat2_box = FancyBboxPatch((3.6, 15.5), 2.8, 2.3,
                           boxstyle="round,pad=0.08",
                           edgecolor=GREEN,
                           facecolor=LIGHT_GRAY,
                           linewidth=2)
ax.add_patch(feat2_box)
ax.text(5, 17.3, '💰', ha='center', va='center', fontsize=28)
ax.text(5, 16.8, 'Credits', ha='center', va='center', fontsize=13, fontweight='bold', color=DARK)
ax.text(5, 16.5, 'Consumption', ha='center', va='center', fontsize=13, fontweight='bold', color=DARK)
ax.text(5, 16.05, 'Billed & non-billed', ha='center', va='center', fontsize=9, color=GRAY)
ax.text(5, 15.8, 'usage tracking', ha='center', va='center', fontsize=9, color=GRAY)

# Feature 3
feat3_box = FancyBboxPatch((6.7, 15.5), 2.8, 2.3,
                           boxstyle="round,pad=0.08",
                           edgecolor=ORANGE,
                           facecolor=LIGHT_GRAY,
                           linewidth=2)
ax.add_patch(feat3_box)
ax.text(8.1, 17.3, '📊', ha='center', va='center', fontsize=28)
ax.text(8.1, 16.8, 'Unified', ha='center', va='center', fontsize=13, fontweight='bold', color=DARK)
ax.text(8.1, 16.5, 'Reporting', ha='center', va='center', fontsize=13, fontweight='bold', color=DARK)
ax.text(8.1, 16.05, 'Merged CSV reports', ha='center', va='center', fontsize=9, color=GRAY)
ax.text(8.1, 15.8, 'ready for analysis', ha='center', va='center', fontsize=9, color=GRAY)

# Statistics Section
stats_y = 14
ax.text(5, 14.8, '📈 BY THE NUMBERS',
        ha='center', va='center', fontsize=18, fontweight='bold', color=PRIMARY_BLUE)

# Stat boxes
stat_data = [
    ('115', 'Total Agents\nDiscovered', PRIMARY_BLUE, 1.2),
    ('8/12', 'Data Fields\nAvailable', GREEN, 3.7),
    ('34', 'Agents with\nUsage Data', ORANGE, 6.2),
    ('365', 'Days Lookback\n(Recommended)', SECONDARY_BLUE, 8.7)
]

for value, label, color, x_pos in stat_data:
    stat_box = FancyBboxPatch((x_pos-0.6, 13), 1.5, 1.4,
                              boxstyle="round,pad=0.08",
                              edgecolor=color,
                              facecolor='white',
                              linewidth=3)
    ax.add_patch(stat_box)
    ax.text(x_pos+0.15, 13.9, value,
            ha='center', va='center', fontsize=20, fontweight='bold', color=color)
    ax.text(x_pos+0.15, 13.35, label,
            ha='center', va='center', fontsize=9, color=GRAY)

# How It Works Section
workflow_y = 11
ax.text(5, 12, '⚙️ HOW IT WORKS',
        ha='center', va='center', fontsize=18, fontweight='bold', color=PRIMARY_BLUE)

# Workflow steps
steps = [
    ('1', '🔐 Authenticate', 'OAuth 2.0\nDevice Code Flow', 1.5, PRIMARY_BLUE),
    ('2', '📥 Fetch Data', '2 API Endpoints\n(Inventory + Credits)', 4, GREEN),
    ('3', '🔄 Process', 'PowerShell\nScripts', 6.5, ORANGE),
    ('4', '📤 Export', 'CSV Reports\nReady', 9, SECONDARY_BLUE)
]

for num, title, desc, x_pos, color in steps:
    # Step circle
    circle = Circle((x_pos, 10.5), 0.35, color=color, zorder=10)
    ax.add_patch(circle)
    ax.text(x_pos, 10.5, num, ha='center', va='center',
            fontsize=16, fontweight='bold', color='white', zorder=11)

    # Step box
    step_box = FancyBboxPatch((x_pos-0.75, 9), 1.5, 1.2,
                              boxstyle="round,pad=0.06",
                              edgecolor=color,
                              facecolor=LIGHT_GRAY,
                              linewidth=2)
    ax.add_patch(step_box)
    ax.text(x_pos, 9.85, title, ha='center', va='center',
            fontsize=10, fontweight='bold', color=DARK)
    ax.text(x_pos, 9.35, desc, ha='center', va='center',
            fontsize=8, color=GRAY)

    # Arrows between steps
    if x_pos < 9:
        arrow = FancyArrowPatch((x_pos+0.4, 10.5), (x_pos+1.35, 10.5),
                               arrowstyle='->', mutation_scale=20,
                               linewidth=2, color=GRAY)
        ax.add_patch(arrow)

# Data Fields Section
fields_y = 7.2
ax.text(5, 8.2, '📋 AVAILABLE DATA FIELDS (8/12)',
        ha='center', va='center', fontsize=18, fontweight='bold', color=PRIMARY_BLUE)

# Available fields (left column)
available_box = FancyBboxPatch((0.5, 5.2), 4.3, 2.8,
                               boxstyle="round,pad=0.08",
                               edgecolor=GREEN,
                               facecolor='#D1FAE5',
                               linewidth=2)
ax.add_patch(available_box)
ax.text(2.65, 7.7, '✅ Available Fields',
        ha='center', va='center', fontsize=13, fontweight='bold', color=GREEN)

available_fields = [
    '• Agent Identifier & Name',
    '• Environment ID & Metadata',
    '• Created/Updated/Published dates',
    '• Agent Owner',
    '• Billed Copilot Credits',
    '• Non-Billed Credits',
    '• Publication Status'
]

y_pos = 7.2
for field in available_fields:
    ax.text(1, y_pos, field, ha='left', va='center', fontsize=9, color=DARK)
    y_pos -= 0.28

# Unavailable fields (right column)
unavailable_box = FancyBboxPatch((5.2, 5.2), 4.3, 2.8,
                                 boxstyle="round,pad=0.08",
                                 edgecolor=RED,
                                 facecolor='#FEE2E2',
                                 linewidth=2)
ax.add_patch(unavailable_box)
ax.text(7.35, 7.7, '❌ Not Available via API',
        ha='center', va='center', fontsize=13, fontweight='bold', color=RED)

unavailable_fields = [
    '• Agent Description',
    '• Solution ID',
    '• Active Users Count'
]

y_pos = 7.1
for field in unavailable_fields:
    ax.text(5.7, y_pos, field, ha='left', va='center', fontsize=10, color=DARK)
    y_pos -= 0.35

ax.text(7.35, 6.15, 'Requires Dataverse queries',
        ha='center', va='center', fontsize=8, color=GRAY, style='italic')
ax.text(7.35, 5.85, 'or not exposed by APIs',
        ha='center', va='center', fontsize=8, color=GRAY, style='italic')

# Technical Architecture
arch_y = 4
ax.text(5, 4.8, '🏗️ TECHNICAL ARCHITECTURE',
        ha='center', va='center', fontsize=18, fontweight='bold', color=PRIMARY_BLUE)

# API boxes
api1_box = FancyBboxPatch((0.5, 2.8), 4.3, 1.6,
                          boxstyle="round,pad=0.08",
                          edgecolor=PRIMARY_BLUE,
                          facecolor=LIGHT_GRAY,
                          linewidth=2)
ax.add_patch(api1_box)
ax.text(2.65, 4.1, '📡 Power Platform Inventory API',
        ha='center', va='center', fontsize=11, fontweight='bold', color=DARK)
ax.text(2.65, 3.75, '✓ Documented & Supported',
        ha='center', va='center', fontsize=9, color=GREEN)
ax.text(2.65, 3.45, 'Returns: Metadata, Owners,',
        ha='center', va='center', fontsize=8, color=GRAY)
ax.text(2.65, 3.2, 'Timestamps, Environment Info',
        ha='center', va='center', fontsize=8, color=GRAY)

api2_box = FancyBboxPatch((5.2, 2.8), 4.3, 1.6,
                          boxstyle="round,pad=0.08",
                          edgecolor=ORANGE,
                          facecolor=LIGHT_GRAY,
                          linewidth=2)
ax.add_patch(api2_box)
ax.text(7.35, 4.1, '📡 Licensing API (v0.1-alpha)',
        ha='center', va='center', fontsize=11, fontweight='bold', color=DARK)
ax.text(7.35, 3.75, '⚠️ Undocumented (Discovered)',
        ha='center', va='center', fontsize=9, color=ORANGE)
ax.text(7.35, 3.45, 'Returns: Billed & Non-Billed',
        ha='center', va='center', fontsize=8, color=GRAY)
ax.text(7.35, 3.2, 'Credits, Channel Breakdown',
        ha='center', va='center', fontsize=8, color=GRAY)

# PowerShell Scripts
scripts_box = FancyBboxPatch((2, 1.3), 6, 1.2,
                             boxstyle="round,pad=0.08",
                             edgecolor=SECONDARY_BLUE,
                             facecolor=LIGHT_GRAY,
                             linewidth=2)
ax.add_patch(scripts_box)
ax.text(5, 2.15, '🔧 PowerShell Scripts',
        ha='center', va='center', fontsize=11, fontweight='bold', color=DARK)
ax.text(5, 1.8, 'Get-AllAgents-InventoryAPI-v2.ps1  •  Get-CopilotCredits-v2.ps1  •  Merge-InventoryAndCredits.ps1',
        ha='center', va='center', fontsize=8, color=GRAY)

# Output
output_box = FancyBboxPatch((2.5, 0.2), 5, 0.9,
                            boxstyle="round,pad=0.08",
                            edgecolor=GREEN,
                            facecolor='#D1FAE5',
                            linewidth=3)
ax.add_patch(output_box)
ax.text(5, 0.85, '📊 Output: CopilotAgents_Complete_TIMESTAMP.csv',
        ha='center', va='center', fontsize=11, fontweight='bold', color=DARK)
ax.text(5, 0.5, 'Unified report with all agents, consumption data, and metadata',
        ha='center', va='center', fontsize=9, color=GRAY)

# Arrows connecting architecture
arrow1 = FancyArrowPatch((2.65, 2.8), (4, 2.5), arrowstyle='->', mutation_scale=15,
                        linewidth=2, color=PRIMARY_BLUE, linestyle='dashed')
ax.add_patch(arrow1)

arrow2 = FancyArrowPatch((7.35, 2.8), (6, 2.5), arrowstyle='->', mutation_scale=15,
                        linewidth=2, color=ORANGE, linestyle='dashed')
ax.add_patch(arrow2)

arrow3 = FancyArrowPatch((5, 1.3), (5, 1.1), arrowstyle='->', mutation_scale=15,
                        linewidth=2, color=GREEN, linestyle='dashed')
ax.add_patch(arrow3)

# Adjust layout and save
plt.tight_layout()
plt.savefig('copilot_reporting_infographic.png', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')
print("Infographic saved as 'copilot_reporting_infographic.png'")
plt.close()
