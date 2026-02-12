import Foundation
import SwiftUI

@Observable
@MainActor
final class ProjectManager {
    var projects: [BeadsProject] = []
    var selectedProject: BeadsProject?
    var issues: [BeadsIssue] = []
    var readyIssues: [BeadsIssue] = []
    var isLoading = false
    var errorMessage: String?

    private let service = BeadsService()
    private let scanRoot: String

    private static let manualPathsKey = "BeadsManualProjectPaths"

    init(scanRoot: String = "\(NSHomeDirectory())/Projects") {
        self.scanRoot = scanRoot
        discoverProjects()
        // Auto-select first initialized project
        if selectedProject == nil, let first = projects.first(where: { $0.isInitialized }) {
            selectProject(first)
        }
    }

    func discoverProjects() {
        var discovered: [BeadsProject] = []
        let fm = FileManager.default

        // Auto-scan ~/Projects
        if let entries = try? fm.contentsOfDirectory(atPath: scanRoot) {
            for entry in entries.sorted() {
                let fullPath = (scanRoot as NSString).appendingPathComponent(entry)
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else { continue }
                // Skip hidden directories
                guard !entry.hasPrefix(".") else { continue }
                discovered.append(BeadsProject(name: entry, path: fullPath))
            }
        }

        // Add manual paths from UserDefaults
        let manualPaths = UserDefaults.standard.stringArray(forKey: Self.manualPathsKey) ?? []
        for path in manualPaths {
            guard !discovered.contains(where: { $0.path == path }) else { continue }
            let name = (path as NSString).lastPathComponent
            discovered.append(BeadsProject(name: name, path: path))
        }

        // Sort: initialized projects first, then alphabetical
        projects = discovered.sorted { a, b in
            if a.isInitialized != b.isInitialized {
                return a.isInitialized
            }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }
    }

    func addManualProject(path: String) {
        var manualPaths = UserDefaults.standard.stringArray(forKey: Self.manualPathsKey) ?? []
        guard !manualPaths.contains(path) else { return }
        manualPaths.append(path)
        UserDefaults.standard.set(manualPaths, forKey: Self.manualPathsKey)
        discoverProjects()
    }

    func removeManualProject(path: String) {
        var manualPaths = UserDefaults.standard.stringArray(forKey: Self.manualPathsKey) ?? []
        manualPaths.removeAll { $0 == path }
        UserDefaults.standard.set(manualPaths, forKey: Self.manualPathsKey)
        discoverProjects()
    }

    func selectProject(_ project: BeadsProject) {
        selectedProject = project
        if project.isInitialized {
            Task { await loadIssues() }
        } else {
            issues = []
            readyIssues = []
        }
    }

    func loadIssues() async {
        guard let project = selectedProject, project.isInitialized else { return }
        isLoading = true
        errorMessage = nil
        do {
            async let allIssues = service.listIssues(in: project.path)
            async let ready = service.readyIssues(in: project.path)
            issues = try await allIssues
            readyIssues = (try? await ready) ?? issues.filter { $0.status == .open }
        } catch {
            errorMessage = error.localizedDescription
            issues = []
            readyIssues = []
        }
        isLoading = false
    }

    func createIssue(title: String, type: IssueType, priority: Int) async {
        guard let project = selectedProject else { return }
        do {
            try await service.createIssue(title: title, type: type, priority: priority, in: project.path)
            await loadIssues()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateStatus(issueId: String, status: IssueStatus) async {
        guard let project = selectedProject else { return }
        do {
            try await service.updateStatus(issueId: issueId, status: status, in: project.path)
            await loadIssues()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func closeIssue(issueId: String) async {
        guard let project = selectedProject else { return }
        do {
            try await service.closeIssue(issueId: issueId, in: project.path)
            await loadIssues()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        await loadIssues()
    }

    func issuesForStatus(_ status: IssueStatus) -> [BeadsIssue] {
        issues.filter { $0.status == status }
    }
}
