import Foundation
import Combine

/// Service for integrating with the LLaMA backend and WebKit
class BackendIntegration: ObservableObject {
    // Dependencies
    private let backendConnection: BackendConnection
    private let aiService: AIService
    
    // Published properties
    @Published var isProcessing: Bool = false
    @Published var lastError: String?
    @Published var pageAnalysis: PageAnalysis?
    
    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    // Initialize with dependencies
    init(backendConnection: BackendConnection, aiService: AIService) {
        self.backendConnection = backendConnection
        self.aiService = aiService
        
        // Monitor backend connection status
        backendConnection.$isConnected
            .sink { [weak self] connected in
                if !connected {
                    self?.lastError = "Backend connection lost"
                }
            }
            .store(in: &cancellables)
        
        // Monitor AI service status
        aiService.$isProcessing
            .sink { [weak self] processing in
                self?.isProcessing = processing
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Page Analysis
    
    /// Analyze a webpage and generate insights
    func analyzePage(content: String, url: URL, completion: @escaping (Result<PageAnalysis, Error>) -> Void) {
        isProcessing = true
        
        // Create system prompt for page analysis
        let systemPrompt = """
        You are Aurora, an AI assistant integrated into a web browser. Analyze the following webpage content and provide:
        1. A concise summary (2-3 sentences)
        2. Key topics or entities mentioned
        3. Any actionable insights
        4. Potential follow-up questions the user might have
        
        Format your response as JSON with the following structure:
        {
            "summary": "Brief summary of the page",
            "topics": ["Topic 1", "Topic 2", "Topic 3"],
            "insights": ["Insight 1", "Insight 2"],
            "questions": ["Question 1?", "Question 2?"]
        }
        
        Webpage: \(url.absoluteString)
        """
        
        // Truncate content if too long
        let truncatedContent = content.count > 8000 ? String(content.prefix(8000)) + "..." : content
        
        // Create messages for chat completion
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: truncatedContent)
        ]
        
        // Send to backend
        backendConnection.generateChatCompletion(messages: messages) { [weak self] result in
            self?.isProcessing = false
            
            switch result {
            case .success(let jsonString):
                // Parse JSON response
                if let analysis = self?.parseAnalysisResponse(jsonString, url: url) {
                    self?.pageAnalysis = analysis
                    completion(.success(analysis))
                } else {
                    let error = BackendError.invalidResponseFormat
                    self?.lastError = error.localizedDescription
                    completion(.failure(error))
                }
                
            case .failure(let error):
                self?.lastError = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
    
    /// Parse JSON response from AI into PageAnalysis object
    private func parseAnalysisResponse(_ response: String, url: URL) -> PageAnalysis? {
        // Extract JSON from response (in case there's additional text)
        guard let jsonStart = response.firstIndex(of: "{"),
              let jsonEnd = response.lastIndex(of: "}") else {
            return nil
        }
        
        let jsonString = String(response[jsonStart...jsonEnd])
        
        // Parse JSON
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        // Extract fields
        let summary = json["summary"] as? String ?? "No summary available"
        let topics = json["topics"] as? [String] ?? []
        let insights = json["insights"] as? [String] ?? []
        let questions = json["questions"] as? [String] ?? []
        
        return PageAnalysis(
            url: url,
            summary: summary,
            topics: topics,
            insights: insights,
            suggestedQuestions: questions,
            timestamp: Date()
        )
    }
    
    // MARK: - Content Search
    
    /// Search for content using the vector store
    func searchContent(query: String, completion: @escaping (Result<SearchResponse, Error>) -> Void) {
        isProcessing = true
        
        backendConnection.search(query: query) { [weak self] result in
            self?.isProcessing = false
            completion(result)
        }
    }
    
    // MARK: - Content Indexing
    
    /// Index webpage content for future searches
    func indexWebpage(title: String, content: String, url: URL, completion: @escaping (Bool) -> Void) {
        isProcessing = true
        
        // Create metadata
        let metadata: [String: Any] = [
            "title": title,
            "url": url.absoluteString,
            "indexed_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        backendConnection.indexDocument(content: content, metadata: metadata) { [weak self] result in
            self?.isProcessing = false
            
            switch result {
            case .success(let success):
                completion(success)
            case .failure:
                completion(false)
            }
        }
    }
    
    // MARK: - Self-Evolution
    
    /// Generate code improvement suggestions
    func generateCodeImprovements(code: String, description: String, completion: @escaping (Result<CodeImprovement, Error>) -> Void) {
        isProcessing = true
        
        // Create system prompt for code improvement
        let systemPrompt = """
        You are Aurora, an AI assistant that can suggest improvements to browser code. Analyze the following code and provide:
        1. Improved version of the code
        2. Explanation of changes
        3. Impact assessment (performance, security, user experience)
        
        Format your response as JSON with the following structure:
        {
            "improvedCode": "// Your improved code here",
            "explanation": "Explanation of changes",
            "impact": {
                "performance": 0.5, // -1.0 to 1.0 scale
                "security": 0.2,    // -1.0 to 1.0 scale
                "userExperience": 0.8 // -1.0 to 1.0 scale
            }
        }
        """
        
        // Create messages for chat completion
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: "Code description: \(description)\n\nCode:\n```\n\(code)\n```")
        ]
        
        // Send to backend
        backendConnection.generateChatCompletion(messages: messages) { [weak self] result in
            self?.isProcessing = false
            
            switch result {
            case .success(let jsonString):
                // Parse JSON response
                if let improvement = self?.parseCodeImprovementResponse(jsonString, originalCode: code) {
                    completion(.success(improvement))
                } else {
                    let error = BackendError.invalidResponseFormat
                    self?.lastError = error.localizedDescription
                    completion(.failure(error))
                }
                
            case .failure(let error):
                self?.lastError = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
    
    /// Parse JSON response from AI into CodeImprovement object
    private func parseCodeImprovementResponse(_ response: String, originalCode: String) -> CodeImprovement? {
        // Extract JSON from response (in case there's additional text)
        guard let jsonStart = response.firstIndex(of: "{"),
              let jsonEnd = response.lastIndex(of: "}") else {
            return nil
        }
        
        let jsonString = String(response[jsonStart...jsonEnd])
        
        // Parse JSON
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        // Extract fields
        let improvedCode = json["improvedCode"] as? String ?? originalCode
        let explanation = json["explanation"] as? String ?? "No explanation provided"
        
        var performanceImpact: Double = 0
        var securityImpact: Double = 0
        var userExperienceImpact: Double = 0
        
        if let impact = json["impact"] as? [String: Any] {
            performanceImpact = impact["performance"] as? Double ?? 0
            securityImpact = impact["security"] as? Double ?? 0
            userExperienceImpact = impact["userExperience"] as? Double ?? 0
        }
        
        return CodeImprovement(
            originalCode: originalCode,
            improvedCode: improvedCode,
            explanation: explanation,
            performanceImpact: performanceImpact,
            securityImpact: securityImpact,
            userExperienceImpact: userExperienceImpact,
            timestamp: Date()
        )
    }
}

// MARK: - Models

/// Page analysis model
struct PageAnalysis {
    let url: URL
    let summary: String
    let topics: [String]
    let insights: [String]
    let suggestedQuestions: [String]
    let timestamp: Date
}

/// Code improvement model
struct CodeImprovement {
    let originalCode: String
    let improvedCode: String
    let explanation: String
    let performanceImpact: Double // -1.0 to 1.0
    let securityImpact: Double // -1.0 to 1.0
    let userExperienceImpact: Double // -1.0 to 1.0
    let timestamp: Date
    
    var overallImpact: Double {
        (performanceImpact + securityImpact + userExperienceImpact) / 3.0
    }
}
