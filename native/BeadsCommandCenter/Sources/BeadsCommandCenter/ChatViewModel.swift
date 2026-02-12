import Foundation
import SwiftUI

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let role: ChatRole
    var content: String
    let timestamp: Date

    enum ChatRole: String, Hashable {
        case user
        case assistant
        case system
    }

    var isUser: Bool { role == .user }
}

@Observable
@MainActor
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isStreaming: Bool = false
    var gatewayOnline: Bool = false
    var errorMessage: String?

    private var service: OpenClawService
    private var currentProjectPath: String?

    init() {
        let url = OpenClawService.savedURL()
        let token = OpenClawService.savedToken()
        self.service = OpenClawService(baseURL: url, token: token)
    }

    func updateSettings() {
        let url = OpenClawService.savedURL()
        let token = OpenClawService.savedToken()
        service = OpenClawService(baseURL: url, token: token)
    }

    func setProjectContext(_ projectPath: String?) {
        currentProjectPath = projectPath
    }

    func checkGateway() async {
        gatewayOnline = await service.checkHealth()
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }

        // Build message with project context
        var content = text
        if let path = currentProjectPath {
            let name = (path as NSString).lastPathComponent
            content = "[Project: \(name)] \(text)"
        }

        let userMessage = ChatMessage(role: .user, content: text, timestamp: Date())
        messages.append(userMessage)
        inputText = ""
        errorMessage = nil

        // Create assistant placeholder for streaming
        let assistantMessage = ChatMessage(role: .assistant, content: "", timestamp: Date())
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1

        isStreaming = true

        // Build conversation history (last 20 messages for context window)
        let history = messages.dropLast(1).suffix(20).map { msg -> (role: String, content: String) in
            (role: msg.role.rawValue, content: msg.content)
        }
        let allMessages = Array(history) + [(role: "user", content: content)]

        await service.streamChat(
            messages: allMessages,
            onToken: { [weak self] token in
                Task { @MainActor in
                    guard let self else { return }
                    if assistantIndex < self.messages.count {
                        self.messages[assistantIndex].content += token
                    }
                }
            },
            onDone: { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    self.isStreaming = false
                    // Remove empty assistant message if no content received
                    if assistantIndex < self.messages.count &&
                       self.messages[assistantIndex].content.isEmpty {
                        self.messages.remove(at: assistantIndex)
                    }
                }
            },
            onError: { [weak self] error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isStreaming = false
                    self.errorMessage = error.localizedDescription
                    // Remove empty assistant placeholder
                    if assistantIndex < self.messages.count &&
                       self.messages[assistantIndex].content.isEmpty {
                        self.messages.remove(at: assistantIndex)
                    }
                }
            }
        )
    }

    func clearChat() {
        messages.removeAll()
        errorMessage = nil
    }
}
