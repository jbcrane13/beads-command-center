import Foundation

actor OpenClawService {
    private let baseURL: URL
    private let token: String

    init(baseURL: URL = URL(string: "http://localhost:18789")!, token: String = "") {
        self.baseURL = baseURL
        self.token = token
    }

    // MARK: - Chat Completions (SSE Streaming)

    struct ChatCompletionRequest: Encodable {
        let model: String
        let messages: [Message]
        let stream: Bool
        let user: String

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    struct ChatCompletionChunk: Decodable {
        let id: String?
        let choices: [Choice]?

        struct Choice: Decodable {
            let delta: Delta?
            let finishReason: String?

            enum CodingKeys: String, CodingKey {
                case delta
                case finishReason = "finish_reason"
            }
        }

        struct Delta: Decodable {
            let role: String?
            let content: String?
        }
    }

    func streamChat(
        messages: [(role: String, content: String)],
        onToken: @Sendable @escaping (String) -> Void,
        onDone: @Sendable @escaping () -> Void,
        onError: @Sendable @escaping (Error) -> Void
    ) async {
        let url = baseURL.appendingPathComponent("v1/chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = ChatCompletionRequest(
            model: "openclaw:main",
            messages: messages.map { .init(role: $0.role, content: $0.content) },
            stream: true,
            user: "bcc"
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            onError(error)
            return
        }

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                onError(OpenClawError.httpError(httpResponse.statusCode))
                return
            }

            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))

                if payload == "[DONE]" {
                    onDone()
                    return
                }

                guard let data = payload.data(using: .utf8),
                      let chunk = try? JSONDecoder().decode(ChatCompletionChunk.self, from: data),
                      let content = chunk.choices?.first?.delta?.content else {
                    continue
                }

                onToken(content)
            }

            // Stream ended without [DONE]
            onDone()
        } catch {
            onError(error)
        }
    }

    // MARK: - Gateway Health Check

    func checkHealth() async -> Bool {
        let url = baseURL.appendingPathComponent("health")
        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Settings

    static let gatewayURLKey = "OpenClawGatewayURL"
    static let gatewayTokenKey = "OpenClawGatewayToken"

    static func savedURL() -> URL {
        if let saved = UserDefaults.standard.string(forKey: gatewayURLKey),
           let url = URL(string: saved) {
            return url
        }
        return URL(string: "http://localhost:18789")!
    }

    static func savedToken() -> String {
        UserDefaults.standard.string(forKey: gatewayTokenKey) ?? ""
    }

    static func save(url: String, token: String) {
        UserDefaults.standard.set(url, forKey: gatewayURLKey)
        UserDefaults.standard.set(token, forKey: gatewayTokenKey)
    }
}

enum OpenClawError: Error, LocalizedError {
    case httpError(Int)
    case gatewayOffline

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            "Gateway returned HTTP \(code)"
        case .gatewayOffline:
            "OpenClaw gateway is offline"
        }
    }
}
