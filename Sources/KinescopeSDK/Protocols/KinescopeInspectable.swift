//
//  KinescopeInspectable.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 23.03.2021.
//

/// Protocol managing inspectations of dashboard content like videos, projects etc
public protocol KinescopeInspectable: AnyObject {

    /// Entry for `GET` Video task with an explicit `Referer` header.
    ///
    /// Added in 0.3.0-kinescoper.1.
    ///
    /// - parameter id: id of video to inspect
    /// - parameter referer: `Referer` header; `nil` falls back to `KinescopeConfig.referer`.
    /// - parameter onSuccess: callback on success. Returns `KinescopeVideo` object aplicable for player.
    /// - parameter onError: callback on error. Called for every failure, including non-2xx responses.
    func video(id: String,
               referer: String?,
               onSuccess: @escaping (KinescopeVideo) -> Void,
               onError: @escaping (KinescopeInspectError) -> Void)

}

public extension KinescopeInspectable {

    func video(id: String,
               onSuccess: @escaping (KinescopeVideo) -> Void,
               onError: @escaping (KinescopeInspectError) -> Void) {
        video(id: id, referer: nil, onSuccess: onSuccess, onError: onError)
    }

}
