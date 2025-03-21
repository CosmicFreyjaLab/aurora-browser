import Foundation
import SwiftUI
import WebKit

class BackendIntegration: ObservableObject {
    static let shared = BackendIntegration()
    
    @Published var isConnected = false
    @Published var backendURL = "http://localhost:8000"
    
    private var backendConnection: BackendConnection?
    
    init() {
        self.backendConnection = BackendConnection(baseURL: backendURL)
        checkConnection()
    }
    
    func checkConnection() {
        Task {
            do {
                let isAlive = try await backendConnection?.checkHealth() ?? false
                DispatchQueue.main.async {
                    self.isConnected = isAlive
                }
            } catch {
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            }
        }
    }
    
    func sendPageContent(url: String, content: String) {
        Task {
            do {
                try await backendConnection?.sendPageContent(url: url, content: content)
            } catch {
                print("Error sending page content: \(error)")
            }
        }
    }
    
    func askAI(question: String, completion: @escaping (String) -> Void) {
        Task {
            do {
                let response = try await backendConnection?.askAI(question: question) ?? "No response from AI"
                DispatchQueue.main.async {
                    completion(response)
                }
            } catch {
                DispatchQueue.main.async {
                    completion("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
