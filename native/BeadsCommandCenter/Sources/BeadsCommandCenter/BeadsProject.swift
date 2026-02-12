import Foundation

struct BeadsProject: Identifiable, Hashable {
    let id: String
    var name: String
    var path: String
    var isInitialized: Bool

    init(name: String, path: String) {
        self.id = path
        self.name = name
        self.path = path
        self.isInitialized = FileManager.default.fileExists(
            atPath: (path as NSString).appendingPathComponent(".beads")
        )
    }

    mutating func recheckInitialized() {
        isInitialized = FileManager.default.fileExists(
            atPath: (path as NSString).appendingPathComponent(".beads")
        )
    }
}
