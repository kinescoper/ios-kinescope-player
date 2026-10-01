//
//  KinescopeViewo+Manifest.swift
//  KinescopeSDK
//
//  Created by Nikita Korobeinikov on 20.02.2024.
//

import Foundation
import M3U8Kit

extension KinescopeVideo {

    /// Loads and parses only the master playlist, sending `referer` like the AVPlayer requests do.
    ///
    /// Blocks the calling thread; call it off the main queue.
    func masterPlaylist(referer: String?) -> M3U8MasterPlaylist? {
        guard let url = URL(string: hlsLink) else {
            return nil
        }
        var request = URLRequest(url: url)
        if let referer, !referer.isEmpty {
            request.setValue(referer, forHTTPHeaderField: "Referer")
        }

        let semaphore = DispatchSemaphore(value: 0)
        var content: String?
        URLSession.shared.dataTask(with: request) { data, response, _ in
            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode),
               let data {
                content = String(data: data, encoding: .utf8)
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()

        guard let content else {
            return nil
        }
        return M3U8MasterPlaylist(content: content, baseURL: url.deletingLastPathComponent())
    }

    func firstResolution(referer: String?) -> MediaResoulution? {
        masterPlaylist(referer: referer)?.xStreamList?.firstStreamInf()?.resolution
    }

}
