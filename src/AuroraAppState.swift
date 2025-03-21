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
    @Published var aiService = AIService()
    @Published var terminalService = TerminalService()
    @Published var backendConnection = BackendConnection()
    
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
        
        // Connect AI service to backend
        aiService.setBackendConnection(backendConnection)
        
        // Initialize AI service
        initializeAIService()
        
        // Add welcome message
        aiMessages.append(AIMessage(
            role: .assistant,
            content: "Hello! I'm Aurora, your AI browser assistant. How can I help you today?"
        ))
        
        // Monitor backend connection status
        backendConnection.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                if connected {
                    print("Connected to LLaMA backend")
                    self?.aiMessages.append(AIMessage(
                        role: .assistant,
                        content: "I've successfully connected to the LLaMA backend server."
                    ))
                } else {
                    print("Not connected to LLaMA backend")
                }
            }
            .store(in: &cancellables)
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
    
    func initializeAIService() {
        // Configure AI service with default settings
        aiService.configure(
            endpoint: aiModel.apiEndpoint,
            apiKey: aiApiKey,
            model: "llama-2-7b-chat" // Default model
        )
    }
    
    func setAIContext(content: String, url: URL) {
        currentAIContext = AIContext(content: content, url: url)
    }
    
    func clearAIContext() {
        currentAIContext = nil
    }
    
    func requestAISuggestions() {
        guard let currentTab = currentTab else { return }
        
        // Extract page content
        currentTab.webView?.extractPageContent { [weak self] content in
            guard let self = self, let content = content else { return }
            
            // Set context
            self.setAIContext(content: content, url: currentTab.url)
            
            // Show AI copilot
            if !self.isAICopilotVisible {
                self.toggleAICopilot()
            }
            
            // Generate suggestions
            self.aiService.generateResponse(
                prompt: "Based on this page, what might be helpful for me to know?",
                context: content
            ) { result in
                switch result {
                case .success(let response):
                    let aiMessage = AIMessage(role: .assistant, content: response)
                    self.aiMessages.append(aiMessage)
                    
                case .failure(let error):
                    let errorMessage = AIMessage(
                        role: .assistant,
                        content: "Sorry, I couldn't generate suggestions: \(error.localizedDescription)"
                    )
                    self.aiMessages.append(errorMessage)
                }
            }
        }
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
    
    func initializeAIService() {
        // Configure AI service with default settings
        aiService.configure(
            endpoint: aiModel.apiEndpoint,
            apiKey: aiApiKey,
            model: "llama-2-7b-chat" // Default model
        )
    }
    
    func setAIContext(content: String, url: URL) {
        currentAIContext = AIContext(content: content, url: url)
    }
    
    func clearAIContext() {
        currentAIContext = nil
    }
    
    func requestAISuggestions() {
        guard let currentTab = currentTab else { return }
        
        // Extract page content
        currentTab.webView?.extractPageContent { [weak self] content in
            guard let self = self, let content = content else { return }
            
            // Set context
            self.setAIContext(content: content, url: currentTab.url)
            
            // Show AI copilot
            if !self.isAICopilotVisible {
                self.toggleAICopilot()
            }
            
            // Generate suggestions
            self.aiService.generateResponse(
                prompt: "Based on this page, what might be helpful for me to know?",
                context: content
            ) { result in
                switch result {
                case .success(let response):
                    let aiMessage = AIMessage(role: .assistant, content: response)
                    self.aiMessages.append(aiMessage)
                    
                case .failure(let error):
                    let errorMessage = AIMessage(
                        role: .assistant,
                        content: "Sorry, I couldn't generate suggestions: \(error.localizedDescription)"
                    )
                    self.aiMessages.append(errorMessage)
                }
            }
        }
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
