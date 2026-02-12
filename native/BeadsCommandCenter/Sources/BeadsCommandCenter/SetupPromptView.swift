import SwiftUI

struct SetupPromptView: View {
    let project: BeadsProject

    private var setupCommand: String {
        "bash ~/.openclaw/workspace/scripts/setup-project.sh \"\(project.path)\" \"\(project.name)\""
    }

    var body: some View {
        VStack(spacing: 20) {
            ContentUnavailableView {
                Label("Not Initialized", systemImage: "folder.badge.questionmark")
                    .foregroundStyle(Theme.textSecondary)
            } description: {
                Text("This project doesn't have beads issue tracking set up yet.")
                    .foregroundStyle(Theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Run this command to initialize:")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textSecondary)

                HStack {
                    Text(setupCommand)
                        .font(.caption.monospaced())
                        .foregroundStyle(Theme.accentBlue)
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Theme.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button {
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(setupCommand, forType: .string)
                        #endif
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(Theme.accentBlue)
                    }
                    .buttonStyle(.plain)
                    .help("Copy command")
                }
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}
