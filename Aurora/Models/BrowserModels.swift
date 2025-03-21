import Foundation
import WebKit
import SwiftUI

struct BrowserTab: Identifiable {
    let id: UUID
    var url: URL
    var title: String
    var isLoading: Bool
    var webView: WKWebView?
    var favicon: Image?
    
    init(id: UUID, url: URL, title: String, isLoading: Bool, webView: WKWebView? = nil, favicon: Image? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.isLoading = isLoading
        self.webView = webView
        self.favicon = favicon
    }
}
