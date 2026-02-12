import SwiftUI

struct AgentsPanelView: View {
    @Bindable var agentsVM: AgentsViewModel

    var body: some View {
        VStack(spacing: 0) {
            agentsHeader
            Divider().background(Theme.cardBorder)
            agentsList
        }
        .background(Theme.background)
        .task {
            await agentsVM.loadAgents()
        }
    }

    // MARK: - Header

    private var agentsHeader: some View {
        HStack {
            Image(systemName: "cpu")
                .foregroundStyle(Theme.accentGreen)
            Text("Agents")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.textPrimary)

            if agentsVM.runningCount > 0 {
                Text("\(agentsVM.runningCount)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.accentGreen.opacity(0.2))
                    .foregroundStyle(Theme.accentGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer()

            Button {
                Task { await agentsVM.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Refresh agents")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.cardBackground)
    }

    // MARK: - List

    private var agentsList: some View {
        ScrollView {
            if agentsVM.agents.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 6) {
                    ForEach(agentsVM.agents) { agent in
                        AgentCard(agent: agent)
                    }
                }
                .padding(8)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "cpu")
                .font(.largeTitle)
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
            Text("No Active Agents")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.textSecondary)
            Text("Agents will appear here when running.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }
}

// MARK: - Agent Card

private struct AgentCard: View {
    let agent: AgentSession
    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: agent.status.icon)
                    .font(.caption)
                    .foregroundStyle(agent.status.color)
                Text(agent.name)
                    .font(.caption.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(agent.runtime)
                    .font(.caption2.monospaced())
                    .foregroundStyle(Theme.textSecondary)
            }

            Text(agent.goal)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)

            HStack {
                Text(agent.status.label)
                    .font(.caption2.bold())
                    .foregroundStyle(agent.status.color)

                Spacer()

                Text(agent.lastActivityLabel)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)

                if let model = agent.model {
                    Text(model)
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                }
            }
        }
        .padding(8)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(agent.status == .running ? agent.status.color.opacity(0.3) : Theme.cardBorder, lineWidth: 1)
        )
    }
}
