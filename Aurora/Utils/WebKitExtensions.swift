import Foundation
import WebKit

extension WKWebView {
    func extractPageContent(completion: @escaping (String?) -> Void) {
        let script = """
        (function() {
            let content = '';
            
            // Get the page title
            content += document.title + '\\n\\n';
            
            // Get meta description if available
            const metaDescription = document.querySelector('meta[name="description"]');
            if (metaDescription) {
                content += metaDescription.getAttribute('content') + '\\n\\n';
            }
            
            // Get main content
            const mainContent = document.querySelector('main') || document.body;
            
            // Extract text content, removing excessive whitespace
            content += mainContent.innerText
                .replace(/\\s+/g, ' ')
                .trim();
                
            return content;
        })();
        """
        
        evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error extracting page content: \(error)")
                completion(nil)
                return
            }
            
            if let content = result as? String {
                completion(content)
            } else {
                completion(nil)
            }
        }
    }
}
