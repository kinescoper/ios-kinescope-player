//
//  CurrentItemStatusObserver.swift
//  KinescopeSDK
//
//  Created by Nikita Korobeinikov on 26.02.2024.
//

import Foundation
import AVFoundation

final class CurrentItemStatusObserver: KVOObserverFactory {
    
    private weak var playerBody: KinescopePlayerBody?
    private weak var repeater: Repeater?

    private var readyToPlayReceived: () -> Void
    /// Item, its error and whether the SDK's repeater scheduled another attempt.
    private var failureReceived: (AVPlayerItem, Error?, Bool) -> Void

    init(playerBody: KinescopePlayerBody,
         repeater: Repeater,
         failureReceived: @escaping (AVPlayerItem, Error?, Bool) -> Void,
         readyToPlayReceived: @escaping () -> Void) {
        self.playerBody = playerBody
        self.repeater = repeater
        self.failureReceived = failureReceived
        self.readyToPlayReceived = readyToPlayReceived
    }

    func provide() -> NSKeyValueObservation? {
        playerBody?.strategy.player.currentItem?.observe(
            \.status,
            options: [.new, .old],
            changeHandler: { [weak self] item, _ in
                guard let self else {
                    return
                }

                switch item.status {
                case .readyToPlay:
                    onSuccess()
                case .failed, .unknown:
                    Kinescope.shared.logger?.log(error: item.error,
                                                 level: KinescopeLoggerLevel.player)
                    let willRetry = onError(error: item.error)
                    if item.status == .failed {
                        failureReceived(item, item.error, willRetry)
                    }
                default:
                    break
                }

                Kinescope.shared.logger?.log(message: "AVPlayerItem.Status – \(item.status.debugDescription)",
                                             level: KinescopeLoggerLevel.player)
                playerBody?.delegate?.player(changedItemStatusTo: item.status)
            }
        )
    }

}

// MARK: - Private

private extension CurrentItemStatusObserver {

    func onSuccess() {
        readyToPlayReceived()
        playerBody?.view?.stopLoader(withPreview: true)
        playerBody?.view?.announceSnack?.hideAnimated()
        playerBody?.view?.overlay?.isHidden = false
    }

    /// Returns `true` when the repeater scheduled another attempt.
    func onError(error: Error?) -> Bool {
        // CoreMediaErrorDomain error -16190 means that live stream is not ready to play
        if let error = error as NSError?, error.code == -16190 {
            showLiveStub()
            return tryRepeat(with: nil)
        } else {
            return tryRepeat(with: error)
        }
    }
    
    func showLiveStub() {
        guard let video = playerBody?.video else {
            return
        }
        playerBody?.view?.announceSnack?.display(startsAt: video.live?.startsAt)
    }

    @discardableResult
    func tryRepeat(with error: Error?) -> Bool {
        switch repeater?.start() {
        case .inProgress:
            playerBody?.view?.startLoader()
            return true
        case .limitReached, .none:
            playerBody?.view?.stopLoader(withPreview: false)
            if let error {
                playerBody?.view?.errorOverlay?.display(error: error)
            }
            return false
        }
    }

}
