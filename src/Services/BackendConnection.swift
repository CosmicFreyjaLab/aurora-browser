import Foundation
import Combine

/// Service for connecting to the LLaMA backend
class BackendConnection: ObservableObject {
    // Backend API endpoint
    private let backendURL: URL
    
    // Published properties
    @Published var isConnected: Bool = false
    @Published var lastError: String?
    @Published var modelInfo: ModelInfo?
    
    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    // Initialize with the backend URL
    init(backendURL: URL = URL(string: "http://localhost:8000")!) {
        self.backendURL = backendURL
        checkConnection()
    }
    
    // MARK: - Connection Management
    
    /// Check if the backend is available
    func checkConnection() {
        let healthURL = backendURL.appendingPathComponent("/")
        
        URLSession.shared.dataTaskPublisher(for: healthURL)
            .map { data, response -> Bool in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return false
                }
                return httpResponse.statusCode == 200
            }
            .replaceError(with: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
                if connected {
                    self?.fetchModelInfo()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Fetch information about the loaded model
    func fetchModelInfo() {
        let modelInfoURL = backendURL.appendingPathComponent("v1/models")
        
        URLSession.shared.dataTaskPublisher(for: modelInfoURL)
            .map(\.data)
            .decode(type: ModelsResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.lastError = error.localizedDescription
                }
            }, receiveValue: { [weak self] response in
                if let model = response.data.first {
                    self?.modelInfo = ModelInfo(
                        id: model.id,
                        name: model.id,
                        parameters: "Unknown",
                        quantization: "Unknown",
                        contextLength: 2048
                    )
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Chat Completions
    
    /// Generate a chat completion
    func generateChatCompletion(messages: [ChatMessage], completion: @escaping (Result<String, Error>) -> Void) {
        let chatEndpoint = backendURL.appendingPathComponent("v1/chat/completions")
        
        // Convert messages to API format
        let apiMessages = messages.map { message -> [String: String] in
            return [
                "role": message.role.rawValue,
                "content": message.content
            ]
        }
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": modelInfo?.id ?? "llama-2-7b-chat",
            "messages": apiMessages,
            "temperature": 0.7,
            "max_tokens": 512
        ]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(BackendError.invalidRequestData))
            return
        }
        
        // Create request
        var request = URLRequest(url: chatEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send request
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: ChatCompletionResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                if let choice = response.choices.first,
                   let content = choice.message["content"] {
                    completion(.success(content))
                } else {
                    completion(.failure(BackendError.noResponseContent))
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Embeddings
    
    /// Generate embeddings for text
    func generateEmbedding(text: String, completion: @escaping (Result<[Float], Error>) -> Void) {
        let embeddingsEndpoint = backendURL.appendingPathComponent("v1/embeddings")
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": modelInfo?.id ?? "llama-2-7b-chat",
            "input": text
        ]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(BackendError.invalidRequestData))
            return
        }
        
        // Create request
        var request = URLRequest(url: embeddingsEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send request
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: EmbeddingResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                if let embedding = response.data.first?.embedding {
                    completion(.success(embedding))
                } else {
                    completion(.failure(BackendError.noEmbeddingData))
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Search API
    
    /// Search using the backend's search API
    func search(query: String, limit: Int = 5, completion: @escaping (Result<SearchResponse, Error>) -> Void) {
        let searchEndpoint = backendURL.appendingPathComponent("api/search")
        
        // Create request body
        let requestBody: [String: Any] = [
            "query": query,
            "limit": limit
        ]
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(BackendError.invalidRequestData))
            return
        }
        
        // Create request
        var request = URLRequest(url: searchEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send request
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: SearchResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }, receiveValue: { response in
                completion(.success(response))
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Index API
    
    /// Index a document in the backend
    func indexDocument(content: String, metadata: [String: Any]? = nil, completion: @escaping (Result<Bool, Error>) -> Void) {
        let indexEndpoint = backendURL.appendingPathComponent("api/index")
        
        // Create request body
        var requestBody: [String: Any] = [
            "content": content
        ]
        
        if let metadata = metadata {
            requestBody["metadata"] = metadata
        }
        
        guard let requestData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(BackendError.invalidRequestData))
            return
        }
        
        // Create request
        var request = URLRequest(url: indexEndpoint)
        request.httpMethod = "POST"
        request.httpBody = requestData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Send request
        URLSession.shared.dataTaskPublisher(for: request)
            .map { data, response -> Bool in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return false
                }
                return httpResponse.statusCode == 200
            }
            .replaceError(with: false)
            .receive(on: DispatchQueue.main)
            .sink { success in
                completion(.success(success))
            }
            .store(in: &cancellables)
    }
}

// MARK: - Models

/// Chat message model
struct ChatMessage: Codable {
    let role: Role
    let content: String
    
    enum Role: String, Codable {
        case system
        case user
        case assistant
    }
}

/// Model information
struct ModelInfo {
    let id: String
    let name: String
    let parameters: String
    let quantization: String
    let contextLength: Int
}

// MARK: - API Response Models

struct ModelsResponse: Decodable {
    let object: String
    let data: [ModelData]
    
    struct ModelData: Decodable {
        let id: String
        let object: String
        let created: Int
        let ownedBy: String
        
        enum CodingKeys: String, CodingKey {
            case id, object, created
            case ownedBy = "owned_by"
        }
    }
}

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

struct SearchResponse: Decodable {
    let results: [SearchResult]
    let llmResponse: String
    let queryTimeMs: Double
    
    enum CodingKeys: String, CodingKey {
        case results
        case llmResponse = "llm_response"
        case queryTimeMs = "query_time_ms"
    }
    
    struct SearchResult: Decodable, Identifiable {
        let id: String
        let content: String
        let metadata: [String: String]?
        let score: Double
    }
}

// MARK: - Errors

enum BackendError: Error, LocalizedError {
    case invalidRequestData
    case noResponseContent
    case noEmbeddingData
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidRequestData:
            return "Failed to create request data"
        case .noResponseContent:
            return "No content in response"
        case .noEmbeddingData:
            return "No embedding data in response"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
