import SwiftUI

@main
struct AuroraApp: App {
    @StateObject private var appState = AuroraAppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    // Start backend server if needed
                    startBackendServer()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    appState.createNewTab()
                }
                .keyboardShortcut("t", modifiers: .command)
                
                Button("Close Tab") {
                    if let currentTab = appState.currentTab {
                        if let index = appState.tabs.firstIndex(where: { $0.id == currentTab.id }) {
                            appState.closeTab(at: index)
                        }
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            
            CommandGroup(after: .sidebar) {
                Button("Toggle Terminal") {
                    appState.toggleTerminal()
                }
                .keyboardShortcut("`", modifiers: .command)
                
                Button("Toggle AI Copilot") {
                    appState.toggleAICopilot()
                }
                .keyboardShortcut("i", modifiers: .command)
            }
        }
    }
    
    private func startBackendServer() {
        // Check if backend server is running
        BackendIntegration.shared.checkConnection()
    }
}
