import SwiftUI

struct TerminalView: View {
    @EnvironmentObject var appState: AuroraAppState
    @State private var commandInput: String = ""
    @State private var isProcessing: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Terminal")
                    .font(.headline)
                Spacer()
                Button(action: {
                    appState.toggleTerminal()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(zip(appState.terminalService.commandHistory.indices, appState.terminalService.commandHistory)), id: \.0) { index, command in
                        Text("$ \(command)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.bottom, 2)
                        
                        if index < appState.terminalService.outputHistory.count {
                            Text(appState.terminalService.outputHistory[index])
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black)
            
            Divider()
            
            HStack {
                Text("$")
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.green)
                
                TextField("Enter command", text: $commandInput, onCommit: executeCommand)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                
                Button(action: executeCommand) {
                    Image(systemName: isProcessing ? "hourglass" : "return")
                }
                .disabled(commandInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            }
            .padding()
            .background(Color.black)
            .foregroundColor(.white)
        }
        .frame(height: 300)
    }
    
    private func executeCommand() {
        guard !commandInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let command = commandInput
        commandInput = ""
        isProcessing = true
        
        appState.terminalService.executeCommand(command)
        
        // This would normally be handled by the TerminalService response
        // but for this demo we'll simulate a response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isProcessing = false
        }
    }
}
