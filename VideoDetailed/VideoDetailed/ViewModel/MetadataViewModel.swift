//
//  MetadataViewModel.swift
//  VideoDetailed
//
//  Created by Monish Kumar on 25/11/25.
//

import Combine
import Foundation

// --- ViewModel ---
class MetadataViewModel: ObservableObject {
    @Published var metadata: VideoMetadata? = nil
    @Published var logs: [String] = []

    func appendLog(_ s: String) {
        DispatchQueue.main.async { self.logs.insert(s, at: 0) }
    }

    // If you have observed a private endpoint and cookies, you can call it here.
    // Provide the full URL and the cookies string (e.g. from WKHTTPCookieStore).
    func fetchFromPrivateEndpoint(url: URL, cookieHeader: String, completion: @escaping (Result<VideoMetadata, Error>) -> Void) {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        appendLog("Calling private endpoint: \(url.absoluteString)")

        let task = URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err = err { self.appendLog("Error: \(err.localizedDescription)"); completion(.failure(err)); return }
            guard let data = data else { let e = NSError(domain: "no-data", code: -1, userInfo: nil); completion(.failure(e)); return }
            // Try decode generic JSON -> map into VideoMetadata fields where possible
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                var vm = VideoMetadata()
                if let dict = json as? [String: Any] {
                    vm.raw = dict.mapValues { AnyCodable($0) }
                    vm.title = dict["title"] as? String ?? dict["name"] as? String
                    vm.description = dict["description"] as? String
                    if let images = dict["images"] as? [String] { vm.images = images }
                    if let id = dict["id"] as? String { vm.videoID = id }
                    if let release = dict["releaseDate"] as? String { vm.releaseDate = release }
                }
                DispatchQueue.main.async { self.metadata = vm }
                completion(.success(vm))
            } catch {
                self.appendLog("JSON parse error: \(error)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
