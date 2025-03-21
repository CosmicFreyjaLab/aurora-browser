import Foundation

struct Project {
    static let name = "Aurora"
    static let version = "0.1.0"
    static let description = "An AI-powered WebKit browser"
    static let repository = "https://github.com/aurora-browser/aurora"
    static let license = "MIT"
    
    static let features = [
        "AI-powered browsing assistant",
        "Built-in terminal",
        "Privacy-focused design",
        "WebKit rendering engine",
        "Modern SwiftUI interface"
    ]
    
    static let credits = [
        "WebKit Team",
        "Swift Team",
        "LLaMA Team",
        "Open source contributors"
    ]
    
    static let buildDate = Date()
    static let buildNumber = "20250320.1"
    
    static var fullVersionString: String {
        return "\(name) \(version) (Build \(buildNumber))"
    }
}
