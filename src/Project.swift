import Foundation

/// Project information for Aurora Browser
struct Project {
    static let name = "Aurora"
    static let version = "0.1.0"
    static let buildNumber = "1"
    static let copyright = "© 2025 Aurora Browser"
    static let website = "https://aurora-browser.app"
    static let repositoryURL = "https://github.com/yourusername/aurora-browser"
    
    /// Feature flags for enabling/disabling features
    struct Features {
        static let terminalEnabled = true
        static let aiCopilotEnabled = true
        static let selfEvolutionEnabled = true
        static let webkitModificationsEnabled = true
        static let nordicElectricAIEnabled = true
    }
    
    /// Build configuration
    struct Build {
        static let debug = true
        static let optimizationLevel = "O2"
        static let targetPlatform = "macOS"
        static let minimumOSVersion = "12.0"
        static let swiftVersion = "5.7"
    }
    
    /// Default settings
    struct Defaults {
        static let homePage = "https://www.google.com"
        static let searchEngine = "https://www.google.com/search?q="
        static let aiModel = "llama-2-7b-chat"
        static let terminalSecurityLevel = "medium"
        static let theme = "nordic-electric"
    }
    
    /// Integration points
    struct Integration {
        static let backendURL = "http://localhost:8000"
        static let openAICompatibleEndpoint = "http://localhost:8000/v1"
        static let webkitSourcePath = "/Users/dima/Development/WebKit"
    }
    
    /// Self-evolution configuration
    struct SelfEvolution {
        static let enabled = true
        static let maxChangesPerSession = 5
        static let requireApproval = true
        static let autoBackup = true
        static let learningRate = 0.1
    }
    
    /// Returns a dictionary of all project information
    static func info() -> [String: Any] {
        return [
            "name": name,
            "version": version,
            "buildNumber": buildNumber,
            "copyright": copyright,
            "website": website,
            "repositoryURL": repositoryURL,
            "features": [
                "terminalEnabled": Features.terminalEnabled,
                "aiCopilotEnabled": Features.aiCopilotEnabled,
                "selfEvolutionEnabled": Features.selfEvolutionEnabled,
                "webkitModificationsEnabled": Features.webkitModificationsEnabled,
                "nordicElectricAIEnabled": Features.nordicElectricAIEnabled
            ],
            "build": [
                "debug": Build.debug,
                "optimizationLevel": Build.optimizationLevel,
                "targetPlatform": Build.targetPlatform,
                "minimumOSVersion": Build.minimumOSVersion,
                "swiftVersion": Build.swiftVersion
            ],
            "defaults": [
                "homePage": Defaults.homePage,
                "searchEngine": Defaults.searchEngine,
                "aiModel": Defaults.aiModel,
                "terminalSecurityLevel": Defaults.terminalSecurityLevel,
                "theme": Defaults.theme
            ],
            "integration": [
                "backendURL": Integration.backendURL,
                "openAICompatibleEndpoint": Integration.openAICompatibleEndpoint,
                "webkitSourcePath": Integration.webkitSourcePath
            ],
            "selfEvolution": [
                "enabled": SelfEvolution.enabled,
                "maxChangesPerSession": SelfEvolution.maxChangesPerSession,
                "requireApproval": SelfEvolution.requireApproval,
                "autoBackup": SelfEvolution.autoBackup,
                "learningRate": SelfEvolution.learningRate
            ]
        ]
    }
}
