#!/bin/bash

# Beads Command Center - Data Refresh Script
# Exports JSON data from all beads projects

echo "🔄 Refreshing beads data..."

# Create data directory if it doesn't exist
mkdir -p data

# Export NetMonitor project
echo "📊 Exporting NetMonitor..."
cd ~/Projects/NetMonitor && bd export --json -o ~/Projects/beads-command-center/data/netmonitor.json

# Export NetMonitor-iOS project  
echo "📱 Exporting NetMonitor-iOS..."
cd ~/Projects/NetMonitor-iOS && bd export --json -o ~/Projects/beads-command-center/data/netmonitor-ios.json

# Return to dashboard directory
cd ~/Projects/beads-command-center

echo "✅ Data refresh complete!"
echo "📁 Data files:"
ls -la data/*.json