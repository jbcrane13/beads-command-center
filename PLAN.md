# PLAN.md — Beads Command Center

## Vision

A native SwiftUI dashboard for beads issue tracking across all projects. **Complements** `setup-project.sh` — this app is a viewer and command interface, never a project initializer.

## Responsibilities Split

### `setup-project.sh` owns:
- `bd init` — database creation
- `bd hooks install` — git hooks
- `bd setup claude` — Claude Code integration
- Supervisor hooks and config
- CLAUDE.md scaffolding

### Command Center owns:
- **Discover** projects (scan ~/Projects for `.beads/` dirs, or manual add)
- **Display** issues in Kanban/list/ready-queue views
- **Run** bd commands (create, update, close, sync) via subprocess
- **Detect** uninitialized projects → show "Run `setup-project.sh <path>`" prompt
- **Refresh** data from live bd databases (not stale JSON exports)

## Architecture

### Phase 1: Functional Dashboard (Current Target)
1. **Project Discovery** — Auto-scan for `.beads/` dirs + manual path config
2. **Live Data** — Shell out to `bd list --json` instead of static JSON files
3. **Kanban Board** — Open → In Progress → Blocked → Closed columns
4. **Ready Queue** — Issues with no unresolved blockers
5. **Issue Detail** — Full issue view with comments, deps, labels
6. **Quick Actions** — Create, update status, close issues from the UI
7. **Setup Detection** — For projects without `.beads/`, show setup prompt

### Phase 2: Polish & Integration
- Filtering (priority, type, assignee, text search)
- Statistics and progress tracking
- Dependency visualization
- Auto-refresh on file changes (FSEvents)
- Keyboard shortcuts

### Phase 3: iOS + Advanced
- iOS companion app
- Widgets for at-a-glance status
- macOS menu bar mode
- Push notifications via OpenClaw

## Data Flow

```
~/Projects/*/  ←── scan for .beads/ dirs
       │
       ▼
  ProjectManager (discovers projects)
       │
       ▼
  bd list --json  ←── subprocess call per project
       │
       ▼
  [BeadsIssue]  ←── decoded into Swift models
       │
       ▼
  SwiftUI Views (Kanban, List, Detail)
```

## Tech Decisions
- **Swift Package Manager** (not Xcode project) — simpler, cross-platform
- **@Observable** macro (not ObservableObject) — modern Swift 5.9+
- **No external deps** — pure Swift/SwiftUI
- **Subprocess for bd** — `Process()` to call `bd` CLI directly
- **Dark theme** — matches the web dashboard aesthetic
