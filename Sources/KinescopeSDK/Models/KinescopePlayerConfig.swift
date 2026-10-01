//
//  KinescopePlayerConfig.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 29.03.2021.
//

import Foundation

/// Configuration entity required to connect resource with player
public struct KinescopePlayerConfig {

    /// Id of concrete video. For example from [GET Videos list](https://documenter.getpostman.com/view/10589901/TVCcXpNM)
    public let videoId: String

    /// If value is `true` show video in infinite loop.
    public let looped: Bool
    
    /// Repeating mode for player
    public let repeatingMode: RepeatingMode

    /// `Referer` header for this video. Added in 0.3.0-kinescoper.1.
    ///
    /// Sent with the video JSON request and with every HLS request made by AVFoundation
    /// (master and variant playlists, media segments, AES-128 keys).
    /// `nil` falls back to `KinescopeConfig.referer`.
    public let referer: String?

    /// Default link to share video and play it on web.
    public var shareLink: URL? {
        URL(string: "https://kinescope.io/\(videoId)")
    }

    /// - parameter videoId: Id of concrete video. For example from [GET Videos list](https://documenter.getpostman.com/view/10589901/TVCcXpNM)
    /// - parameter looped: If value is `true` show video in infinite loop. By default is `false`
    /// - parameter repeatingMode: Mode which will be used to repeat failed requests.
    /// - parameter referer: `Referer` header for this video; `nil` falls back to `KinescopeConfig.referer`.
    public init(videoId: String,
                looped: Bool = false,
                repeatingMode: RepeatingMode = .default,
                referer: String? = nil) {
        self.videoId = videoId
        self.looped = looped
        self.repeatingMode = repeatingMode
        self.referer = referer
    }

    /// Referer actually sent: the per-video one or the global `KinescopeConfig.referer`.
    var effectiveReferer: String? {
        referer ?? Kinescope.shared.config?.referer
    }

}
