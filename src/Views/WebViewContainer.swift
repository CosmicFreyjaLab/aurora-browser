import SwiftUI
import WebKit
import Combine

struct WebViewContainer: UIViewRepresentable {
    let url: URL
    @Binding var webView: WKWebView?
    @Binding var title: String
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    var onPageLoad: ((URL) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        // Configure WKWebView
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        // Add user script for AI integration
        let aiScript = WKUserScript(
            source: createAIInjectionScript(),
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        
        let userContentController = WKUserContentController()
        userContentController.addUserScript(aiScript)
        userContentController.add(context.coordinator, name: "auroraAI")
        configuration.userContentController = userContentController
        
        // Create WKWebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Load initial URL
        webView.load(URLRequest(url: url))
        
        // Store reference
        self.webView = webView
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update only if URL has changed significantly
        if uiView.url?.absoluteString != url.absoluteString && 
           uiView.url?.host != url.host {
            uiView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createAIInjectionScript() -> String {
        """
        // Aurora AI Integration Script
        (function() {
            // Create Aurora AI button
            const aiButton = document.createElement('div');
            aiButton.id = 'aurora-ai-button';
            aiButton.style.position = 'fixed';
            aiButton.style.bottom = '20px';
            aiButton.style.right = '20px';
            aiButton.style.width = '50px';
            aiButton.style.height = '50px';
            aiButton.style.borderRadius = '25px';
            aiButton.style.backgroundColor = 'rgba(59, 158, 255, 0.9)';
            aiButton.style.boxShadow = '0 0 15px rgba(59, 158, 255, 0.5)';
            aiButton.style.display = 'flex';
            aiButton.style.justifyContent = 'center';
            aiButton.style.alignItems = 'center';
            aiButton.style.cursor = 'pointer';
            aiButton.style.zIndex = '9999';
            aiButton.style.transition = 'all 0.3s ease';
            
            // Add sparkles icon
            aiButton.innerHTML = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" fill="white"/></svg>';
            
            // Add hover effect
            aiButton.onmouseover = function() {
                this.style.transform = 'scale(1.1)';
            };
            aiButton.onmouseout = function() {
                this.style.transform = 'scale(1)';
            };
            
            // Add click handler
            aiButton.onclick = function() {
                // Get page content
                const pageContent = {
                    title: document.title,
                    url: window.location.href,
                    text: document.body.innerText.substring(0, 10000),
                    html: document.documentElement.outerHTML.substring(0, 20000)
                };
                
                // Send to Swift
                window.webkit.messageHandlers.auroraAI.postMessage(pageContent);
            };
            
            // Add to page
            document.body.appendChild(aiButton);
            
            // Expose Aurora AI API
            window.AuroraAI = {
                analyze: function() {
                    aiButton.click();
                },
                getSelection: function() {
                    return window.getSelection().toString();
                }
            };
        })();
        """
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebViewContainer
        private var pageTitle: String = "New Tab"
        
        init(_ parent: WebViewContainer) {
            self.parent = parent
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            
            // Update title
            webView.evaluateJavaScript("document.title") { (result, error) in
                if let title = result as? String {
                    self.parent.title = title
                }
            }
            
            // Notify about page load
            if let url = webView.url {
                parent.onPageLoad?(url)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "auroraAI" {
                // Handle AI message from webpage
                if let pageContent = message.body as? [String: Any],
                   let text = pageContent["text"] as? String,
                   let url = pageContent["url"] as? String,
                   let urlObj = URL(string: url) {
                    
                    // Post notification for AI service
                    NotificationCenter.default.post(
                        name: Notification.Name("AuroraAIPageContent"),
                        object: nil,
                        userInfo: [
                            "content": text,
                            "url": urlObj
                        ]
                    )
                }
            }
        }
        
        // MARK: - WKUIDelegate
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Handle new window/tab requests
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}

// MARK: - WKWebView Extensions

extension WKWebView {
    func extractPageContent(completion: @escaping (String?) -> Void) {
        let script = """
        (function() {
            const content = {
                title: document.title,
                url: window.location.href,
                text: document.body.innerText.substring(0, 10000)
            };
            return JSON.stringify(content);
        })();
        """
        
        self.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error extracting page content: \(error)")
                completion(nil)
                return
            }
            
            guard let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8),
                  let content = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = content["text"] as? String else {
                completion(nil)
                return
            }
            
            completion(text)
        }
    }
}
