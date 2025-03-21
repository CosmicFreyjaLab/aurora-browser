import WebKit
import SwiftUI

// MARK: - WKWebView Extensions

extension WKWebView {
    /// Extract the main content from the current webpage
    func extractPageContent(completion: @escaping (String?) -> Void) {
        let script = """
        (function() {
            // Helper function to get readable content
            function getReadableContent() {
                // Try to find main content containers
                const selectors = [
                    'article',
                    'main',
                    '.content',
                    '.main',
                    '.article',
                    '.post',
                    '#content',
                    '#main',
                    '.page'
                ];
                
                let mainContent = '';
                
                // Try each selector
                for (const selector of selectors) {
                    const elements = document.querySelectorAll(selector);
                    if (elements.length > 0) {
                        // Use the largest content block
                        let largestElement = elements[0];
                        let largestLength = elements[0].innerText.length;
                        
                        for (let i = 1; i < elements.length; i++) {
                            if (elements[i].innerText.length > largestLength) {
                                largestElement = elements[i];
                                largestLength = elements[i].innerText.length;
                            }
                        }
                        
                        if (largestLength > 200) {
                            mainContent = largestElement.innerText;
                            break;
                        }
                    }
                }
                
                // If no main content found, use body text
                if (!mainContent) {
                    mainContent = document.body.innerText;
                }
                
                return mainContent;
            }
            
            // Create content object
            const content = {
                title: document.title,
                url: window.location.href,
                text: getReadableContent().substring(0, 15000),
                metaDescription: document.querySelector('meta[name="description"]')?.content || '',
                h1: Array.from(document.querySelectorAll('h1')).map(h => h.innerText).join(' | ')
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
            
            // Format the content with metadata
            let title = content["title"] as? String ?? "Untitled"
            let url = content["url"] as? String ?? ""
            let metaDescription = content["metaDescription"] as? String ?? ""
            let h1 = content["h1"] as? String ?? ""
            
            let formattedContent = """
            Title: \(title)
            URL: \(url)
            \(metaDescription.isEmpty ? "" : "Description: \(metaDescription)\n")
            \(h1.isEmpty ? "" : "Headings: \(h1)\n")
            
            Content:
            \(text)
            """
            
            completion(formattedContent)
        }
    }
    
    /// Inject Aurora AI assistant into the webpage
    func injectAuroraAI() {
        let script = """
        (function() {
            // Check if already injected
            if (document.getElementById('aurora-ai-assistant')) {
                return;
            }
            
            // Create Aurora AI container
            const container = document.createElement('div');
            container.id = 'aurora-ai-assistant';
            container.style.position = 'fixed';
            container.style.bottom = '20px';
            container.style.right = '20px';
            container.style.zIndex = '9999';
            
            // Create Aurora AI button
            const button = document.createElement('div');
            button.id = 'aurora-ai-button';
            button.style.width = '50px';
            button.style.height = '50px';
            button.style.borderRadius = '25px';
            button.style.backgroundColor = 'rgba(59, 158, 255, 0.9)';
            button.style.boxShadow = '0 0 15px rgba(59, 158, 255, 0.5)';
            button.style.display = 'flex';
            button.style.justifyContent = 'center';
            button.style.alignItems = 'center';
            button.style.cursor = 'pointer';
            button.style.transition = 'all 0.3s ease';
            
            // Add sparkles icon
            button.innerHTML = '<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" fill="white"/></svg>';
            
            // Add hover effect
            button.onmouseover = function() {
                this.style.transform = 'scale(1.1)';
            };
            button.onmouseout = function() {
                this.style.transform = 'scale(1)';
            };
            
            // Add click handler
            button.onclick = function() {
                // Get page content
                const pageContent = {
                    title: document.title,
                    url: window.location.href,
                    text: document.body.innerText.substring(0, 10000)
                };
                
                // Send to Swift
                window.webkit.messageHandlers.auroraAI.postMessage(pageContent);
            };
            
            // Add to page
            container.appendChild(button);
            document.body.appendChild(container);
            
            // Expose Aurora AI API
            window.AuroraAI = {
                analyze: function() {
                    button.click();
                },
                getSelection: function() {
                    return window.getSelection().toString();
                }
            };
        })();
        """
        
        let userScript = WKUserScript(
            source: script,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        
        self.configuration.userContentController.addUserScript(userScript)
    }
    
    /// Execute a terminal command and return the result to JavaScript
    func executeTerminalCommand(_ command: String, completion: @escaping (String) -> Void) {
        // This is a bridge to the TerminalService
        // In a real implementation, this would communicate with the TerminalService
        // For security, we're just simulating it here
        
        // Simulate command execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let output = "Command '\(command)' executed in Aurora Terminal\nThis is a simulated response for security reasons."
            completion(output)
        }
    }
}

// MARK: - WKWebView SwiftUI Wrapper

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var title: String
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    var onPageLoad: ((URL) -> Void)?
    var onAIRequest: ((String, URL) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "auroraAI")
        configuration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        webView.load(URLRequest(url: url))
        webView.injectAuroraAI()
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url?.absoluteString != url.absoluteString {
            webView.load(URLRequest(url: url))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            
            webView.evaluateJavaScript("document.title") { (result, error) in
                if let title = result as? String {
                    self.parent.title = title
                }
            }
            
            if let url = webView.url {
                parent.onPageLoad?(url)
            }
            
            // Re-inject Aurora AI (in case it was lost during navigation)
            webView.injectAuroraAI()
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "auroraAI" {
                if let pageContent = message.body as? [String: Any],
                   let text = pageContent["text"] as? String,
                   let urlString = pageContent["url"] as? String,
                   let url = URL(string: urlString) {
                    parent.onAIRequest?(text, url)
                }
            }
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}
