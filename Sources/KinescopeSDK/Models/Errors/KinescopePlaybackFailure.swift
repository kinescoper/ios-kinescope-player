//
//  KinescopePlaybackFailure.swift
//  KinescopeSDK
//

import AVFoundation

/// Entry of `AVPlayerItem.errorLog()`, reported as it appears.
///
/// Added in 0.3.0-kinescoper.1. Many entries are recoverable (AVFoundation switches variants
/// or retries a segment by itself); a fatal failure arrives as `KinescopePlaybackFailure`.
public struct KinescopePlaybackErrorLogEntry: Equatable {

    public let date: Date?
    /// URI of the playlist, segment or key that failed.
    public let uri: String?
    public let serverAddress: String?
    /// `errorStatusCode` as reported by AVFoundation: an HTTP status or a negative CoreMedia code.
    public let errorStatusCode: Int
    public let errorDomain: String
    public let errorComment: String?

    public init(date: Date?,
                uri: String?,
                serverAddress: String?,
                errorStatusCode: Int,
                errorDomain: String,
                errorComment: String?) {
        self.date = date
        self.uri = uri
        self.serverAddress = serverAddress
        self.errorStatusCode = errorStatusCode
        self.errorDomain = errorDomain
        self.errorComment = errorComment
    }

    init(event: AVPlayerItemErrorLogEvent) {
        self.init(date: event.date,
                  uri: event.uri,
                  serverAddress: event.serverAddress,
                  errorStatusCode: event.errorStatusCode,
                  errorDomain: event.errorDomain,
                  errorComment: event.errorComment)
    }

    /// HTTP status behind the entry, if it was an HTTP failure.
    public var httpStatusCode: Int? {
        if (400..<600).contains(errorStatusCode) {
            return errorStatusCode
        }
        if let comment = errorComment, let code = Self.httpStatus(inComment: comment) {
            return code
        }
        return Self.coreMediaHTTPCodes[errorStatusCode]
    }

}

/// Fatal playback failure of the current `AVPlayerItem`.
///
/// Added in 0.3.0-kinescoper.1. The SDK does not decide whether to retry beyond its own
/// `RepeatingMode` (pass `RepeatingMode(attempts: 0, interval: .never)` to disable it);
/// retry policy belongs to the app.
public struct KinescopePlaybackFailure: Error {

    public enum Source: Equatable {
        /// `AVPlayerItem.status` became `.failed`.
        case itemStatus
        /// `AVPlayerItemFailedToPlayToEndTime` was posted for the current item.
        case failedToPlayToEnd
    }

    public let source: Source
    /// `AVPlayerItem.error` or the notification's error.
    public let underlyingError: Error?
    /// HTTP status of the most recent HTTP failure in the item's error log, if any.
    public let httpStatusCode: Int?
    /// Snapshot of the item's error log at the moment of failure.
    public let errorLog: [KinescopePlaybackErrorLogEntry]
    /// `true` when the SDK's own `RepeatingMode` scheduled another attempt.
    public let willRetry: Bool

    public init(source: Source,
                underlyingError: Error?,
                errorLog: [KinescopePlaybackErrorLogEntry],
                willRetry: Bool) {
        self.source = source
        self.underlyingError = underlyingError
        self.errorLog = errorLog
        self.httpStatusCode = errorLog.reversed().lazy.compactMap(\.httpStatusCode).first
        self.willRetry = willRetry
    }

    init(source: Source, item: AVPlayerItem?, error: Error?, willRetry: Bool) {
        let events = item?.errorLog()?.events ?? []
        self.init(source: source,
                  underlyingError: error,
                  errorLog: events.map(KinescopePlaybackErrorLogEntry.init(event:)),
                  willRetry: willRetry)
    }

}

// MARK: - Private

private extension KinescopePlaybackErrorLogEntry {

    /// CoreMedia HLS codes that stand for HTTP statuses when the log carries no HTTP code.
    static let coreMediaHTTPCodes: [Int: Int] = [
        -12660: 403,
        -12938: 404
    ]

    static func httpStatus(inComment comment: String) -> Int? {
        guard let range = comment.range(of: #"HTTP\s*(\d{3})"#, options: .regularExpression) else {
            return nil
        }
        let code = Int(comment[range].filter(\.isNumber))
        return code.flatMap { (400..<600).contains($0) ? $0 : nil }
    }

}
