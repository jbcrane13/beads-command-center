import Foundation

enum IssueStatus: String, Codable, CaseIterable, Hashable {
    case open
    case inProgress = "in_progress"
    case blocked
    case closed

    var label: String {
        switch self {
        case .open: "Open"
        case .inProgress: "In Progress"
        case .blocked: "Blocked"
        case .closed: "Closed"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = IssueStatus(rawValue: raw) ?? .open
    }
}

enum IssueType: String, Codable, CaseIterable, Hashable {
    case task
    case bug
    case feature
    case epic
    case chore
    case unknown

    static var allCases: [IssueType] { [.task, .bug, .feature, .epic, .chore] }

    var label: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .task: "checkmark.circle"
        case .bug: "ladybug"
        case .feature: "star"
        case .epic: "flag"
        case .chore: "wrench"
        case .unknown: "questionmark.circle"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = IssueType(rawValue: raw) ?? .unknown
    }
}

struct BeadsIssue: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var description: String?
    var status: IssueStatus
    var priority: Int
    var issueType: IssueType
    var owner: String?
    var createdAt: String?
    var createdBy: String?
    var updatedAt: String?
    var closedAt: String?
    var closeReason: String?
    var dependencyCount: Int?
    var dependentCount: Int?
    var commentCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, description, status, priority, owner
        case issueType = "issue_type"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case updatedAt = "updated_at"
        case closedAt = "closed_at"
        case closeReason = "close_reason"
        case dependencyCount = "dependency_count"
        case dependentCount = "dependent_count"
        case commentCount = "comment_count"
    }

    var priorityLabel: String {
        switch priority {
        case 0: "P0"
        case 1: "P1"
        case 2: "P2"
        case 3: "P3"
        case 4: "P4"
        default: "P\(priority)"
        }
    }
}

extension BeadsIssue {
    static func parseJSONL(_ data: Data) -> [BeadsIssue] {
        guard let text = String(data: data, encoding: .utf8) else { return [] }
        let decoder = JSONDecoder()
        return text.split(separator: "\n").compactMap { line in
            guard let lineData = line.data(using: .utf8) else { return nil }
            return try? decoder.decode(BeadsIssue.self, from: lineData)
        }
    }
}
