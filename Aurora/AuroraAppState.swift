import SwiftUI
import WebKit
import Combine

class AuroraAppState: ObservableObject {
    // Tab management
    @Published var tabs: [BrowserTab] = []
    @Published var activeTabIndex: Int = 0
    
    // UI state
    @Published var isTerminalVisible: Bool = false
    @Published var isAICopilotVisible: Bool = false
    @Published var showSettings: Bool = false
    @Published var showTerminalSettings: Bool = false
    @Published var showAISettings: Bool = false
    
    // Services
    @Published var aiService = AIService.shared
    @Published var terminalService = TerminalService.shared
    @Published var backendConnection = BackendIntegration.shared
    
    // AI state
    @Published var aiModel: AIModel = .local
    @Published var aiApiKey: String = ""
    @Published var aiCustomEndpoint: String = ""
    @Published var aiMessages: [AIMessage] = []
    @Published var currentAIContext: AIContext?
    @Published var isAIInjectionEnabled: Bool = true
    
    // History and bookmarks
    @Published var history: [HistoryItem] = []
    @Published var bookmarks: [Bookmark] = []
    
    // Settings
    @Published var settings = BrowserSettings()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Create initial tab
        createNewTab()
        
        // Add welcome message
        aiMessages.append(AIMessage(
            role: .assistant,
            content: "Hello! I'm Aurora, your AI browser assistant. How can I help you today?"
        ))
    }
    
    // MARK: - Tab Management
    
    func createNewTab(withURL url: URL? = nil) {
        let newTab = BrowserTab(
            id: UUID(),
            url: url ?? URL(string: "https://www.google.com")!,
            title: "New Tab",
            isLoading: true
        )
        
        tabs.append(newTab)
        activeTabIndex = tabs.count - 1
    }
    
    func closeTab(at index: Int) {
        guard tabs.count > 1 else { return } // Don't close the last tab
        
        tabs.remove(at: index)
        
        // Adjust active tab index if needed
        if activeTabIndex >= tabs.count {
            activeTabIndex = tabs.count - 1
        }
    }
    
    // MARK: - UI Controls
    
    func toggleTerminal() {
        isTerminalVisible.toggle()
    }
    
    func toggleAICopilot() {
        isAICopilotVisible.toggle()
    }
    
    func openHelpPage() {
        createNewTab(withURL: URL(string: "https://aurora-browser.app/help")!)
    }
    
    // MARK: - AI Functions
    
    func setAIContext(content: String, url: URL) {
        currentAIContext = AIContext(content: content, url: url)
    }
    
    func clearAIContext() {
        currentAIContext = nil
    }
    
    // MARK: - History Management
    
    func addToHistory(url: URL, title: String) {
        let newItem = HistoryItem(
            url: url.absoluteString,
            title: title,
            visitDate: Date()
        )
        
        history.append(newItem)
        
        // Limit history size
        if history.count > 1000 {
            history.removeFirst()
        }
    }
    
    func clearHistory() {
        history.removeAll()
    }
    
    // MARK: - Bookmark Management
    
    func addBookmark(url: URL, title: String) {
        let newBookmark = Bookmark(
            url: url.absoluteString,
            title: title,
            creationDate: Date()
        )
        
        bookmarks.append(newBookmark)
    }
    
    func removeBookmark(at index: Int) {
        bookmarks.remove(at: index)
    }
    
    // MARK: - Helpers
    
    var currentTab: BrowserTab? {
        guard tabs.indices.contains(activeTabIndex) else { return nil }
        return tabs[activeTabIndex]
    }
}

// AI context model
struct AIContext {
    let content: String
    let url: URL
    let timestamp = Date()
}

// AI message model
struct AIMessage: Identifiable {
    let id = UUID()
    let role: AIRole
    let content: String
    let timestamp = Date()
    
    enum AIRole {
        case user
        case assistant
    }
}

// AI model
enum AIModel {
    case local
    case openAI
    case custom
    
    var apiEndpoint: String {
        switch self {
        case .local:
            return "http://localhost:8000"
        case .openAI:
            return "https://api.openai.com/v1"
        case .custom:
            return ""
        }
    }
}

// Browser settings
struct BrowserSettings {
    var defaultSearchEngine = "Google"
    var enableJavaScript = true
    var blockTrackers = true
    var enableCookies = true
    var clearHistoryOnExit = false
}

// History item
struct HistoryItem: Identifiable {
    let id = UUID()
    let url: String
    let title: String
    let visitDate: Date
}

// Bookmark
struct Bookmark: Identifiable {
    let id = UUID()
    let url: String
    let title: String
    let creationDate: Date
}
