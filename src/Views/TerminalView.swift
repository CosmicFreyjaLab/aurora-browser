import SwiftUI

struct TerminalView: View {
    @EnvironmentObject private var appState: AuroraAppState
    @State private var commandText: String = ""
    @State private var isScrollToBottom: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Terminal header
            HStack {
                Text("Terminal")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if appState.terminalService.isProcessing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color("AccentColor")))
                            .scaleEffect(0.7)
                        
                        Text("Running...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    appState.showTerminalSettings = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    appState.toggleTerminal()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color("TerminalHeaderColor"))
            
            // Terminal output
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        // Welcome message
                        Text("Aurora Terminal v1.0")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color("AccentColor"))
                        
                        Text("Type 'help' for available commands")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color("TerminalTextColor"))
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        // Command history
                        ForEach(appState.terminalService.commandHistory) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("$")
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(Color("AccentColor"))
                                    
                                    Text(item.command)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(Color("TerminalTextColor"))
                                }
                                
                                Text(item.output)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(item.isSuccess ? Color("TerminalTextColor") : Color.red)
                            }
                            .padding(.vertical, 4)
                            .id(item.id)
                        }
                    }
                    .padding()
                    .onChange(of: appState.terminalService.commandHistory.count) { _ in
                        if let lastCommand = appState.terminalService.commandHistory.last {
                            scrollView.scrollTo(lastCommand.id, anchor: .bottom)
                        }
                    }
                }
                .background(Color("TerminalBackgroundColor"))
            }
            
            // Command input
            HStack {
                Text("$")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(Color("AccentColor"))
                
                TextField("Enter command", text: $commandText, onCommit: executeCommand)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .disabled(appState.terminalService.isProcessing)
                
                Button(action: executeCommand) {
                    Image(systemName: appState.terminalService.isProcessing ? "stop.fill" : "return")
                        .foregroundColor(Color("AccentColor"))
                }
                .disabled(commandText.isEmpty && !appState.terminalService.isProcessing)
            }
            .padding()
            .background(Color("TerminalInputColor"))
        }
        .cornerRadius(16)
        .shadow(radius: 10)
        .sheet(isPresented: $appState.showTerminalSettings) {
            TerminalSettingsView()
        }
    }
    
    private func executeCommand() {
        guard !commandText.isEmpty else { return }
        
        if appState.terminalService.isProcessing {
            // Cancel current command
            appState.terminalService.cancelCurrentCommand()
            return
        }
        
        let command = commandText
        commandText = ""
        
        // Special commands
        if command == "clear" {
            appState.terminalService.clearHistory()
            return
        }
        
        if command == "help" {
            let helpOutput = """
            Available commands:
            - clear: Clear terminal history
            - help: Show this help message
            - exit: Close terminal
            
            System commands are also available based on security settings.
            """
            
            let helpCommand = TerminalCommand(
                id: UUID(),
                command: command,
                output: helpOutput,
                exitCode: 0
            )
            
            appState.terminalService.commandHistory.append(helpCommand)
            return
        }
        
        if command == "exit" {
            appState.toggleTerminal()
            return
        }
        
        // Execute system command
        appState.terminalService.executeCommand(command) { _ in
            // Command completed, handled by the service
        }
    }
}

struct TerminalSettingsView: View {
    @EnvironmentObject private var appState: AuroraAppState
    @State private var securityLevel: TerminalService.SecurityLevel = .medium
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Security Level")) {
                    Picker("Security", selection: $securityLevel) {
                        Text("Low").tag(TerminalService.SecurityLevel.low)
                        Text("Medium").tag(TerminalService.SecurityLevel.medium)
                        Text("High").tag(TerminalService.SecurityLevel.high)
                        Text("Custom").tag(TerminalService.SecurityLevel.custom)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Security Level Description")) {
                    switch securityLevel {
                    case .low:
                        Text("Low security allows most commands except explicitly dangerous ones.")
                            .foregroundColor(.red)
                    case .medium:
                        Text("Medium security allows common development and system commands.")
                            .foregroundColor(.orange)
                    case .high:
                        Text("High security allows only safe, read-only commands.")
                            .foregroundColor(.green)
                    case .custom:
                        Text("Custom security with user-defined allowed and disallowed commands.")
                            .foregroundColor(.blue)
                    }
                }
                
                if securityLevel == .custom {
                    Section(header: Text("Custom Command Settings")) {
                        NavigationLink("Configure Allowed Commands") {
                            Text("Command configuration not implemented in this demo")
                        }
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(Color("AccentColor"))
                }
            }
            .navigationTitle("Terminal Settings")
            .onAppear {
                // Load current settings
                securityLevel = appState.terminalService.securityLevel
            }
        }
    }
    
    private func saveSettings() {
        appState.terminalService.setSecurityLevel(securityLevel)
        appState.showTerminalSettings = false
    }
}
