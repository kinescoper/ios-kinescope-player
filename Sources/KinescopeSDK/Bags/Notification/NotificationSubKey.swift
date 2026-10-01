//
//  NotificationSubKey.swift
//  KinescopeSDK
//
//  Created by Nikita Korobeinikov on 26.02.2024.
//

import Foundation
import UIKit
import AVFoundation

enum NotificationSubKey {

    case appWillEnterForeground
    case appDidEnterBackground
    case deviceOrientationChanged
    case itemDidPlayToEnd
    case itemFailedToPlayToEndTime
    case itemNewErrorLogEntry

    var notificationName: NSNotification.Name {
        switch self {
        case .appWillEnterForeground:
            return UIApplication.willEnterForegroundNotification
        case .appDidEnterBackground:
            return UIApplication.didEnterBackgroundNotification
        case .deviceOrientationChanged:
            return UIDevice.orientationDidChangeNotification
        case .itemDidPlayToEnd:
            return AVPlayerItem.didPlayToEndTimeNotification
        case .itemFailedToPlayToEndTime:
            return AVPlayerItem.failedToPlayToEndTimeNotification
        case .itemNewErrorLogEntry:
            return AVPlayerItem.newErrorLogEntryNotification
        }
    }

}
