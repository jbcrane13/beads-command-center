import Foundation

#if canImport(AppKit)
import AppKit
#endif

actor BeadsService {
    private func findBdPath() -> String {
        // Check common locations for bd CLI
        let candidates = [
            "/usr/local/bin/bd",
            "/opt/homebrew/bin/bd",
            "\(NSHomeDirectory())/.local/bin/bd",
            "\(NSHomeDirectory())/.cargo/bin/bd",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        // Fall back to PATH resolution via /usr/bin/env
        return "/usr/bin/env"
    }

    private func runBd(args: [String], in directory: String) async throws -> Data {
        let bdPath = findBdPath()
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        if bdPath == "/usr/bin/env" {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["bd"] + args
        } else {
            process.executableURL = URL(fileURLWithPath: bdPath)
            process.arguments = args
        }
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Inherit a reasonable PATH
        var env = ProcessInfo.processInfo.environment
        let extra = ["/usr/local/bin", "/opt/homebrew/bin",
                     "\(NSHomeDirectory())/.local/bin",
                     "\(NSHomeDirectory())/.cargo/bin"]
        let existing = env["PATH"] ?? "/usr/bin:/bin"
        env["PATH"] = (extra + [existing]).joined(separator: ":")
        process.environment = env

        do {
            try process.run()
        } catch {
            throw BeadsServiceError.bdNotFound
        }

        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let stderrText = String(data: stderrData, encoding: .utf8) ?? ""
            if !stderrText.isEmpty {
                throw BeadsServiceError.commandFailedWithMessage(stderrText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            throw BeadsServiceError.commandFailed(process.terminationStatus)
        }
        return data
    }

    func listIssues(in projectPath: String, status: String = "all") async throws -> [BeadsIssue] {
        let data = try await runBd(args: ["list", "--status=\(status)", "--json"], in: projectPath)
        // bd list --json outputs JSON array or JSONL depending on version
        // Try JSON array first, fall back to JSONL
        let decoder = JSONDecoder()
        if let issues = try? decoder.decode([BeadsIssue].self, from: data) {
            return issues
        }
        return BeadsIssue.parseJSONL(data)
    }

    func readyIssues(in projectPath: String) async throws -> [BeadsIssue] {
        let data = try await runBd(args: ["ready", "--json"], in: projectPath)
        let decoder = JSONDecoder()
        if let issues = try? decoder.decode([BeadsIssue].self, from: data) {
            return issues
        }
        return BeadsIssue.parseJSONL(data)
    }

    func createIssue(title: String, type: IssueType, priority: Int, in projectPath: String) async throws {
        _ = try await runBd(
            args: ["create", "--title", title, "--type", type.rawValue, "--priority", "\(priority)"],
            in: projectPath
        )
    }

    func updateStatus(issueId: String, status: IssueStatus, in projectPath: String) async throws {
        _ = try await runBd(
            args: ["update", issueId, "--status", status.rawValue],
            in: projectPath
        )
    }

    func closeIssue(issueId: String, in projectPath: String) async throws {
        _ = try await runBd(args: ["close", issueId], in: projectPath)
    }

    func syncProject(_ projectPath: String) async throws {
        _ = try await runBd(args: ["sync"], in: projectPath)
    }
}

enum BeadsServiceError: Error, LocalizedError {
    case commandFailed(Int32)
    case commandFailedWithMessage(String)
    case bdNotFound

    var errorDescription: String? {
        switch self {
        case .commandFailed(let code):
            "bd command failed with exit code \(code)"
        case .commandFailedWithMessage(let msg):
            "bd: \(msg)"
        case .bdNotFound:
            "bd CLI not found. Install beads: pip install beads-cli"
        }
    }
}
