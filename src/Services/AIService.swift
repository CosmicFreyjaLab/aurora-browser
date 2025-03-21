import Foundation
import Combine

class AIService: ObservableObject {
    private var apiKey: String = ""
    private var apiEndpoint: URL?
    private var model: String = "llama-2-7b-chat"
    private var backendConnection: BackendConnection?
    
    @Published var isProcessing: Bool = false
    @Published var lastError: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(apiEndpoint: URL? = URL(string: "http://localhost:8000/v1"), apiKey: String = "") {
        self.apiEndpoint = apiEndpoint
        self.apiKey = apiKey
    }
    
    func configure(endpoint: URL?, apiKey: String, model: String) {
        self.apiEndpoint = endpoint
        self.apiKey = apiKey
        self.model = model
    }
    
    func setBackendConnection(_ connection: BackendConnection) {
        self.backendConnection = connection
    }
    
    func generateResponse(prompt: String, context: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        // If we have a backend connection, use it
        if let backendConnection = backendConnection, backendConnection.isConnected {
            generateResponseWithBackend(prompt: prompt, context: context, completion: completion)
            return
        }
        
        // Otherwise use the direct API endpoint
        generateResponseWithDirectAPI(prompt: prompt, context: context, completion: completion)
    }
    
    private func generateResponseWithBackend(prompt: String, context: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        guard let backendConnection = backendConnection else {
            completion(.failure(AIServiceError.noEndpointConfigured))
            return
        }
        
        isProcessing = true
        lastError = nil
        
        // Prepare messages
        var messages: [ChatMessage] = []
        
        // Add system message with context if available
        if let context = context {
            messages.append(ChatMessage(
                role: .system,
                content: "You are Aurora, an AI assistant integrated into a web browser. Use the following context from the current webpage to answer the user's question: \(context)"
            ))
        } else {
            messages.append(ChatMessage(
                role: .system,
                content: "You are Aurora, an AI assistant integrated into a web browser. Be helpful, concise, and accurate."
            ))
        }
        
        // Add user message
        messages.append(ChatMessage(
            role: .user,
            content: prompt
        ))
        
        // Send to backend
        backendConnection.generateChatCompletion(messages: messages) { [weak self] result in
            self?.isProcessing = false
            
            switch result {
            case .success(let response):
                completion(.success(response))
                
            case .failure(let error):
                self?.lastError = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
    
    private func generateResponseWithDirectAPI(prompt: String, context: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiEndpoint = apiEndpoint else {
            completion(.failure(AIServiceError.noEndpointConfigured))
            return
        }
        
        isProcessing = true
        lastError = nil
        
        // Prepare system message with context if available
        let systemMessage: [String: String] = [
            "role": "system",
            "content": context != nil ? 
                "You are Aurora, an AI assistant integrated into a web browser. Use the following context from the current webpage to answer the user's question: \(context!)" :
                "You are Aurora, an AI assistant integrated into a web browser. Be helpful, concise, and accurate."
        ]
        
        // Prepare user message
        let userMessage: [String: String] = [
            "role": "user",
            "content": prompt
        ]
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [systemMessage, userMessage],
            "temperature": 0.7,
            "max_tokens": 512
        ]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(AIServiceError.invalidRequestData))
            isProcessing = false
            return
        }
        
        // Create URL for chat completions endpoint
        let chatEndpoint = apiEndpoint.appendingPathComponent("chat/completions")
        
        var request = URLRequest(url: chatEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add API key if available
        if !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Make the request
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: ChatCompletionResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isProcessing = false
                
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self?.lastError = error.localizedDescription
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                if let choice = response.choices.first,
                   let content = choice.message["content"] {
                    completion(.success(content))
                } else {
                    completion(.failure(AIServiceError.noResponseContent))
                }
            })
            .store(in: &cancellables)
    }
    
    func generateEmbedding(text: String, completion: @escaping (Result<[Float], Error>) -> Void) {
        // If we have a backend connection, use it
        if let backendConnection = backendConnection, backendConnection.isConnected {
            generateEmbeddingWithBackend(text: text, completion: completion)
            return
        }
        
        // Otherwise use the direct API endpoint
        generateEmbeddingWithDirectAPI(text: text, completion: completion)
    }
    
    private func generateEmbeddingWithBackend(text: String, completion: @escaping (Result<[Float], Error>) -> Void) {
        guard let backendConnection = backendConnection else {
            completion(.failure(AIServiceError.noEndpointConfigured))
            return
        }
        
        isProcessing = true
        lastError = nil
        
        backendConnection.generateEmbedding(text: text) { [weak self] result in
            self?.isProcessing = false
            completion(result)
        }
    }
    
    private func generateEmbeddingWithDirectAPI(text: String, completion: @escaping (Result<[Float], Error>) -> Void) {
        guard let apiEndpoint = apiEndpoint else {
            completion(.failure(AIServiceError.noEndpointConfigured))
            return
        }
        
        isProcessing = true
        lastError = nil
        
        // Prepare request body
        let requestBody: [String: Any] = [
            "model": model,
            "input": text
        ]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(AIServiceError.invalidRequestData))
            isProcessing = false
            return
        }
        
        // Create URL for embeddings endpoint
        let embeddingsEndpoint = apiEndpoint.appendingPathComponent("embeddings")
        
        var request = URLRequest(url: embeddingsEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add API key if available
        if !apiKey.isEmpty {
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Make the request
        URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: EmbeddingResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isProcessing = false
                
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self?.lastError = error.localizedDescription
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                if let embedding = response.data.first?.embedding {
                    completion(.success(embedding))
                } else {
                    completion(.failure(AIServiceError.noEmbeddingData))
                }
            })
            .store(in: &cancellables)
    }
    
    func analyzeWebpage(htmlContent: String, url: URL, completion: @escaping (Result<WebpageAnalysis, Error>) -> Void) {
        // Create a prompt for webpage analysis
        let prompt = """
        Analyze the following webpage content from \(url.absoluteString):
        
        \(htmlContent.prefix(5000))
        
        Provide a concise summary, main topics, and key information.
        """
        
        generateResponse(prompt: prompt) { result in
            switch result {
            case .success(let response):
                // Parse the response into a structured analysis
                let analysis = WebpageAnalysis(
                    url: url,
                    summary: response,
                    mainTopics: [], // Would need more sophisticated parsing
                    sentiment: .neutral // Would need sentiment analysis
                )
                completion(.success(analysis))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func cancelRequest() {
        // Cancel any ongoing requests
        cancellables.forEach { $0.cancel() }
        isProcessing = false
    }
}

// Response models for API
struct ChatCompletionResponse: Decodable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let usage: Usage
    
    struct Choice: Decodable {
        let index: Int
        let message: [String: String]
        let finishReason: String
        
        enum CodingKeys: String, CodingKey {
            case index, message
            case finishReason = "finish_reason"
        }
    }
    
    struct Usage: Decodable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

struct EmbeddingResponse: Decodable {
    let object: String
    let data: [EmbeddingData]
    let model: String
    let usage: EmbeddingUsage
    
    struct EmbeddingData: Decodable {
        let object: String
        let embedding: [Float]
        let index: Int
    }
    
    struct EmbeddingUsage: Decodable {
        let promptTokens: Int
        let totalTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

// Webpage analysis model
struct WebpageAnalysis {
    let url: URL
    let summary: String
    let mainTopics: [String]
    let sentiment: Sentiment
    
    enum Sentiment {
        case positive
        case neutral
        case negative
    }
}

// Error types
enum AIServiceError: Error, LocalizedError {
    case noEndpointConfigured
    case invalidRequestData
    case noResponseContent
    case noEmbeddingData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .noEndpointConfigured:
            return "No AI API endpoint configured"
        case .invalidRequestData:
            return "Failed to create request data"
        case .noResponseContent:
            return "No content in AI response"
        case .noEmbeddingData:
            return "No embedding data in response"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
