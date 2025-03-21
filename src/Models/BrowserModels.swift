import SwiftUI
import WebKit

// Main browser tab model
struct BrowserTab: Identifiable {
    let id: UUID
    var url: URL
    var title: String
    var isLoading: Bool
    var favicon: Image?
    var historyItems: [URL] = []
    var webView: WKWebView?
    
    init(id: UUID = UUID(), url: URL, title: String = "New Tab", isLoading: Bool = true, favicon: Image? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.isLoading = isLoading
        self.favicon = favicon
        
        // Create WebView
        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: .zero, configuration: configuration)
    }
}

// AI model configuration
enum AIModel: String, CaseIterable, Identifiable {
    case local = "Local LLaMA"
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case custom = "Custom"
    
    var id: String { self.rawValue }
    
    static var defaultModel: AIModel {
        return .local
    }
    
    var apiEndpoint: URL? {
        switch self {
        case .local:
            return URL(string: "http://localhost:8000/v1")
        case .openAI:
            return URL(string: "https://api.openai.com/v1")
        case .anthropic:
            return URL(string: "https://api.anthropic.com/v1")
        case .custom:
            return nil // Set by user
        }
    }
}

// AI message model
struct AIMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
    
    enum MessageRole: String {
        case user
        case assistant
        case system
    }
}

// Terminal command model
struct TerminalCommand: Identifiable {
    let id = UUID()
    let command: String
    let output: String
    let timestamp = Date()
    let exitCode: Int
    
    var isSuccess: Bool {
        return exitCode == 0
    }
}

// Browser settings model
struct BrowserSettings: Codable {
    var defaultSearchEngine: SearchEngine = .google
    var aiModel: String = AIModel.local.rawValue
    var aiApiKey: String = ""
    var aiCustomEndpoint: String = ""
    var terminalEnabled: Bool = true
    var aiCopilotEnabled: Bool = true
    var nordicThemeIntensity: Double = 1.0
    var privacyMode: PrivacyMode = .standard
    
    enum SearchEngine: String, CaseIterable, Codable {
        case google = "Google"
        case duckDuckGo = "DuckDuckGo"
        case bing = "Bing"
        case custom = "Custom"
    }
    
    enum PrivacyMode: String, CaseIterable, Codable {
        case standard = "Standard"
        case strict = "Strict"
        case custom = "Custom"
    }
}

// Browser history item
struct HistoryItem: Identifiable, Codable {
    let id = UUID()
    let url: String
    let title: String
    let visitDate: Date
    var favicon: Data?
    
    enum CodingKeys: String, CodingKey {
        case id, url, title, visitDate, favicon
    }
}

// Bookmark model
struct Bookmark: Identifiable, Codable {
    let id = UUID()
    let url: String
    let title: String
    let creationDate: Date
    var favicon: Data?
    var folder: String?
    
    enum CodingKeys: String, CodingKey {
        case id, url, title, creationDate, favicon, folder
    }
}

// AI suggestion model
struct AISuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let content: String
    let context: String
    let confidence: Double // 0.0 to 1.0
    
    enum SuggestionType {
        case search
        case navigation
        case command
        case information
        case action
    }
}

// Self-evolution suggestion model
struct EvolutionSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let codeChanges: [CodeChange]
    let impact: ImpactAssessment
    let confidence: Double // 0.0 to 1.0
    
    struct CodeChange {
        let filePath: String
        let originalCode: String
        let suggestedCode: String
        let explanation: String
    }
    
    struct ImpactAssessment {
        let performance: Double // -1.0 to 1.0
        let security: Double // -1.0 to 1.0
        let userExperience: Double // -1.0 to 1.0
        let notes: String
    }
}
