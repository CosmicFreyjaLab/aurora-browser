import Foundation
import Combine

class TerminalService: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var commandHistory: [TerminalCommand] = []
    
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    // Security settings
    private var allowedCommands: Set<String> = [
        "ls", "cd", "pwd", "echo", "cat", "grep", "find",
        "mkdir", "touch", "rm", "cp", "mv", "curl", "wget",
        "python", "python3", "node", "npm", "git"
    ]
    
    private var disallowedCommands: Set<String> = [
        "sudo", "su", "rm -rf /", ":(){ :|:& };:"
    ]
    
    private var securityLevel: SecurityLevel = .medium
    
    enum SecurityLevel {
        case low    // Allow most commands
        case medium // Allow common commands
        case high   // Allow only safe commands
        case custom // Custom allowed/disallowed lists
    }
    
    func executeCommand(_ command: String, completion: @escaping (TerminalCommand) -> Void) {
        guard !isProcessing else { return }
        guard isCommandAllowed(command) else {
            let result = TerminalCommand(
                id: UUID(),
                command: command,
                output: "Error: Command not allowed for security reasons",
                exitCode: 1
            )
            commandHistory.append(result)
            completion(result)
            return
        }
        
        isProcessing = true
        
        // Create process
        process = Process()
        outputPipe = Pipe()
        errorPipe = Pipe()
        
        process?.standardOutput = outputPipe
        process?.standardError = errorPipe
        
        // Configure process to use shell
        process?.executableURL = URL(fileURLWithPath: "/bin/bash")
        process?.arguments = ["-c", command]
        
        var outputData = Data()
        var errorData = Data()
        
        // Set up output handling
        outputPipe?.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            outputData.append(data)
        }
        
        errorPipe?.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            errorData.append(data)
        }
        
        // Set up completion handler
        process?.terminationHandler = { [weak self] process in
            // Clean up
            self?.outputPipe?.fileHandleForReading.readabilityHandler = nil
            self?.errorPipe?.fileHandleForReading.readabilityHandler = nil
            
            // Get output
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            let combinedOutput = output + (error.isEmpty ? "" : "\nError: \(error)")
            
            // Create result
            let result = TerminalCommand(
                id: UUID(),
                command: command,
                output: combinedOutput,
                exitCode: Int(process.terminationStatus)
            )
            
            // Update state on main thread
            DispatchQueue.main.async {
                self?.isProcessing = false
                self?.commandHistory.append(result)
                completion(result)
            }
        }
        
        // Run the process
        do {
            try process?.run()
        } catch {
            isProcessing = false
            let result = TerminalCommand(
                id: UUID(),
                command: command,
                output: "Error: \(error.localizedDescription)",
                exitCode: 1
            )
            commandHistory.append(result)
            completion(result)
        }
    }
    
    func cancelCurrentCommand() {
        guard isProcessing, let process = process else { return }
        process.terminate()
    }
    
    func clearHistory() {
        commandHistory.removeAll()
    }
    
    func setSecurityLevel(_ level: SecurityLevel) {
        securityLevel = level
        
        // Update allowed commands based on security level
        switch level {
        case .low:
            // Allow most commands except explicitly disallowed ones
            allowedCommands = Set<String>()
        case .medium:
            // Default set of common commands
            break
        case .high:
            // Only allow very safe commands
            allowedCommands = Set([
                "ls", "pwd", "echo", "cat", "grep", "find"
            ])
        case .custom:
            // Keep current settings
            break
        }
    }
    
    func addAllowedCommand(_ command: String) {
        allowedCommands.insert(command)
    }
    
    func removeAllowedCommand(_ command: String) {
        allowedCommands.remove(command)
    }
    
    func addDisallowedCommand(_ command: String) {
        disallowedCommands.insert(command)
    }
    
    func removeDisallowedCommand(_ command: String) {
        disallowedCommands.remove(command)
    }
    
    private func isCommandAllowed(_ command: String) -> Bool {
        // Check for disallowed commands first
        for disallowed in disallowedCommands {
            if command.contains(disallowed) {
                return false
            }
        }
        
        // In low security mode, allow anything not explicitly disallowed
        if securityLevel == .low {
            return true
        }
        
        // In other modes, check against allowed commands
        let commandName = command.split(separator: " ").first.map(String.init) ?? ""
        return allowedCommands.contains(commandName)
    }
}
