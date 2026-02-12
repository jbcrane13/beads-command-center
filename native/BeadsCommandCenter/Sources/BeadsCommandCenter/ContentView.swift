import SwiftUI

enum DashboardTab: String, CaseIterable {
    case kanban = "Board"
    case ready = "Ready"
}

struct ContentView: View {
    @State private var manager = ProjectManager()
    @State private var selectedTab: DashboardTab = .kanban
    @State private var showingCreateSheet = false
    @State private var showingAddProject = false

    var body: some View {
        NavigationSplitView {
            sidebar
                #if os(macOS)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
                #endif
        } detail: {
            detail
        }
        .background(Theme.background)
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        List(selection: Binding(
            get: { manager.selectedProject?.id },
            set: { newId in
                if let project = manager.projects.first(where: { $0.id == newId }) {
                    manager.selectProject(project)
                }
            }
        )) {
            Section("Projects") {
                ForEach(manager.projects) { project in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(project.name)
                                .font(.headline)
                                .foregroundStyle(project.isInitialized ? Theme.textPrimary : Theme.textSecondary)
                            Text(project.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        if !project.isInitialized {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow.opacity(0.7))
                        }
                    }
                    .tag(project.id)
                    .opacity(project.isInitialized ? 1.0 : 0.6)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Beads")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showingAddProject = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .help("Add project path")

                Button {
                    manager.discoverProjects()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Rescan projects")
            }
        }
        .sheet(isPresented: $showingAddProject) {
            AddProjectSheet(manager: manager)
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
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
