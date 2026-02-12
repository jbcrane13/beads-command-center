import SwiftUI

struct CreateIssueView: View {
    var manager: ProjectManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var issueType: IssueType = .task
    @State private var priority: Int = 2

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Issue")
                .font(.title3.bold())
                .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textSecondary)
                TextField("Issue title", text: $title)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Type")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.textSecondary)
                    Picker("Type", selection: $issueType) {
                        ForEach(IssueType.allCases, id: \.self) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    .labelsHidden()
                    #if os(macOS)
                    .pickerStyle(.menu)
                    #endif
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.textSecondary)
                    Picker("Priority", selection: $priority) {
                        Text("P0 Critical").tag(0)
                        Text("P1 High").tag(1)
                        Text("P2 Medium").tag(2)
                        Text("P3 Low").tag(3)
                        Text("P4 Backlog").tag(4)
                    }
                    .labelsHidden()
                    #if os(macOS)
                    .pickerStyle(.menu)
                    #endif
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)

                Button("Create") {
                    Task {
                        await manager.createIssue(title: title, type: issueType, priority: priority)
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentGreen)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 380, minHeight: 250)
        .background(Theme.background)
    }
}
