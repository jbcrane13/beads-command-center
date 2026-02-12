import SwiftUI

enum DashboardTab: String, CaseIterable {
    case kanban = "Board"
    case ready = "Ready"
}

struct ContentView: View {
    @State private var manager = ProjectManager()
    @State private var chatVM = ChatViewModel()
    @State private var agentsVM = AgentsViewModel()
    @State private var selectedTab: DashboardTab = .kanban
    @State private var showingCreateSheet = false
    @State private var showingAddProject = false
    @State private var showRightPanel = true
    @State private var rightPanelWidth: CGFloat = 340

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Left: Project sidebar
                sidebar
                    .frame(width: 200)
                    .background(Theme.background)

                Divider().background(Theme.cardBorder)

                // Center: Board / Ready content
                centerPanel
                    .frame(minWidth: 400)

                if showRightPanel {
                    Divider().background(Theme.cardBorder)

                    // Right: Chat + Agents (resizable)
                    rightPanel
                        .frame(width: rightPanelWidth)
                        .overlay(alignment: .leading) {
                            ResizeHandle { delta in
                                rightPanelWidth = max(280, min(600, rightPanelWidth - delta))
                            }
                        }
                }
            }

            // Bottom status bar
            StatusBarView(manager: manager, agentsVM: agentsVM)
        }
        .background(Theme.background)
        .onChange(of: manager.selectedProject) { _, newProject in
            chatVM.setProjectContext(newProject?.path)
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Beads")
                    .font(.headline.bold())
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    showingAddProject = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Add project path")

                Button {
                    manager.discoverProjects()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Rescan projects")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.cardBackground)

            Divider().background(Theme.cardBorder)

            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(manager.projects) { project in
                        ProjectRow(
                            project: project,
                            isSelected: manager.selectedProject?.id == project.id
                        )
                        .onTapGesture {
                            manager.selectProject(project)
                        }
                    }
                }
                .padding(6)
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectSheet(manager: manager)
        }
    }

    // MARK: - Center Panel

    @ViewBuilder
    private var centerPanel: some View {
        if let project = manager.selectedProject {
            if project.isInitialized {
                projectDashboard
            } else {
                SetupPromptView(project: project)
            }
        } else {
            ContentUnavailableView("Select a Project", systemImage: "sidebar.left")
                .foregroundStyle(Theme.textSecondary)
                .background(Theme.background)
        }
    }

    @ViewBuilder
    private var projectDashboard: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                if let project = manager.selectedProject {
                    Text(project.name)
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                Picker("View", selection: $selectedTab) {
                    ForEach(DashboardTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Button {
                    showingCreateSheet = true
                } label: {
                    Label("New Issue", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentGreen)
                .keyboardShortcut("n", modifiers: .command)

                Button {
                    Task { await manager.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh issues")
                .keyboardShortcut("r", modifiers: .command)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showRightPanel.toggle()
                    }
                } label: {
                    Image(systemName: showRightPanel ? "sidebar.right" : "sidebar.right")
                        .foregroundStyle(showRightPanel ? Theme.accentBlue : Theme.textSecondary)
                }
                .help(showRightPanel ? "Hide chat panel" : "Show chat panel")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.cardBackground)

            // Error banner
            if let error = manager.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                    Spacer()
                    Button("Dismiss") { manager.errorMessage = nil }
                        .buttonStyle(.plain)
                }
                .font(.caption)
                .foregroundStyle(.white)
                .padding(8)
                .background(Theme.statusColor(.blocked).opacity(0.8))
            }

            // Loading
            if manager.isLoading {
                ProgressView()
                    .padding(8)
            }

            // Content
            switch selectedTab {
            case .kanban:
                KanbanBoardView(manager: manager)
            case .ready:
                ReadyQueueView(manager: manager)
            }
        }
        .background(Theme.background)
        .sheet(isPresented: $showingCreateSheet) {
            CreateIssueView(manager: manager)
        }
    }

    // MARK: - Right Panel (Chat + Agents)

    @ViewBuilder
    private var rightPanel: some View {
        VSplitView {
            ChatPanelView(chatVM: chatVM, projectPath: manager.selectedProject?.path)
                .frame(minHeight: 200)

            AgentsPanelView(agentsVM: agentsVM)
                .frame(minHeight: 120, idealHeight: 200)
        }
        .background(Theme.background)
    }
}

// MARK: - Project Row

private struct ProjectRow: View {
    let project: BeadsProject
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(project.isInitialized ? Theme.textPrimary : Theme.textSecondary)
                Text(project.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            if !project.isInitialized {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow.opacity(0.7))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Theme.accentBlue.opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .opacity(project.isInitialized ? 1.0 : 0.6)
    }
}

// MARK: - Resize Handle

private struct ResizeHandle: View {
    let onDrag: (CGFloat) -> Void

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 6)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        onDrag(value.translation.width)
                    }
            )
            #if os(macOS)
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            #endif
    }
}

// MARK: - Add Project Sheet

private struct AddProjectSheet: View {
    var manager: ProjectManager
    @Environment(\.dismiss) private var dismiss
    @State private var path = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Project Path")
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)

            Text("Enter the full path to a project directory.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)

            TextField("/path/to/project", text: $path)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)
                Button("Add") {
                    let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    manager.addManualProject(path: trimmed)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentBlue)
                .disabled(path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 350, minHeight: 150)
        .background(Theme.background)
    }
}
