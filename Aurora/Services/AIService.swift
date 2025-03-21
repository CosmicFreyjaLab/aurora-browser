import Foundation
import SwiftUI

class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isProcessing = false
    @Published var lastResponse = ""
    
    private let backendIntegration = BackendIntegration.shared
    
    func askQuestion(_ question: String) {
        guard !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isProcessing = true
        
        backendIntegration.askAI(question: question) { [weak self] response in
            guard let self = self else { return }
            
            self.lastResponse = response
            self.isProcessing = false
        }
    }
}
