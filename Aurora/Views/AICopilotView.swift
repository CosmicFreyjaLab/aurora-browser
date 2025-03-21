import SwiftUI

struct AICopilotView: View {
    @EnvironmentObject var appState: AuroraAppState
    @State private var userInput: String = ""
    @State private var isProcessing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI Copilot")
                    .font(.headline)
                Spacer()
                Button(action: {
                    appState.toggleAICopilot()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(appState.aiMessages) { message in
                        MessageView(message: message)
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                TextField("Ask me anything...", text: $userInput, onCommit: sendMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: isProcessing ? "hourglass" : "paperplane.fill")
                }
                .disabled(userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            }
            .padding()
        }
        .frame(width: 300)
    }
    
    private func sendMessage() {
        guard !userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = AIMessage(role: .user, content: userInput)
        appState.aiMessages.append(userMessage)
        
        let question = userInput
        userInput = ""
        isProcessing = true
        
        AIService.shared.askQuestion(question)
        
        // This would normally be handled by the AIService response
        // but for this demo we'll simulate a response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = "I'm a simulated AI response to your question: \"\(question)\""
            let aiMessage = AIMessage(role: .assistant, content: response)
            appState.aiMessages.append(aiMessage)
            isProcessing = false
        }
    }
}

struct MessageView: View {
    let message: AIMessage
    
    var body: some View {
        HStack(alignment: .top) {
            if message.role == .assistant {
                Image(systemName: "brain")
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "person.circle")
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
            }
            
            Text(message.content)
                .padding(8)
                .background(message.role == .assistant ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Spacer()
        }
    }
}
