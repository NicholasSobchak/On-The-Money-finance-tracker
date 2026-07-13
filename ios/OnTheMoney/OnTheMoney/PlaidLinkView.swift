import SwiftUI
import WebKit

struct PlaidLinkView: UIViewRepresentable {
    let linkToken: String
    let onComplete: (String, String, String) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = config.userContentController
        contentController.add(context.coordinator, name: "plaidHandler")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false

        let js = """
        window.addEventListener('message', function(event) {
            if (event.data && event.data.public_token) {
                window.webkit.messageHandlers.plaidHandler.postMessage({
                    public_token: event.data.public_token,
                    institution_id: event.data.institution_id || '',
                    institution_name: event.data.institution_name || ''
                });
            }
        });
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)

        let redirectUri = "http://localhost/plaid-callback"
        let urlString = "https://cdn.link.plaid.com/link.html?token=\(linkToken)&redirectUri=\(redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectUri)"
        webView.load(URLRequest(url: URL(string: urlString)!))

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: PlaidLinkView
        private var didComplete = false

        init(_ parent: PlaidLinkView) {
            self.parent = parent
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard !didComplete,
                  let body = message.body as? [String: Any],
                  let publicToken = body["public_token"] as? String
            else { return }
            didComplete = true
            let institutionId = body["institution_id"] as? String ?? ""
            let institutionName = body["institution_name"] as? String ?? ""
            parent.onComplete(publicToken, institutionId, institutionName)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if let url = navigationAction.request.url,
               url.absoluteString.contains("plaid-callback") {
                decisionHandler(.cancel)
                if !didComplete {
                    didComplete = true
                    let fragment = url.fragment ?? ""
                    let params = fragment.components(separatedBy: "&").reduce(into: [String: String]()) { dict, pair in
                        let parts = pair.components(separatedBy: "=")
                        if parts.count == 2 { dict[parts[0]] = parts[1] }
                    }
                    if let token = params["public-token"] {
                        let instId = params["institution_id"] ?? ""
                        let instName = params["institution_name"] ?? ""
                        parent.onComplete(token, instId, instName)
                    } else {
                        parent.onCancel()
                    }
                }
            } else {
                decisionHandler(.allow)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if !didComplete {
                parent.onCancel()
            }
        }
    }
}
