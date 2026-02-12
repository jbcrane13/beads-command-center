import SwiftUI

struct KanbanBoardView: View {
    var manager: ProjectManager
    @State private var selectedIssue: BeadsIssue?
    @State private var showAllClosed = false

    private let columns: [IssueStatus] = [.open, .inProgress, .blocked, .closed]
    private let closedLimit = 15

    private func displayIssues(for status: IssueStatus) -> [BeadsIssue] {
        let all = manager.issuesForStatus(status)
        if status == .closed && !showAllClosed && all.count > closedLimit {
            return Array(all.prefix(closedLimit))
        }
        return all
    }

    private func totalCount(for status: IssueStatus) -> Int {
        manager.issuesForStatus(status).count
    }

    private func isLimited(for status: IssueStatus) -> Bool {
        status == .closed && !showAllClosed && totalCount(for: status) > closedLimit
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(columns, id: \.self) { status in
                    KanbanColumn(
                        status: status,
                        issues: displayIssues(for: status),
                        totalCount: totalCount(for: status),
                        isLimited: isLimited(for: status),
                        onSelect: { issue in selectedIssue = issue },
                        onShowAll: { showAllClosed = true }
                    )
                }
            }
            .padding(16)
        }
        .background(Theme.background)
        .sheet(item: $selectedIssue) { issue in
            IssueDetailView(issue: issue, manager: manager)
        }
    }
}

private struct KanbanColumn: View {
    let status: IssueStatus
    let issues: [BeadsIssue]
    let totalCount: Int
    var isLimited: Bool = false
    let onSelect: (BeadsIssue) -> Void
    var onShowAll: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Column header
            HStack {
                Circle()
                    .fill(Theme.statusColor(status))
                    .frame(width: 8, height: 8)
                Text(status.label)
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.textPrimary)
                Text("\(totalCount)")
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.cardBorder)
                    .foregroundStyle(Theme.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.bottom, 4)

            if issues.isEmpty {
                Text("No issues")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(issues) { issue in
                            IssueCardView(issue: issue) {
                                onSelect(issue)
                            }
                        }
                        if isLimited {
                            Button {
                                onShowAll?()
                            } label: {
                                Text("Show all \(totalCount) closed")
                                    .font(.caption)
                                    .foregroundStyle(Theme.accentBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .frame(width: 260)
        .padding(12)
        .background(Theme.background.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
