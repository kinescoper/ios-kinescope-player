//
//  KinescopePlaybackControllable.swift
//  KinescopeSDK
//

import Foundation

/// Programmatic playback control on top of `KinescopePlayer`.
///
/// Added in 0.3.0-kinescoper.1. Kept separate from `KinescopePlayer` so existing conformers
/// of that protocol stay source-compatible.
public protocol KinescopePlaybackControllable: KinescopePlayer {

    /// Current playback position in seconds; `0` while nothing is loaded.
    var currentTime: TimeInterval { get }

    /// Duration of the current item in seconds; `nil` until it is known and for live streams.
    var duration: TimeInterval? { get }

    /// Loads the video JSON and binds the player item without starting playback and without
    /// any extra SDK UI. Reports the result through `playerDidLoadVideo(error:)`; call `play()` afterwards.
    /// Calling `play()` while loading starts playback once the video is loaded.
    func prepare()

    /// Seeks to `time` seconds. Before the item is ready the position is kept and applied on ready,
    /// so it can be used to restore a position after reload.
    func seek(to time: TimeInterval)

}
