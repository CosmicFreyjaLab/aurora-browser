import SwiftUI

struct AICopilotView: View {
    @EnvironmentObject private var appState: AuroraAppState
    @State private var queryText: String = ""
    @State private var isProcessing: Bool = false
    @State private var scrollToBottom: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Nordic Electric AI styling
            HStack {
                Text("Aurora AI")
                    .font(.headline)
                    .foregroundColor(NordicElectricAI.textPrimary)
                    .nordicGlow(intensity: 0.5)
                
                Spacer()
                
                Button(action: {
                    appState.showAISettings = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(NordicElectricAI.textPrimary)
                }
                
                Button(action: {
                    appState.toggleAICopilot()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(NordicElectricAI.textPrimary)
                }
            }
            .padding()
            .background(NordicElectricAI.backgroundMedium)
            
            // Messages with Nordic Electric AI styling
            ScrollViewReader { scrollView in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(appState.aiMessages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Invisible spacer view for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                    }
                    .padding()
                }
                .background(NordicElectricAI.backgroundDeep)
                .onChange(of: appState.aiMessages.count) { _ in
                    withAnimation {
                        scrollView.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
                .onAppear {
                    withAnimation {
                        scrollView.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
            }
            
            // Context indicator
            if let context = appState.currentAIContext {
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(NordicElectricAI.accentCyan)
                    
                    Text("Using context from: \(context.url.host ?? context.url.absoluteString)")
                        .font(.caption)
                        .foregroundColor(NordicElectricAI.textSecondary)
                    
                    Spacer()
                    
                    Button(action: {
                        appState.clearAIContext()
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(NordicElectricAI.textSecondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(NordicElectricAI.surface)
            }
            
            // Input with Nordic Electric AI styling
            HStack {
                TextField("Ask me anything...", text: $queryText)
                    .padding(10)
                    .background(NordicElectricAI.surface)
                    .cornerRadius(20)
                    .foregroundColor(NordicElectricAI.textPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(NordicElectricAI.accentBlue.opacity(0.5), lineWidth: 1)
                    )
                    .disabled(isProcessing)
                
                Button(action: sendQuery) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: NordicElectricAI.accentBlue))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(NordicElectricAI.accentBlue)
                            .nordicGlow(color: NordicElectricAI.accentBlue, intensity: 0.7)
                    }
                }
                .padding(10)
                .background(
                    Circle()
                        .fill(NordicElectricAI.surface)
                        .shadow(color: NordicElectricAI.accentBlue.opacity(0.3), radius: 5)
                )
                .disabled(queryText.isEmpty && !isProcessing)
            }
            .padding()
            .background(NordicElectricAI.backgroundMedium)
        }
        .background(NordicElectricAI.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(NordicElectricAI.accentBlue.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: NordicElectricAI.accentBlue.opacity(0.2), radius: 15)
        .sheet(isPresented: $appState.showAISettings) {
            AISettingsView()
        }
    }
    
    private func sendQuery() {
        guard !queryText.isEmpty || isProcessing else { return }
        
        if isProcessing {
            // Cancel current query
            appState.aiService.cancelRequest()
            isProcessing = false
            return
        }
        
        let query = queryText
        queryText = ""
        
        // Add user message to chat
        let userMessage = AIMessage(role: .user, content: query)
        appState.aiMessages.append(userMessage)
        
        isProcessing = true
        
        // Generate AI response
        appState.aiService.generateResponse(
            prompt: query,
            context: appState.currentAIContext?.content
        ) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    let aiMessage = AIMessage(role: .assistant, content: response)
                    appState.aiMessages.append(aiMessage)
                    
                case .failure(let error):
                    let errorMessage = AIMessage(
                        role: .assistant,
                        content: "Sorry, I encountered an error: \(error.localizedDescription)"
                    )
                    appState.aiMessages.append(errorMessage)
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: AIMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .assistant {
                AvatarView(role: .assistant)
            } else {
                Spacer()
            }
            
            VStack(alignment: message.role == .assistant ? .leading : .trailing, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(
                        message.role == .assistant ?
                            NordicElectricAI.surface :
                            LinearGradient(
                                gradient: Gradient(colors: [NordicElectricAI.accentBlue, NordicElectricAI.accentCyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .foregroundColor(message.role == .assistant ? NordicElectricAI.textPrimary : .white)
                    .cornerRadius(16)
                    .shadow(color: message.role == .assistant ? 
                            NordicElectricAI.accentBlue.opacity(0.2) : 
                            NordicElectricAI.accentCyan.opacity(0.2), 
                            radius: 5)
                
                Text(formattedTime(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(NordicElectricAI.textSecondary)
            }
            
            if message.role == .user {
                AvatarView(role: .user)
            } else {
                Spacer()
            }
        }
    }
    
    private func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AvatarView: View {
    let role: AIMessage.MessageRole
    
    var body: some View {
        Group {
            if role == .assistant {
                Image(systemName: "sparkles")
                    .foregroundColor(NordicElectricAI.accentCyan)
                    .nordicGlow(color: NordicElectricAI.accentCyan, intensity: 0.8)
            } else {
                Image(systemName: "person.circle")
                    .foregroundColor(NordicElectricAI.textPrimary)
            }
        }
        .font(.system(size: 16))
        .padding(8)
        .background(
            Circle()
                .fill(NordicElectricAI.surface)
                .shadow(color: role == .assistant ? 
                        NordicElectricAI.accentCyan.opacity(0.3) : 
                        NordicElectricAI.accentBlue.opacity(0.3), 
                        radius: 5)
        )
    }
}

struct AISettingsView: View {
    @EnvironmentObject private var appState: AuroraAppState
    @State private var selectedModel: AIModel = .local
    @State private var apiKey: String = ""
    @State private var customEndpoint: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Model")) {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(AIModel.allCases) { model in
                            Text(model.rawValue).tag(model)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if selectedModel == .openAI || selectedModel == .anthropic {
                    Section(header: Text("API Key")) {
                        SecureField("API Key", text: $apiKey)
                    }
                }
                
                if selectedModel == .custom {
                    Section(header: Text("Custom Endpoint")) {
                        TextField("API Endpoint URL", text: $customEndpoint)
                            .keyboardType(.URL)
                        
                        SecureField("API Key (if required)", text: $apiKey)
                    }
                }
                
                Section(header: Text("AI Features")) {
                    Toggle("Enable AI Page Analysis", isOn: $appState.isAIInjectionEnabled)
                }
                
                Section {
                    Button("Save Changes") {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(NordicElectricAI.accentBlue)
                }
            }
            .navigationTitle("AI Settings")
            .onAppear {
                // Load current settings
                selectedModel = appState.aiModel
                apiKey = appState.aiApiKey
                customEndpoint = appState.aiCustomEndpoint
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveSettings() {
        appState.aiModel = selectedModel
        appState.aiApiKey = apiKey
        appState.aiCustomEndpoint = customEndpoint
        
        // Reconfigure AI service
        appState.initializeAIService()
        
        appState.showAISettings = false
    }
}
