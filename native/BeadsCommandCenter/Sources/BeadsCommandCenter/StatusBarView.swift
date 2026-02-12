import SwiftUI

struct StatusBarView: View {
    var manager: ProjectManager
    var agentsVM: AgentsViewModel

    var body: some View {
        HStack(spacing: 16) {
            // Agents status
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                    .font(.caption2)
                    .foregroundStyle(agentsVM.runningCount > 0 ? Theme.accentGreen : Theme.textSecondary)
                Text("\(agentsVM.runningCount) agent\(agentsVM.runningCount == 1 ? "" : "s") running")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }

            Divider()
                .frame(height: 12)

            // Open issues
            HStack(spacing: 4) {
                Circle()
                    .fill(Theme.statusColor(.open))
                    .frame(width: 6, height: 6)
                Text("\(manager.issuesForStatus(.open).count) open")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }

            // In progress
            HStack(spacing: 4) {
                Circle()
                    .fill(Theme.statusColor(.inProgress))
                    .frame(width: 6, height: 6)
                Text("\(manager.issuesForStatus(.inProgress).count) in progress")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }

            // Blocked
            let blockedCount = manager.issuesForStatus(.blocked).count
            if blockedCount > 0 {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.statusColor(.blocked))
                        .frame(width: 6, height: 6)
                    Text("\(blockedCount) blocked")
                        .font(.caption2)
                        .foregroundStyle(Color(red: 255/255, green: 123/255, blue: 114/255))
                }
            }

            Spacer()

            // Project name
            if let project = manager.selectedProject {
                Text(project.name)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.cardBackground)
        .overlay(alignment: .top) {
            Divider().background(Theme.cardBorder)
        }
    }
}
