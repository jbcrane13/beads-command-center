import SwiftUI

struct IssueDetailView: View {
    let issue: BeadsIssue
    var manager: ProjectManager

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header — fixed at top
            HStack {
                Text(issue.id)
                    .font(.headline.monospaced())
                    .foregroundStyle(Theme.accentBlue)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider().background(Theme.cardBorder)

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(issue.title)
                        .font(.title2.bold())
                        .foregroundStyle(Theme.textPrimary)

                    if let description = issue.description, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Metadata grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], alignment: .leading, spacing: 12) {
                        MetadataRow(label: "Status", value: issue.status.label, color: Theme.statusColor(issue.status))
                        MetadataRow(label: "Priority", value: issue.priorityLabel, color: Theme.priorityColor(issue.priority))
                        MetadataRow(label: "Type", value: issue.issueType.label)
                        MetadataRow(label: "Owner", value: issue.owner ?? "Unassigned")
                        if let created = issue.createdAt {
                            MetadataRow(label: "Created", value: formatDate(created))
                        }
                        if let updated = issue.updatedAt {
                            MetadataRow(label: "Updated", value: formatDate(updated))
                        }
                    }

                    if let depCount = issue.dependencyCount, depCount > 0 {
                        MetadataRow(label: "Dependencies", value: "\(depCount) blocking")
                    }
                    if let depByCount = issue.dependentCount, depByCount > 0 {
                        MetadataRow(label: "Dependents", value: "\(depByCount) waiting")
                    }

                    if let reason = issue.closeReason, !reason.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Close Reason")
                                .font(.caption.bold())
                                .foregroundStyle(Theme.textSecondary)
                            Text(reason)
                                .font(.body)
                                .foregroundStyle(Theme.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Divider().background(Theme.cardBorder)

                    // Quick actions
                    HStack(spacing: 12) {
                        if issue.status != .inProgress {
                            ActionButton(label: "Start", icon: "play.fill", color: Theme.statusColor(.inProgress)) {
                                Task { await manager.updateStatus(issueId: issue.id, status: .inProgress) }
                                dismiss()
                            }
                        }
                        if issue.status != .closed {
                            ActionButton(label: "Close", icon: "checkmark.circle.fill", color: Theme.accentGreen) {
                                Task { await manager.closeIssue(issueId: issue.id) }
                                dismiss()
                            }
                        }
                        if issue.status != .blocked {
                            ActionButton(label: "Block", icon: "exclamationmark.triangle.fill", color: Theme.statusColor(.blocked)) {
                                Task { await manager.updateStatus(issueId: issue.id, status: .blocked) }
                                dismiss()
                            }
                        }
                        if issue.status != .open {
                            ActionButton(label: "Reopen", icon: "arrow.uturn.left", color: Theme.accentBlue) {
                                Task { await manager.updateStatus(issueId: issue.id, status: .open) }
                                dismiss()
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 450, idealWidth: 500, minHeight: 400, idealHeight: 500)
        .background(Theme.background)
    }

    private func formatDate(_ iso: String) -> String {
        String(iso.prefix(10))
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String
    var color: Color = Theme.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
        }
    }
}

private struct ActionButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
