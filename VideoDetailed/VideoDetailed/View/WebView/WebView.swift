//
//  WebView.swift
//  VideoDetailed
//
//  Created by Monish Kumar on 25/11/25.
//
import SwiftUI
import WebKit

// --- WebView Representable ---
struct WebView: UIViewRepresentable {
    let webView: WKWebView
    @ObservedObject var vm: MetadataViewModel

    init(vm: MetadataViewModel) {
        self.vm = vm
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true

        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()
        config.userContentController = userContent

        webView = WKWebView(frame: .zero, configuration: config)

        userContent.add(CallbackScriptMessageHandler(viewModel: vm), name: "metadata")
    }

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(vm: vm) }

    class Coordinator: NSObject, WKNavigationDelegate {
        var vm: MetadataViewModel
        init(vm: MetadataViewModel) { self.vm = vm }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            vm.appendLog("Loaded: \(webView.url?.absoluteString ?? "(no url)")")
        }
    }

    // Message handler wrapper to be able to hold a strong reference to the ViewModel
    class CallbackScriptMessageHandler: NSObject, WKScriptMessageHandler {
        var vm: MetadataViewModel
        init(viewModel: MetadataViewModel) { vm = viewModel }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "metadata" else { return }
            vm.appendLog("Received metadata message")
            if let body = message.body as? String {
                // Body is a JSON string created by injected JS
                if let data = body.data(using: .utf8) {
                    do {
                        let decoder = JSONDecoder()
                        let meta = try decoder.decode(VideoMetadata.self, from: data)
                        DispatchQueue.main.async { self.vm.metadata = meta }
                    } catch {
                        vm.appendLog("Decoding metadata failed: \(error)")
                    }
                }
            } else if let dict = message.body as? [String: Any] {
                // fallback: convert dict to JSON
                do {
                    let data = try JSONSerialization.data(withJSONObject: dict, options: [])
                    let decoder = JSONDecoder()
                    let meta = try decoder.decode(VideoMetadata.self, from: data)
                    DispatchQueue.main.async { self.vm.metadata = meta }
                } catch {
                    vm.appendLog("Decoding fallback failed: \(error)")
                }
            }
        }
    }
}
