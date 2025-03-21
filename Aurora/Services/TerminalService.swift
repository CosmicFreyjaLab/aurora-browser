import Foundation
import SwiftUI

class TerminalService: ObservableObject {
    static let shared = TerminalService()
    
    @Published var commandHistory: [String] = []
    @Published var outputHistory: [String] = []
    @Published var isProcessing = false
    
    private let backendConnection = BackendConnection(baseURL: "http://localhost:8000")
    
    func executeCommand(_ command: String) {
        guard !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        commandHistory.append(command)
        isProcessing = true
        
        Task {
            do {
                let output = try await backendConnection.executeCommand(command: command)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.outputHistory.append(output)
                    self.isProcessing = false
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.outputHistory.append("Error: \(error.localizedDescription)")
                    self.isProcessing = false
                }
            }
        }
    }
}
