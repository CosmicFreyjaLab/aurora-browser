import SwiftUI

struct StatusBarView: View {
    @EnvironmentObject private var appState: AuroraAppState
    
    var body: some View {
        HStack {
            // Left side - browser info
            HStack(spacing: 8) {
                Text("Aurora")
                    .font(.caption)
                    .foregroundColor(NordicElectricAI.textSecondary)
                
                if let currentTab = currentTab, currentTab.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NordicElectricAI.accentBlue))
                        .scaleEffect(0.5)
                }
            }
            
            Spacer()
            
            // Center - current URL
            if let currentTab = currentTab {
                Text(currentTab.url.host ?? currentTab.url.absoluteString)
                    .font(.caption)
                    .foregroundColor(NordicElectricAI.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Right side - AI status
            HStack(spacing: 8) {
                // Backend connection status
                Circle()
                    .fill(appState.backendConnection.isConnected ? 
                          NordicElectricAI.successTeal : 
                          NordicElectricAI.errorRed)
                    .frame(width: 6, height: 6)
                
                Text("AI: \(appState.aiModel.rawValue)")
                    .font(.caption)
                    .foregroundColor(NordicElectricAI.textSecondary)
                
                // AI processing indicator
                if appState.aiService.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: NordicElectricAI.accentCyan))
                        .scaleEffect(0.5)
                }
            }
        }
        .padding(.horizontal)
        .frame(height: 24)
        .background(NordicElectricAI.backgroundDeep)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(NordicElectricAI.accentBlue.opacity(0.3)),
            alignment: .top
        )
    }
    
    private var currentTab: BrowserTab? {
        guard appState.tabs.indices.contains(appState.activeTabIndex) else { return nil }
        return appState.tabs[appState.activeTabIndex]
    }
}

struct StatusBarView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarView()
            .environmentObject(AuroraAppState())
            .preferredColorScheme(.dark)
    }
}
