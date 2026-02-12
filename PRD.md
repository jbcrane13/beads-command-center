# Beads Command Center — Product Requirements Document

**Version:** 1.0 Draft
**Date:** 2026-02-11
**Author:** Blake + Daneel

---

## 1. Vision

A native macOS (and eventually iOS) app that combines project management, AI chat, and agent orchestration into a single window. Think **Linear meets Cursor** — you see your issues, discuss them with your AI partner, and dispatch agents to do the work, all without leaving the app.

The Beads Dashboard (web) provides the baseline for issue visualization. We improve on it with a native experience, real-time chat integrated into the project context, and first-class agent management.

---

## 2. Target User

Blake (solo developer) managing multiple projects with AI assistance. The app replaces:
- Jumping between terminal (bd CLI), browser (Beads Dashboard), and chat (Telegram/webchat) to manage work
- Manually checking on agent sessions via tmux
- Context-switching between "planning" and "executing" modes

---

## 3. Core Principles

1. **Everything in one window** — Board, chat, and agents visible simultaneously
2. **Chat is the command layer** — Natural language to plan, create issues, dispatch work, review progress
3. **Agents are visible, not hidden** — See what's running, what it's doing, intervene when needed
4. **Complement, don't duplicate** — Uses `bd` CLI for issue tracking, OpenClaw gateway for AI, `setup-project.sh` for initialization
5. **Dark, fast, native** — SwiftUI, no Electron, feels like it belongs on macOS

---

## 4. Architecture

### 4.1 Chat Backend: OpenClaw Gateway

The app is a native OpenClaw client. All chat goes through the gateway API at `localhost:18789`.

```
┌─────────────────────────────────────┐
│         Beads Command Center        │
│                                     │
│  ┌──────────┐  ┌─────────────────┐  │
│  │  Board /  │  │     Chat        │  │
│  │  Epics /  │  │  (WebSocket or  │  │
│  │  History  │  │   REST to GW)   │  │
│  └──────────┘  └────────┬────────┘  │
│                          │          │
│  ┌──────────────────────┐│          │
│  │  Agents Panel        ││          │
│  │  (session status)    ││          │
│  └──────────────────────┘│          │
└──────────────────────────┼──────────┘
                           │
                           ▼
              ┌─────────────────────┐
              │  OpenClaw Gateway   │
              │  localhost:18789    │
              ├─────────────────────┤
              │  Main session       │ ← Chat messages
              │  Subagent sessions  │ ← Spawned tasks
              │  Tools / Skills     │ ← bd, git, etc.
              └─────────────────────┘
```

**Why OpenClaw, not direct API:**
- Full tool access (bd CLI, git, file system, web search, memory)
- Session continuity (Daneel remembers context across conversations)
- Subagent spawning for parallel work
- Existing skills and automation infrastructure
- Single auth (gateway token), no API key management in app

### 4.2 Agent Model: Hybrid

| Task Type | Handler | Visibility |
|---|---|---|
| Quick actions (create issue, update status, answer question) | Daneel via chat | Inline in chat |
| Planning (break down epic, prioritize backlog, review PRD) | Daneel via chat | Inline in chat |
| Implementation (fix bug, build feature, write tests) | Daneel spawns supervised Claude Code | Agents panel — live status |
| Monitoring (check on agent, nudge stuck session) | Daneel via watchdog | Agents panel + chat notification |

Agents are OpenClaw subagents (`sessions_spawn`) for lightweight tasks, or supervised Claude Code (tmux + hooks) for implementation work that needs a full coding environment.

### 4.3 Data Layer

| Data | Source | Method |
|---|---|---|
| Projects | Scan `~/Projects` for `.beads/` | `FileManager` + FSEvents |
| Issues | `bd list --json`, `bd ready --json` | `Process()` subprocess |
| Chat | OpenClaw gateway API | HTTP REST / WebSocket |
| Agent status | OpenClaw `sessions_list` API | HTTP polling |
| Issue mutations | `bd create`, `bd update`, `bd close` | `Process()` subprocess |

---

## 5. Features

### 5.1 Project Sidebar (P0)

- Auto-discover projects from `~/Projects` with `.beads/` directories
- Manual project add/remove
- Project health indicator (open issues count, blocked count)
- Uninitialized projects show setup prompt (existing behavior)
- Multi-project view option (aggregate all issues)

### 5.2 Board View (P0)

Kanban board — improved over Beads Dashboard:

- **Columns:** Open → In Progress → Blocked → Closed
- **Issue cards:** Title, ID badge, priority color, type icon, assignee
- **Drag-and-drop** to change status (calls `bd update`)
- **Quick filters:** Priority, type, assignee, text search
- **Column counts** and progress bar
- **Recent Activity** sidebar (last N status changes, comments, closes)
- **Inline create:** "+" button at top of Open column → quick-create popover

**Improvements over Beads Dashboard:**
- Dark theme (GitHub dark aesthetic)
- Richer cards (show dependencies, time since created/updated)
- Keyboard navigation (j/k to move between cards, Enter to open)
- Batch operations (select multiple → close, change priority)

### 5.3 Chat Panel (P0)

Full conversational interface to Daneel, contextual to the selected project.

**Layout:** Right-side panel (collapsible), or split view. Always visible alongside the board.

**Capabilities:**
- Natural language project management: "Create a bug for the login crash", "What's blocking the auth epic?", "Prioritize the backlog"
- Ask questions about code: "What does the NetworkService do?", "Show me recent commits"
- Dispatch work: "Fix the device detail hang", "Run the test suite", "Build and upload to TestFlight"
- Review agent output: "How's the fix-ios-theme agent doing?", "Show me the diff from the last commit"
- Planning: "Break this epic into tasks", "What should I work on next?"

**UX:**
- Message input with markdown support
- Streaming responses (token-by-token display)
- Code blocks with syntax highlighting
- Inline issue references (`#NetMonitor-x87` → clickable, shows issue card)
- Agent status cards embedded in chat (when agents are spawned/complete)
- Chat history persisted per project (or per session)

**Context injection:** When sending a message, include:
- Currently selected project path
- Currently selected issue (if any)
- Active agent sessions
- This gives Daneel automatic context without the user having to explain

### 5.4 Epics View (P1)

- Group issues by epic/parent
- Tree visualization (epic → child issues with status)
- Progress bars per epic (% complete)
- Dependency graph (which issues block which)
- Click epic → filtered board showing only that epic's issues

### 5.5 Agents Panel (P0)

Live view of all active coding agents.

**Per agent:**
- Name/task description
- Status: running / idle / completed / failed
- Runtime duration
- Last activity (from tmux pane capture or hook events)
- Actions: View output, Nudge, Kill

**Aggregate:**
- Total active agents
- Resource usage (CPU estimate)
- Recent completions with results

**Integration:** 
- Data from `supervisor-state.json` + OpenClaw `sessions_list`
- "Spawn Agent" button → opens dialog with task prompt, model selection
- Agent completion → notification + chat message

### 5.6 History View (P1)

- Timeline of all issue changes, agent runs, chat interactions
- Filterable by date, type (issue change, agent event, chat)
- Git integration: show commits alongside issue closes
- Searchable

### 5.7 Issue Detail (P0)

Full issue view when clicking a card:

- Title, description (editable)
- Status, priority, type (editable dropdowns)
- Labels, assignee
- Dependencies (blocks/blocked-by with linked cards)
- Comments thread
- Activity log (status changes, who/when)
- "Chat about this" button → opens chat with issue pre-selected as context
- "Assign to agent" button → spawns agent with issue context

### 5.8 Quick Actions Bar (P1)

Global keyboard shortcut (⌘K) opens command palette:
- "Create issue..."
- "Search issues..."
- "Switch project..."
- "Ask Daneel..."
- "Spawn agent..."
- Recent actions

---

## 6. Non-Functional Requirements

### 6.1 Performance
- App launch to usable: < 2 seconds
- Project switch + issue load: < 500ms
- Chat response start (first token): < 1 second
- Kanban drag-and-drop: 60fps, no jank

### 6.2 Platform
- macOS 14+ (Sonoma) — primary target
- iOS 17+ — future (Phase 2)
- Swift Package Manager (no Xcode project dependency)
- Pure SwiftUI + Foundation — no external deps for v1

### 6.3 Reliability
- Graceful handling of: bd not found, gateway offline, empty projects
- Chat works offline (queues messages, syncs when gateway available)
- No data loss — all mutations go through bd CLI (git-backed)

---

## 7. Technical Decisions

### 7.1 Gateway Communication

**Option A: REST API (recommended for v1)**
- `POST /api/sessions/send` for chat messages
- `GET /api/sessions/list` for agent status
- Simple, well-understood, easy to debug
- Polling for responses (every 500ms when waiting)

**Option B: WebSocket (future optimization)**
- Real-time streaming responses
- Push notifications for agent events
- More complex but better UX for chat

Start with REST, upgrade to WebSocket when we need streaming.

### 7.2 Chat Session Model

**Dedicated project sessions** (recommended):
- Each project gets its own OpenClaw session (via `sessions_send` with a label like `bcc-<project-name>`)
- Context stays scoped to the project
- Multiple projects can have active chats simultaneously
- Session history persists in OpenClaw

Alternative: Single main session with project context injected per message. Simpler but loses per-project history.

### 7.3 State Persistence

| State | Storage |
|---|---|
| Project list (manual adds) | UserDefaults |
| Chat history | OpenClaw session history (via API) |
| Window layout preferences | UserDefaults |
| Issue data | Live from bd (no local cache for v1) |
| Agent state | supervisor-state.json + sessions_list |

---

## 8. UI Design Direction

### Theme
- **Dark-first** — `#0D1117` background, `#161B22` cards, `#30363D` borders
- GitHub dark meets Linear aesthetic
- Accent blue `#58A6FF` for links/selection, green `#238636` for positive actions
- Priority colors: P0=red, P1=orange, P2=blue, P3=gray

### Layout
```
┌──────────────────────────────────────────────────┐
│  ● ● ●  Beads Command Center          ⌘K  ⚙️    │
├────────┬─────────────────────────┬───────────────┤
│        │  Board  Epics  History  │   ⊕ Agent 1 🟢│
│  Proj  │─────────────────────────│   ⊕ Agent 2 🟡│
│  List  │                         │───────────────│
│        │  ┌Open┐┌InProg┐┌Block┐  │               │
│  NM    │  │    ││      ││     │  │   💬 Chat     │
│  NM-i  │  │    ││      ││     │  │               │
│  BCC   │  │    ││      ││     │  │  Blake: Fix   │
│        │  │    ││      ││     │  │  the login... │
│        │  │    ││      ││     │  │               │
│        │  └────┘└──────┘└─────┘  │  Daneel: On   │
│        │                         │  it. I'll...  │
│        │                         │               │
│        │                         │  [───────] ⏎  │
├────────┴─────────────────────────┴───────────────┤
│  ● 2 agents running  │  12 open  │  3 blocked    │
└──────────────────────────────────────────────────┘
```

- **Left:** Project sidebar (narrow, collapsible)
- **Center:** Board/Epics/History (main content)
- **Right:** Chat + Agents panel (collapsible, resizable split)
- **Bottom:** Status bar with aggregate stats

### Improvements Over Beads Dashboard (from screenshot)
1. **Dark theme** — current Dashboard is light; we go dark
2. **Chat is always present** — not a separate mode, it's a panel
3. **Agents are visible** — dedicated panel showing live status, not hidden
4. **Richer cards** — more info density per card
5. **Keyboard-first** — ⌘K palette, j/k navigation, shortcuts everywhere
6. **Native feel** — no web rendering, proper macOS chrome, menu bar integration

---

## 9. Phased Delivery

### Phase 1: Foundation (Target: This Week)
- [x] Project discovery + sidebar
- [x] Kanban board with live bd data
- [x] Issue detail view
- [x] Quick actions (create, update, close)
- [x] Dark theme
- [ ] **Chat panel** — OpenClaw gateway integration (REST)
- [ ] **Agents panel** — Read from supervisor-state.json + sessions_list
- [ ] **Drag-and-drop** on kanban columns
- [ ] **Window layout** — Three-panel with resizable splits

### Phase 2: Polish (Next Week)
- [ ] Streaming chat responses (WebSocket upgrade)
- [ ] Epics view with dependency graph
- [ ] History/activity timeline
- [ ] ⌘K command palette
- [ ] Inline issue references in chat
- [ ] Agent spawn from UI
- [ ] Keyboard navigation

### Phase 3: Power Features (Future)
- [ ] iOS companion
- [ ] macOS menu bar mode
- [ ] Widgets (issue counts, agent status)
- [ ] Multi-project aggregate view
- [ ] Git integration (commits, branches, PRs)
- [ ] Notifications via OpenClaw

---

## 10. Decisions Made

1. **Gateway auth:** Token auth is already enabled. App stores token in Keychain. Works locally and over Tailscale.
2. **Remote access:** Tailscale — gateway already has `tailscale.mode: "serve"`. App connects to `localhost:18789` (local) or Tailscale IP `100.108.40.44:18789` (remote). Settings screen lets user configure gateway URL.
3. **Chat session model:** One shared session. Daneel already has cross-project context. App injects current project/issue as context per message.
4. **Chat API:** OpenAI-compatible `/v1/chat/completions` endpoint with SSE streaming. Already supported by the gateway (just needs enabling in config). Standard pattern every Swift HTTP library handles.
5. **Agent visibility:** All OpenClaw sessions visible (via `sessions_list` equivalent), not just app-spawned ones.
6. **Offline mode:** Issue browsing (bd CLI) works offline. Chat/agents require gateway. Show clear "Gateway offline" state.

## 11. Gateway API Integration

### Chat: OpenAI-Compatible Endpoint

```
POST /v1/chat/completions
Authorization: Bearer <gateway-token>
x-openclaw-agent-id: main
Content-Type: application/json

{
  "model": "openclaw:main",
  "stream": true,
  "user": "bcc",  // stable session key
  "messages": [
    {"role": "user", "content": "[Project: NetMonitor-iOS] What should I work on next?"}
  ]
}
```

**Enable in config:**
```json
{ "gateway": { "http": { "endpoints": { "chatCompletions": { "enabled": true } } } } }
```

Response: SSE stream (`data: <json>` lines, ends with `data: [DONE]`).

### Gateway WebSocket (Alternative)

The Control UI already uses WebSocket (`chat.send`, `chat.history`, `chat.inject`). We could use the same protocol for richer integration (history sync, inject assistant notes, etc.). Consider for Phase 2.

### Session Management

Use `user: "bcc"` field to route all app chat to a stable session. This means:
- Chat history persists across app launches
- Same session whether local or remote
- Daneel sees full conversation context

## 12. Configuration Required

Before the app works, enable the chat completions endpoint:

```bash
openclaw config set gateway.http.endpoints.chatCompletions.enabled true
```

Or via config patch. The gateway token and Tailscale are already configured.

## 13. Open Questions (Remaining)

1. **Ship name:** "Beads Command Center" is long. Ideas?
2. **Webchat channel vs custom:** Should the app register as a proper OpenClaw channel (like Telegram/WhatsApp), or just use the OpenAI endpoint? Channel gives us reactions, typing indicators, etc. OpenAI endpoint is simpler.
3. **Multi-user future:** If other devs use this, each would need their own OpenClaw instance. Fine for now (solo dev), but worth noting.

---

*This PRD is a living document. Update as decisions are made and features ship.*
