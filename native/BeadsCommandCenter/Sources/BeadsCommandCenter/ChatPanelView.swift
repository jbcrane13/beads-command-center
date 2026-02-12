import SwiftUI

struct ChatPanelView: View {
    @Bindable var chatVM: ChatViewModel
    var projectPath: String?

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            Divider().background(Theme.cardBorder)
            messagesList
            Divider().background(Theme.cardBorder)
            inputArea
        }
        .background(Theme.background)
        .onChange(of: projectPath) { _, newPath in
            chatVM.setProjectContext(newPath)
        }
        .task {
            chatVM.setProjectContext(projectPath)
            await chatVM.checkGateway()
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .foregroundStyle(Theme.accentBlue)
            Text("Chat")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Circle()
                .fill(chatVM.gatewayOnline ? Theme.accentGreen : Color.red.opacity(0.8))
                .frame(width: 8, height: 8)
                .help(chatVM.gatewayOnline ? "Gateway online" : "Gateway offline")
            Button {
                chatVM.clearChat()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Clear chat")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.cardBackground)
    }

    // MARK: - Messages

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if chatVM.messages.isEmpty {
                        emptyState
                    } else {
                        ForEach(chatVM.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }

                    if chatVM.isStreaming {
                        HStack(spacing: 4) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Thinking...")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 12)
                        .id("streaming-indicator")
                    }
                }
                .padding(12)
            }
            .onChange(of: chatVM.messages.count) { _, _ in
                if let last = chatVM.messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: chatVM.messages.last?.content) { _, _ in
                if let last = chatVM.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundStyle(Theme.textSecondary.opacity(0.5))
            Text("Chat with Daneel")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.textSecondary)
            Text("Ask about your project, create issues, or dispatch work.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Input

    private var inputArea: some View {
        VStack(spacing: 4) {
            if let error = chatVM.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(error)
                        .font(.caption2)
                        .lineLimit(2)
                    Spacer()
                    Button {
                        chatVM.errorMessage = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.red.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }

            if !chatVM.gatewayOnline {
                HStack(spacing: 4) {
                    Image(systemName: "wifi.slash")
                        .font(.caption2)
                    Text("Gateway offline")
                        .font(.caption2)
                    Spacer()
                    Button("Retry") {
                        Task { await chatVM.checkGateway() }
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accentBlue)
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.top, 4)
            }

            HStack(spacing: 8) {
                TextField("Message Daneel...", text: $chatVM.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                    .lineLimit(1...5)
                    .onSubmit {
                        if !chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Task { await chatVM.sendMessage() }
                        }
                    }

                Button {
                    Task { await chatVM.sendMessage() }
                } label: {
                    Image(systemName: chatVM.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title3)
                        .foregroundStyle(
                            chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chatVM.isStreaming
                                ? Theme.textSecondary
                                : Theme.accentBlue
                        )
                }
                .buttonStyle(.plain)
                .disabled(chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chatVM.isStreaming)
            }
            .padding(10)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Theme.background)
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.isUser ? "You" : "Daneel")
                    .font(.caption2.bold())
                    .foregroundStyle(message.isUser ? Theme.accentBlue : Theme.accentGreen)

                Text(message.content.isEmpty ? " " : message.content)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(
                message.isUser
                    ? Theme.accentBlue.opacity(0.12)
                    : Theme.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if !message.isUser {
                Spacer(minLength: 40)
            }
        }
    }
}
