import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject var appState: AuroraAppState
    
    var body: some View {
        HStack {
            if let currentTab = appState.currentTab {
                if currentTab.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                }
                
                Text(currentTab.url.host ?? "")
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    appState.toggleTerminal()
                }) {
                    Image(systemName: "terminal")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(appState.isTerminalVisible ? .blue : .primary)
                
                Button(action: {
                    appState.toggleAICopilot()
                }) {
                    Image(systemName: "brain")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundColor(appState.isAICopilotVisible ? .blue : .primary)
                
                Button(action: {
                    // Request AI suggestions for current page
                }) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.windowBackgroundColor))
        .frame(height: 24)
    }
}
