//
//  AVURLAsset+Referer.swift
//  KinescopeSDK
//

import AVFoundation

extension AVURLAsset {

    /// Undocumented AVURLAsset option: extra HTTP headers that AVFoundation attaches to every request
    /// it makes for the asset (playlists, media segments, AES-128 keys).
    ///
    /// The iOS SDK has no public equivalent: `AVURLAssetHTTPCookiesKey` and `AVURLAssetHTTPUserAgentKey`
    /// cover cookies and User-Agent only, and `AVAssetResourceLoaderDelegate` cannot serve HLS media
    /// segments, so the `Referer` would not reach them. The key is a plain string, not a private symbol.
    static let httpHeaderFieldsKey = "AVURLAssetHTTPHeaderFieldsKey"

    static func options(referer: String?) -> [String: Any]? {
        guard let referer, !referer.isEmpty else {
            return nil
        }
        return [httpHeaderFieldsKey: ["Referer": referer]]
    }

}
