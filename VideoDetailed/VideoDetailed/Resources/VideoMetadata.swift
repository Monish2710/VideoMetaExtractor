//
//  VideoMetadata.swift
//  VideoDetailed
//
//  Created by Monish Kumar on 25/11/25.
//

import Combine
import SwiftUI
import WebKit
// Single-file SwiftUI app that demonstrates:
// 1) a WKWebView for signing into a streaming site and browsing
// 2) injecting JavaScript to extract metadata from the currently loaded page (JSON-LD, Open Graph, meta tags)
// 3) copying cookies from the WKWebView and using them for a manual URLRequest to a reverse-engineered API endpoint
//
// IMPORTANT: This app does NOT attempt to bypass authentication. It uses the user's active WebKit session (cookies) and reads
// metadata available on the page. If you want to call private service endpoints, supply the endpoint and use the copied cookies.
// Use only with accounts you are authorized to use.

// --- Models ---
struct VideoMetadata: Codable, Identifiable {
    var id: String { (videoID ?? title) ?? UUID().uuidString }
    var title: String?
    var description: String?
    var videoID: String?
    var series: String?
    var season: Int?
    var episode: Int?
    var releaseDate: String?
    var images: [String] = []
    var raw: [String: AnyCodable]? = nil
}

// Helper to allow storing arbitrary JSON in `raw`
struct AnyCodable: Codable {
    let value: Any
    init(_ value: Any) { self.value = value }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v; return }
        if let v = try? container.decode(Int.self) { value = v; return }
        if let v = try? container.decode(Double.self) { value = v; return }
        if let v = try? container.decode(String.self) { value = v; return }
        if let v = try? container.decode([String: AnyCodable].self) {
            value = v.mapValues { $0.value }; return
        }
        if let v = try? container.decode([AnyCodable].self) {
            value = v.map { $0.value }; return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [String: Any]:
            let mapped = v.mapValues { AnyCodable($0) }
            try container.encode(mapped)
        case let v as [Any]:
            try container.encode(v.map { AnyCodable($0) })
        default:
            let s = String(describing: value)
            try container.encode(s)
        }
    }
}

// --- JavaScript snippet to extract metadata from a page ---
let extractMetadataJS = """
(function() {
    function firstMeta(name) {
        var m = document.querySelector('meta[property="' + name + '"]') || document.querySelector('meta[name="' + name + '"]');
        return m ? (m.content || m.getAttribute('content')) : null;
    }
    var result = {};
    // Try JSON-LD
    try {
        var scripts = document.querySelectorAll('script[type="application/ld+json"]');
        if (scripts.length > 0) {
            for (var i=0;i<scripts.length;i++) {
                try {
                    var j = JSON.parse(scripts[i].innerText || scripts[i].textContent);
                    // If we find a video object or schema.org MediaObject, merge
                    if (j) {
                        if (j['@type'] && (j['@type'].toLowerCase().indexOf('video') !== -1 || j['@type'] === 'MediaObject')) {
                            result.title = result.title || j.name || j.title;
                            result.description = result.description || j.description;
                            result.releaseDate = result.releaseDate || j.datePublished || j.uploadDate;
                            if (j.image) {
                                if (Array.isArray(j.image)) result.images = (result.images||[]).concat(j.image);
                                else result.images = (result.images||[]).concat([j.image]);
                            }
                            if (j.partOfSeries) result.series = j.partOfSeries.name || j.partOfSeries;
                        } else if (Array.isArray(j)) {
                            // some pages wrap many objects
                            j.forEach(function(obj) {
                                if (obj['@type'] && obj['@type'].toLowerCase().indexOf('video') !== -1) {
                                    result.title = result.title || obj.name;
                                    result.description = result.description || obj.description;
                                }
                            })
                        }
                    }
                } catch(e) { }
            }
        }
    } catch(e) {}

    // Open Graph
    result.title = result.title || firstMeta('og:title') || firstMeta('twitter:title') || document.title || null;
    result.description = result.description || firstMeta('og:description') || firstMeta('description') || firstMeta('twitter:description') || null;
    var ogImage = firstMeta('og:image') || firstMeta('twitter:image');
    if (ogImage) { result.images = (result.images||[]).concat([ogImage]); }

    // Try extract video id from common data attributes (best-effort)
    var vid = null;
    // data attributes
    ['data-video-id', 'data-asset-id', 'data-id', 'data-video'].forEach(function(k){
        var el = document.querySelector('['+k+']'); if(el && !vid) vid = el.getAttribute(k);
    });
    // Url patterns
    if(!vid) {
        var m = window.location.href.match(/(video|watch|title)[\\/\\_-]?(\\d{4,})/i);
        if (m) vid = m[2];
    }
    if(vid) result.videoID = vid;

    // Add final housekeeping defaults
    result.images = result.images || [];

    // Post message (stringified JSON)
    try {
        window.webkit.messageHandlers.metadata.postMessage(JSON.stringify(result));
    } catch(e) {
        try { window.postMessage({type:'metadata', payload: result}, '*'); } catch(e) {}
    }
    return result;
})();
"""
