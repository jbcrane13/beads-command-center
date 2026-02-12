# CLAUDE.md — Beads Command Center

## Build & Development Commands

This is a Swift Package (SPM) project, NOT an Xcode project.

```bash
# Build
swift build

# Run (macOS only — SwiftUI app)
swift run BeadsCommandCenter

# Test (when tests exist)
swift test
```

## Architecture

**Swift Package** with multi-platform targets (macOS 14+, iOS 17+).

### Source Layout
```
native/BeadsCommandCenter/
├── Package.swift
└── Sources/BeadsCommandCenter/
    ├── BeadsCommandCenterApp.swift   # App entry point, dark theme, window sizing
    ├── BeadsIssue.swift              # Issue + status + type models (Codable)
    ├── BeadsProject.swift            # Project config with .beads/ detection
    ├── BeadsService.swift            # bd CLI subprocess actor (Process)
    ├── ProjectManager.swift          # @Observable project/issue state manager
    ├── Theme.swift                   # GitHub-dark color palette
    ├── ContentView.swift             # 3-panel layout (sidebar, center, right)
    ├── KanbanBoardView.swift         # 4-column kanban with drag-and-drop
    ├── ReadyQueueView.swift          # Unblocked issues list
    ├── IssueCardView.swift           # Compact draggable issue card
    ├── IssueDetailView.swift         # Full issue detail with quick actions
    ├── CreateIssueView.swift         # New issue form (title, type, priority)
    ├── SetupPromptView.swift         # Setup prompt for uninitialized projects
    ├── OpenClawService.swift         # HTTP + SSE streaming client for gateway
    ├── ChatViewModel.swift           # Chat message model + streaming state
    ├── ChatPanelView.swift           # Chat UI with message list + input
    ├── AgentsViewModel.swift         # Agent session model + supervisor-state reader
    ├── AgentsPanelView.swift         # Live agent status panel
    └── StatusBarView.swift           # Bottom bar with aggregate stats
```

### Data Layer
- Projects are discovered by scanning `~/Projects` for directories
- Initialized projects have `.beads/` directories
- Issue data comes from `bd list --status=all --json` (JSON array)
- Ready queue from `bd ready --json`
- Chat goes through OpenClaw gateway at `localhost:18789` via `/v1/chat/completions` (SSE streaming)
- Agent status read from `~/.openclaw/workspace/supervisor-state.json`
- The app does NOT initialize projects — that's `setup-project.sh`'s job
- If a project lacks setup, show a prompt to run the setup script

### Key Design Principle
**Complement, don't duplicate.** The `setup-project.sh` script handles:
- `bd init` (database creation)
- `bd hooks install` (git hooks)
- `bd setup claude` (Claude Code integration)
- Supervisor hooks and config

This app is a **viewer and command interface** — it reads beads data and provides
a visual dashboard. It never creates `.beads/` directories, installs hooks, or
writes config files. For uninitialized projects, it shows "Set up this project"
with the command to run.

## Conventions
- SwiftUI with `@Observable` (not ObservableObject) for new code
- Prefer Swift 5.9+ features
- Dark theme aesthetic (GitHub Projects meets Linear)
- No external dependencies — pure Swift/SwiftUI

## Issue Tracking
This project uses **bd (beads)** for issue tracking.
Run `bd prime` for workflow context.

**Quick reference:**
- `bd ready` - Find unblocked work
- `bd create "Title" --type task --priority 2` - Create issue
- `bd close <id>` - Complete work
- `bd sync` - Sync with git (run at session end)
