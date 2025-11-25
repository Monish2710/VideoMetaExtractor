//
//  ContentView.swift
//  VideoDetailed
//
//  Created by Monish Kumar on 25/11/25.
//

import Combine
import SwiftUI
import WebKit

// --- SwiftUI ContentView ---
struct ContentView: View {
    // We'll create the view model in init() and use the same instance for the StateObject and the WebView.
    @StateObject private var vm: MetadataViewModel
    private let webViewHolder: WebView

    @State private var urlString: String = "https://www.netflix.com" // change to streaming site home
    @State private var apiEndpoint: String = ""

    init() {
        let viewModel = MetadataViewModel()
        _vm = StateObject(wrappedValue: viewModel)
        webViewHolder = WebView(vm: viewModel)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 8) {
                HStack {
                    TextField("Enter URL to browse (use stream site)", text: $urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: {
                        if let url = URL(string: urlString) {
                            webViewHolder.webView.load(URLRequest(url: url))
                        }
                    }) {
                        Text("Go")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                // Show the WebView (no assignments here)
                webViewHolder
                    .frame(height: 360)
                    .cornerRadius(8)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button(action: {
                        webViewHolder.webView.evaluateJavaScript(extractMetadataJS) { _, err in
                            if let err = err {
                                vm.appendLog("JS inject error: \(err)")
                                return
                            }
                            vm.appendLog("JS executed; waiting for result")
                        }
                    }) {
                        Text("Extract Metadata")
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        copyCookiesAndCallEndpoint()
                    }) {
                        Text("Copy Cookies")
                            .font(.callout.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading) {
                    if let m = vm.metadata {
                        Text("Title: \(m.title ?? "—")").font(.headline)
                        Text("Description: \(m.description ?? "—")").lineLimit(3)
                        Text("ID: \(m.videoID ?? "—")")
                        Text("Series: \(m.series ?? "—")  Season: \(m.season.map(String.init) ?? "—") Episode: \(m.episode.map(String.init) ?? "—")")
                        Text("Release: \(m.releaseDate ?? "—")")
                        if m.images.count > 0 {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(m.images, id: \.self) { urlStr in
                                        AsyncImage(url: URL(string: urlStr)) { img in
                                            img.resizable().aspectRatio(contentMode: .fit)
                                        } placeholder: {
                                            Color.gray.frame(width: 120, height: 70)
                                        }
                                        .frame(width: 120, height: 70)
                                        .cornerRadius(6)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } else {
                        Text("No metadata yet. Use \"Extract Metadata from Page\" after loading a video page.")
                    }
                }
                .padding(.horizontal)

                List {
                    Section(header: Text("Logs")) {
                        ForEach(vm.logs, id: \.self) { l in
                            Text(l).font(.system(size: 12))
                        }
                    }

                    Section(header: Text("Manual Private API Call (advanced)")) {
                        TextField("Private endpoint URL (observed)", text: $apiEndpoint)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button("Call Endpoint with WebView cookies") {
                            guard let url = URL(string: apiEndpoint) else { vm.appendLog("Invalid endpoint"); return }
                            copyCookiesAndCallEndpoint(url: url)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Streaming Metadata Extractor")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if let url = URL(string: urlString) {
                webViewHolder.webView.load(URLRequest(url: url))
            }
        }
    }

    func copyCookiesAndCallEndpoint(url: URL? = nil) {
        let target = url
        let store = webViewHolder.webView.configuration.websiteDataStore.httpCookieStore
        store.getAllCookies { cookies in
            // Build Cookie header
            let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            vm.appendLog("Copied \(cookies.count) cookies; cookie header length: \(cookieHeader.count)")

            if let url = target {
                vm.fetchFromPrivateEndpoint(url: url, cookieHeader: cookieHeader) { res in
                    switch res {
                    case let .success(meta): vm.appendLog("Private endpoint returned metadata: \(meta.title ?? "(no title)")")
                    case let .failure(e): vm.appendLog("Private endpoint error: \(e.localizedDescription)")
                    }
                }
            } else {
                vm.appendLog("Cookie header: \(String(cookieHeader.prefix(300)))...")
            }
        }
    }
}
