import SwiftUI

struct ReadyQueueView: View {
    var manager: ProjectManager
    @State private var selectedIssue: BeadsIssue?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ready Queue")
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("\(manager.readyIssues.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accentGreen.opacity(0.2))
                    .foregroundStyle(Theme.accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Text("Issues with no unresolved blockers, ready to work on.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 16)

            if manager.readyIssues.isEmpty {
                ContentUnavailableView(
                    "No Ready Issues",
                    systemImage: "checkmark.seal",
                    description: Text("All open issues have blockers, or there are no open issues.")
                )
                .foregroundStyle(Theme.textSecondary)
            } else {
                List {
                    ForEach(manager.readyIssues) { issue in
                        Button {
                            selectedIssue = issue
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(issue.id)
                                            .font(.caption.monospaced())
                                            .foregroundStyle(Theme.accentBlue)
                                        Text(issue.priorityLabel)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Theme.priorityColor(issue.priority).opacity(0.2))
                                            .foregroundStyle(Theme.priorityColor(issue.priority))
                                            .clipShape(RoundedRectangle(cornerRadius: 3))
                                    }
                                    Text(issue.title)
                                        .font(.body)
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                Spacer()
                                Label(issue.issueType.label, systemImage: issue.issueType.icon)
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(Theme.background)
        .sheet(item: $selectedIssue) { issue in
            IssueDetailView(issue: issue, manager: manager)
        }
    }
}
