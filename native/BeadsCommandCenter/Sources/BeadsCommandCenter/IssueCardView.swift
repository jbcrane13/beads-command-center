import SwiftUI

struct IssueCardView: View {
    let issue: BeadsIssue
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(issue.id)
                        .font(.caption2.monospaced())
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(issue.priorityLabel)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.priorityColor(issue.priority).opacity(0.2))
                        .foregroundStyle(Theme.priorityColor(issue.priority))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Text(issue.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Label(issue.issueType.label, systemImage: issue.issueType.icon)
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary)

                    if let owner = issue.owner, !owner.isEmpty {
                        Spacer()
                        Text(owner)
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(10)
            .background(Theme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
