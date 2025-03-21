import SwiftUI
import WebKit

struct ContentView: View {
    @EnvironmentObject var appState: AuroraAppState
    @State private var urlString: String = "https://www.google.com"
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation bar
            HStack {
                // Back/Forward buttons
                HStack(spacing: 8) {
                    Button(action: {
                        appState.currentTab?.webView?.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(appState.currentTab?.webView?.canGoBack != true)
                    
                    Button(action: {
                        appState.currentTab?.webView?.goForward()
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(appState.currentTab?.webView?.canGoForward != true)
                    
                    Button(action: {
                        if let url = appState.currentTab?.url {
                            appState.currentTab?.webView?.reload()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .padding(.leading, 8)
                
                // URL bar
                TextField("Enter URL", text: $urlString, onCommit: loadURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 8)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        appState.createNewTab()
                    }) {
                        Image(systemName: "plus")
                    }
                    
                    Button(action: {
                        // Show settings
                        appState.showSettings.toggle()
                    }) {
                        Image(systemName: "gear")
                    }
                }
                .padding(.trailing, 8)
            }
            .padding(8)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Tab bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(appState.tabs.enumerated()), id: \.element.id) { index, tab in
                        TabView(tab: tab, isActive: index == appState.activeTabIndex) {
                            appState.activeTabIndex = index
                        } closeAction: {
                            appState.closeTab(at: index)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 36)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Main content area
            ZStack {
                if let currentTab = appState.currentTab {
                    TabContentView(tab: currentTab)
                        .onAppear {
                            urlString = currentTab.url.absoluteString
                        }
                } else {
                    Text("No active tab")
                        .foregroundColor(.gray)
                }
                
                // Terminal overlay (if visible)
                VStack {
                    Spacer()
                    
                    if appState.isTerminalVisible {
                        TerminalView()
                            .transition(.move(edge: .bottom))
                    }
                }
                .animation(.easeInOut, value: appState.isTerminalVisible)
                
                // AI Copilot overlay (if visible)
                HStack {
                    Spacer()
                    
                    if appState.isAICopilotVisible {
                        AICopilotView()
                            .transition(.move(edge: .trailing))
                    }
                }
                .animation(.easeInOut, value: appState.isAICopilotVisible)
            }
            
            // Status bar
            StatusBarView()
                .background(Color(NSColor.windowBackgroundColor))
        }
    }
    
    private func loadURL() {
        guard !urlString.isEmpty else { return }
        
        var finalURLString = urlString
        
        // Add https:// if no scheme is specified
        if !urlString.contains("://") {
            finalURLString = "https://" + urlString
        }
        
        if let url = URL(string: finalURLString) {
            if let currentTab = appState.currentTab {
                currentTab.webView?.load(URLRequest(url: url))
            } else {
                appState.createNewTab(withURL: url)
            }
            urlString = finalURLString
        }
    }
}

struct TabView: View {
    let tab: BrowserTab
    let isActive: Bool
    let selectAction: () -> Void
    let closeAction: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            if let favicon = tab.favicon {
                favicon
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "globe")
                    .frame(width: 16, height: 16)
            }
            
            Text(tab.title)
                .lineLimit(1)
                .frame(maxWidth: 120, alignment: .leading)
            
            Button(action: closeAction) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
            }
            .buttonStyle(.plain)
            .opacity(isActive ? 1 : 0)
            .frame(width: 16, height: 16)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isActive ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .onTapGesture {
            selectAction()
        }
    }
}

struct TabContentView: View {
    @State var tab: BrowserTab
    @State private var isLoading: Bool
    @State private var title: String
    
    init(tab: BrowserTab) {
        self._tab = State(initialValue: tab)
        self._isLoading = State(initialValue: tab.isLoading)
        self._title = State(initialValue: tab.title)
    }
    
    var body: some View {
        WebViewContainer(
            url: tab.url,
            isLoading: $isLoading,
            title: $title,
            onNavigationChange: { newURL in
                tab.url = newURL
                tab.isLoading = isLoading
                tab.title = title
            }
        )
        .onChange(of: title) { newTitle in
            tab.title = newTitle
        }
        .onChange(of: isLoading) { newValue in
            tab.isLoading = newValue
        }
    }
}
