import Foundation
import SwiftUI

struct AgentSession: Identifiable, Hashable {
    var id: String { name + goal }
    let name: String
    let goal: String
    let status: AgentStatus
    let startedAt: Date?
    let lastActivity: Date?
    let model: String?
    let projectPath: String?

    enum AgentStatus: String, Hashable {
        case running
        case idle
        case completed
        case failed
        case unknown

        var label: String { rawValue.capitalized }

        var icon: String {
            switch self {
            case .running: "play.circle.fill"
            case .idle: "pause.circle.fill"
            case .completed: "checkmark.circle.fill"
            case .failed: "xmark.circle.fill"
            case .unknown: "questionmark.circle"
            }
        }

        var color: Color {
            switch self {
            case .running: Theme.accentGreen
            case .idle: Color(red: 210/255, green: 153/255, blue: 34/255)
            case .completed: Theme.accentBlue
            case .failed: Color(red: 255/255, green: 123/255, blue: 114/255)
            case .unknown: Theme.textSecondary
            }
        }
    }

    var runtime: String {
        guard let start = startedAt else { return "--" }
        let elapsed = Date().timeIntervalSince(start)
        if elapsed < 60 { return "\(Int(elapsed))s" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m \(Int(elapsed.truncatingRemainder(dividingBy: 60)))s" }
        return "\(Int(elapsed / 3600))h \(Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60))m"
    }

    var lastActivityLabel: String {
        guard let last = lastActivity else { return "No activity" }
        let elapsed = Date().timeIntervalSince(last)
        if elapsed < 60 { return "Just now" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m ago" }
        return "\(Int(elapsed / 3600))h ago"
    }
}

@Observable
@MainActor
final class AgentsViewModel {
    var agents: [AgentSession] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private static let supervisorStatePath = "\(NSHomeDirectory())/.openclaw/workspace/supervisor-state.json"

    func loadAgents() async {
        isLoading = true
        errorMessage = nil

        do {
            agents = try await readSupervisorState()
        } catch {
            // Supervisor state not found is normal if no agents are running
            agents = []
            if case SupervisorError.fileNotFound = error {
                // Not an error — just no agents
            } else {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func refresh() async {
        await loadAgents()
    }

    // MARK: - Supervisor State Parsing

    private struct SupervisorState: Decodable {
        let sessions: [SessionEntry]?

        struct SessionEntry: Decodable {
            let name: String?
            let goal: String?
            let status: String?
            let startedAt: String?
            let lastActivity: String?
            let model: String?
            let projectPath: String?

            enum CodingKeys: String, CodingKey {
                case name, goal, status, model
                case startedAt = "started_at"
                case lastActivity = "last_activity"
                case projectPath = "project_path"
            }
        }
    }

    private func readSupervisorState() async throws -> [AgentSession] {
        let path = Self.supervisorStatePath
        guard FileManager.default.fileExists(atPath: path) else {
            throw SupervisorError.fileNotFound
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let decoder = JSONDecoder()

        // Try parsing as supervisor state with sessions array
        if let state = try? decoder.decode(SupervisorState.self, from: data),
           let sessions = state.sessions {
            return sessions.map { entry in
                AgentSession(
                    name: entry.name ?? "unnamed",
                    goal: entry.goal ?? "No goal specified",
                    status: parseStatus(entry.status),
                    startedAt: parseISO(entry.startedAt),
                    lastActivity: parseISO(entry.lastActivity),
                    model: entry.model,
                    projectPath: entry.projectPath
                )
            }
        }

        // Try as a flat dict keyed by session name
        if let dict = try? decoder.decode([String: SessionInfo].self, from: data) {
            return dict.map { (key, info) in
                AgentSession(
                    name: key,
                    goal: info.goal ?? "No goal specified",
                    status: parseStatus(info.status),
                    startedAt: parseISO(info.startedAt),
                    lastActivity: parseISO(info.lastActivity),
                    model: info.model,
                    projectPath: info.projectPath
                )
            }.sorted { ($0.name) < ($1.name) }
        }

        return []
    }

    private struct SessionInfo: Decodable {
        let goal: String?
        let status: String?
        let startedAt: String?
        let lastActivity: String?
        let model: String?
        let projectPath: String?

        enum CodingKeys: String, CodingKey {
            case goal, status, model
            case startedAt = "started_at"
            case lastActivity = "last_activity"
            case projectPath = "project_path"
        }
    }

    private func parseStatus(_ raw: String?) -> AgentSession.AgentStatus {
        guard let raw else { return .unknown }
        switch raw.lowercased() {
        case "running", "active": return .running
        case "idle", "waiting": return .idle
        case "completed", "done", "finished": return .completed
        case "failed", "error", "crashed": return .failed
        default: return .unknown
        }
    }

    private func parseISO(_ str: String?) -> Date? {
        guard let str else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: str) { return date }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: str)
    }

    // MARK: - Computed

    var runningCount: Int {
        agents.filter { $0.status == .running }.count
    }

    var totalCount: Int {
        agents.count
    }
}

enum SupervisorError: Error, LocalizedError {
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            "No supervisor state found — no agents are running"
        }
    }
}
