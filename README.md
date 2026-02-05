# Beads Command Center

A modern visual command center for beads issue tracking across multiple projects.

## 🎯 Project Vision

**Phase 1: Web Dashboard** *(Current)*  
Starting as a single-page web application that provides an immediate visual command center for beads projects. Built with vanilla HTML/CSS/JS for simplicity and universal browser compatibility.

**Phase 2: Native SwiftUI App** *(Future)*  
Evolution into a native SwiftUI application for iOS and macOS, providing:
- Native performance and system integration
- Offline-first data synchronization
- iOS widgets for at-a-glance project status
- macOS menu bar integration
- Push notifications for issue updates
- Deep system integration with Shortcuts, Focus modes, and more

The web dashboard serves as both the MVP and a reference implementation for the native app's feature set and user experience.

## Features

- **🎨 Modern Dark Theme**: GitHub Projects meets Linear design aesthetic
- **📊 Multi-Project Support**: Unified view of NetMonitor and NetMonitor-iOS issues
- **📋 Kanban Board**: Visual columns for Open → In Progress → Blocked → Closed
- **⚡ Ready Queue**: Smart view showing issues with no unresolved blockers
- **🔍 Advanced Filtering**: Filter by status, priority, type, assignee + full-text search
- **📈 Live Statistics**: Total issues, progress tracking, completion percentage
- **🔗 Dependency Visualization**: See which issues block others
- **📱 Responsive Design**: Works seamlessly on desktop and tablet
- **🔄 Auto-refresh**: Loads latest data with manual refresh option

## Quick Start

1. **Refresh Data**: Run `./refresh.sh` to export latest beads data
2. **Open Dashboard**: Open `index.html` in your web browser
3. **Explore**: Switch between projects, use filters, click cards for details

## Data Sources

The dashboard loads data from:
- `data/netmonitor.json` (NetMonitor project)
- `data/netmonitor-ios.json` (NetMonitor iOS project)

Data is automatically exported from beads databases using the refresh script.

## Issue Cards

Each issue card displays:
- **Title & ID**: Clear identification
- **Priority**: Color-coded P0 (critical) to P3 (low)
- **Type**: Badge showing task/bug/feature/epic
- **Assignee**: Who's responsible
- **Dependencies**: Blue indicator if issue has blockers

## Views

### Kanban Board
Classic workflow visualization with drag-and-drop feel (visual only).

### Ready Queue  
Shows only issues that can be worked on immediately:
- Not closed
- No unresolved dependencies/blockers
- Ready for development

## Tech Stack

- **Pure HTML/CSS/JS**: No frameworks, no build tools, no npm dependencies
- **Modern CSS Grid**: Responsive layout that adapts to screen size
- **Vanilla JavaScript**: Clean, readable code with modern ES6+ features
- **JSON Data**: Simple file-based data source from beads exports

## File Structure

```
beads-command-center/
├── index.html          # Single-page application
├── refresh.sh          # Data export script
├── data/              # JSON exports from beads
│   ├── netmonitor.json
│   └── netmonitor-ios.json
└── README.md          # This file
```

## Development

The dashboard automatically processes beads data and normalizes field names for consistent display. It handles various status, priority, and type formats from different beads configurations.

### Data Processing
- **Status normalization**: open, in-progress, blocked, closed
- **Priority mapping**: P0-P3 with color coding
- **Type categorization**: task, bug, feature, epic

## Browser Compatibility

Works in all modern browsers with ES6+ support:
- Chrome 60+
- Firefox 55+
- Safari 12+
- Edge 79+

## Data Refresh

Run `./refresh.sh` to update dashboard data. The script:
1. Exports NetMonitor beads data to `data/netmonitor.json`
2. Exports NetMonitor-iOS beads data to `data/netmonitor-ios.json`
3. Dashboard auto-detects and loads new data on refresh

---

**Current Status**: 
- ✅ 30 total issues (7 NetMonitor + 23 NetMonitor-iOS)
- 📊 Data successfully loaded and dashboard functional
- 🎯 Ready for use as project command center