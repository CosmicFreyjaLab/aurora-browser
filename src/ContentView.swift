import SwiftUI
import WebKit

struct ContentView: View {
    @EnvironmentObject private var appState: AuroraAppState
    
    var body: some View {
        ZStack {
            // Main browser interface with Nordic Electric AI styling
            VStack(spacing: 0) {
                // Top navigation bar
                NavigationBarView()
                
                // Tab bar
                TabBarView()
                
                // Main content area with browser and terminal
                ZStack {
                    // Browser tabs
                    TabView(selection: $appState.activeTabIndex) {
                        ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                            BrowserTabView(tab: binding(for: index))
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Terminal panel (slides up from bottom when visible)
                    if appState.isTerminalVisible {
                        TerminalView()
                            .transition(.move(edge: .bottom))
                    }
                }
                
                // Status bar
                StatusBarView()
            }
            .background(NordicElectricAI.backgroundDeep)
            
            // AI Copilot panel (slides in from right when visible)
            if appState.isAICopilotVisible {
                HStack(spacing: 0) {
                    Spacer()
                    
                    AICopilotView()
                        .frame(width: 350)
                        .transition(.move(edge: .trailing))
                }
                .background(
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                appState.isAICopilotVisible = false
                            }
                        }
                )
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(), value: appState.isTerminalVisible)
        .animation(.spring(), value: appState.isAICopilotVisible)
    }
    
    // Helper function to get binding for a specific tab
    private func binding(for index: Int) -> Binding<BrowserTab> {
        return Binding(
            get: { self.appState.tabs[index] },
            set: { self.appState.tabs[index] = $0 }
        )
    }
}

struct NavigationBarView: View {
    @EnvironmentObject private var appState: AuroraAppState
    @State private var urlText: String = ""
    @State private var isEditing: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Navigation buttons with Nordic Electric AI styling
            HStack(spacing: 12) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(canGoBack ? NordicElectricAI.textPrimary : NordicElectricAI.textSecondary)
                        .frame(width: 16, height: 16)
                }
                .disabled(!canGoBack)
                .buttonStyle(NordicElectricAI.IconButtonStyle())
                
                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(canGoForward ? NordicElectricAI.textPrimary : NordicElectricAI.textSecondary)
                        .frame(width: 16, height: 16)
                }
                .disabled(!canGoForward)
                .buttonStyle(NordicElectricAI.IconButtonStyle())
                
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(NordicElectricAI.textPrimary)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(NordicElectricAI.IconButtonStyle())
            }
            .padding(.leading, 16)
            
            // URL/Search bar with Nordic Electric AI styling
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(NordicElectricAI.accentBlue)
                    .padding(.leading, 8)
                
                TextField("Search or enter URL", text: $urlText, onCommit: loadURL)
                    .foregroundColor(NordicElectricAI.textPrimary)
                    .onTapGesture {
                        isEditing = true
                    }
                
                if !urlText.isEmpty {
                    Button(action: { urlText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(NordicElectricAI.textSecondary)
                    }
                    .padding(.trailing, 8)
                }
            }
            .padding(8)
            .background(NordicElectricAI.surface)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isEditing ? NordicElectricAI.accentBlue : NordicElectricAI.accentBlue.opacity(0.3), lineWidth: 1)
            )
            .onAppear {
                if let currentTab = currentTab {
                    urlText = currentTab.url.absoluteString
                }
            }
            .onChange(of: appState.activeTabIndex) { _ in
                if let currentTab = currentTab {
                    urlText = currentTab.url.absoluteString
                }
            }
            
            // Action buttons with Nordic Electric AI styling
            HStack(spacing: 16) {
                Button(action: { appState.toggleAICopilot() }) {
                    Image(systemName: "sparkles")
                        .foregroundColor(appState.isAICopilotVisible ? NordicElectricAI.accentCyan : NordicElectricAI.textPrimary)
                        .nordicGlow(color: appState.isAICopilotVisible ? NordicElectricAI.accentCyan : .clear, intensity: 0.7)
                }
                .buttonStyle(NordicElectricAI.IconButtonStyle())
                
                Button(action: { appState.toggleTerminal() }) {
                    Image(systemName: "terminal")
                        .foregroundColor(appState.isTerminalVisible ? NordicElectricAI.accentCyan : NordicElectricAI.textPrimary)
                        .nordicGlow(color: appState.isTerminalVisible ? NordicElectricAI.accentCyan : .clear, intensity: 0.7)
                }
                .buttonStyle(NordicElectricAI.IconButtonStyle())
                
                Button(action: { appState.createNewTab() }) {
                    Image(systemName: "plus")
                        .foregroundColor(NordicElectricAI.textPrimary)
                }
                .buttonStyle(NordicElectricAI.IconButtonStyle())
                
                Button(action: showSettings) {
                    Image(systemName: "gear")
                        .foregroundColor(NordicElectricAI.textPrimary)
                }
                .buttonStyle(NordicElectricAI.IconButtonStyle())
            }
            .padding(.trailing, 16)
        }
        .frame(height: 60)
        .background(NordicElectricAI.backgroundMedium)
    }
    
    private var currentTab: BrowserTab? {
        guard appState.tabs.indices.contains(appState.activeTabIndex) else { return nil }
        return appState.tabs[appState.activeTabIndex]
    }
    
    private var canGoBack: Bool {
        guard let tab = currentTab else { return false }
        return tab.webView?.canGoBack ?? false
    }
    
    private var canGoForward: Bool {
        guard let tab = currentTab else { return false }
        return tab.webView?.canGoForward ?? false
    }
    
    private func goBack() {
        guard let tab = currentTab else { return }
        tab.webView?.goBack()
    }
    
    private func goForward() {
        guard let tab = currentTab else { return }
        tab.webView?.goForward()
    }
    
    private func refresh() {
        guard let tab = currentTab else { return }
        tab.webView?.reload()
    }
    
    private func loadURL() {
        guard var urlString = urlText.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.isEmpty else { return }
        
        // Check if it's a search query or URL
        if !urlString.contains(".") || urlString.contains(" ") {
            // Treat as search query
            urlString = "https://www.google.com/search?q=" + urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        } else if !urlString.contains("://") {
            // Add https:// if no scheme is specified
            urlString = "https://" + urlString
        }
        
        if let url = URL(string: urlString) {
            if appState.tabs.indices.contains(appState.activeTabIndex) {
                appState.tabs[appState.activeTabIndex].url = url
                appState.tabs[appState.activeTabIndex].isLoading = true
                appState.tabs[appState.activeTabIndex].webView?.load(URLRequest(url: url))
            }
        }
        
        isEditing = false
    }
    
    private func showSettings() {
        appState.showSettings = true
    }
}

struct TabBarView: View {
    @EnvironmentObject private var appState: AuroraAppState
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                    TabButtonView(tab: tab, isActive: index == appState.activeTabIndex) {
                        appState.activeTabIndex = index
                    } onClose: {
                        appState.closeTab(at: index)
                    }
                }
                
                Button(action: { appState.createNewTab() }) {
                    Image(systemName: "plus")
                        .foregroundColor(NordicElectricAI.textPrimary)
                        .frame(width: 30, height: 30)
                }
                .padding(.horizontal, 8)
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 40)
        .background(NordicElectricAI.backgroundDeep)
    }
}

struct TabButtonView: View {
    let tab: BrowserTab
    let isActive: Bool
    let onTap: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            if let favicon = tab.favicon {
                favicon
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "globe")
                    .foregroundColor(isActive ? NordicElectricAI.accentBlue : NordicElectricAI.textSecondary)
                    .frame(width: 16, height: 16)
            }
            
            Text(tab.title)
                .lineLimit(1)
                .foregroundColor(isActive ? NordicElectricAI.textPrimary : NordicElectricAI.textSecondary)
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(NordicElectricAI.textSecondary)
            }
            .opacity(isActive ? 1 : 0)
            .padding(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            isActive ? 
                NordicElectricAI.surface : 
                NordicElectricAI.backgroundMedium
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? NordicElectricAI.accentBlue.opacity(0.5) : .clear, lineWidth: 1)
        )
        .onTapGesture(perform: onTap)
    }
}

struct BrowserTabView: View {
    @Binding var tab: BrowserTab
    @State private var title: String = "New Tab"
    @State private var isLoading: Bool = true
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @EnvironmentObject private var appState: AuroraAppState
    
    var body: some View {
        WebViewContainer(
            url: tab.url,
            webView: $tab.webView,
            title: $title,
            isLoading: $isLoading,
            canGoBack: $canGoBack,
            canGoForward: $canGoForward,
            onPageLoad: { url in
                // Update tab properties
                tab.title = title
                tab.isLoading = isLoading
                
                // Add to history
                appState.addToHistory(url: url, title: title)
                
                // Extract page content for AI if enabled
                if appState.isAIInjectionEnabled {
                    tab.webView?.extractPageContent { content in
                        if let content = content {
                            appState.setAIContext(content: content, url: url)
                        }
                    }
                }
            }
        )
        .onChange(of: tab.url) { newURL in
            tab.webView?.load(URLRequest(url: newURL))
        }
        .onChange(of: title) { newTitle in
            tab.title = newTitle
        }
        .onChange(of: isLoading) { newValue in
            tab.isLoading = newValue
        }
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuroraAppState())
            .preferredColorScheme(.dark)
    }
}
