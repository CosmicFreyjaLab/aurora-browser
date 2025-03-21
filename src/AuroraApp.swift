import SwiftUI

@main
struct AuroraApp: App {
    @StateObject private var appState = AuroraAppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AuroraAIPageContent"))) { notification in
                    handleAIPageContentNotification(notification)
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            // Browser commands
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    appState.createNewTab()
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Button("New Window") {
                    // TODO: Implement new window
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            // Navigation commands
            CommandGroup(after: .sidebar) {
                Button("Back") {
                    // TODO: Implement back navigation
                }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(!canGoBack)
                
                Button("Forward") {
                    // TODO: Implement forward navigation
                }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(!canGoForward)
                
                Button("Reload") {
                    // TODO: Implement reload
                }
                .keyboardShortcut("r", modifiers: .command)
            }
            
            // Aurora AI commands
            CommandGroup(after: .help) {
                Button("Toggle AI Copilot") {
                    appState.toggleAICopilot()
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                
                Button("Toggle Terminal") {
                    appState.toggleTerminal()
                }
                .keyboardShortcut("`", modifiers: .command)
                
                Divider()
                
                Button("About Aurora") {
                    showAboutDialog()
                }
            }
        }
    }
    
    private var canGoBack: Bool {
        guard let currentTab = appState.currentTab else { return false }
        return currentTab.webView?.canGoBack ?? false
    }
    
    private var canGoForward: Bool {
        guard let currentTab = appState.currentTab else { return false }
        return currentTab.webView?.canGoForward ?? false
    }
    
    private func setupApp() {
        // Initialize backend connection
        appState.backendConnection.checkConnection()
        
        // Create welcome tab if no tabs exist
        if appState.tabs.isEmpty {
            appState.createNewTab(withURL: URL(string: "https://www.google.com")!)
        }
        
        // Set up AI service
        appState.initializeAIService()
        
        // Register for system notifications
        registerForNotifications()
    }
    
    private func registerForNotifications() {
        // App lifecycle notifications
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Save state before termination
            saveAppState()
        }
    }
    
    private func saveAppState() {
        // TODO: Implement state saving
    }
    
    private func handleAIPageContentNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let content = userInfo["content"] as? String,
              let url = userInfo["url"] as? URL else {
            return
        }
        
        // Set AI context
        appState.setAIContext(content: content, url: url)
        
        // Show AI copilot if not visible
        if !appState.isAICopilotVisible {
            appState.toggleAICopilot()
        }
        
        // Add AI message
        let aiMessage = AIMessage(
            role: .assistant,
            content: "I've analyzed the page at \(url.host ?? url.absoluteString). What would you like to know about it?"
        )
        appState.aiMessages.append(aiMessage)
    }
    
    private func showAboutDialog() {
        // TODO: Implement about dialog
        let aiMessage = AIMessage(
            role: .assistant,
            content: "Aurora Browser v0.1\nAn AI-powered WebKit browser with Nordic Electric AI aesthetics."
        )
        appState.aiMessages.append(aiMessage)
        
        if !appState.isAICopilotVisible {
            appState.toggleAICopilot()
        }
    }
}

// Hide the title bar
struct HiddenTitleBarWindowStyle: WindowStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .frame(minWidth: 800, minHeight: 600)
    }
}
