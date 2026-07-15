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

        let js = """
        (function() {
            function sendToNative(data) {
                if (data && data.public_token) {
                    window.webkit.messageHandlers.plaidHandler.postMessage({
                        public_token: data.public_token,
                        institution_id: data.institution_id || '',
                        institution_name: data.institution_name || ''
                    });
                }
            }
            window.addEventListener('message', function(event) {
                sendToNative(event.data);
            });
        })();
        """
        let script = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(script)

        let urlString = "https://cdn.plaid.com/link/v2/stable/link.html?isWebview=true&token=\(linkToken)"
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
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if !didComplete {
                parent.onCancel()
            }
        }
    }
}
