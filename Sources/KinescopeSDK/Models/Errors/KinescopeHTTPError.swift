//
//  KinescopeHTTPError.swift
//  KinescopeSDK
//

import Foundation

/// Non-2xx HTTP response from a Kinescope endpoint.
///
/// Added in 0.3.0-kinescoper.1. Delivered either directly or wrapped into
/// `KinescopeInspectError.unknown(_:)`; use `KinescopeInspectError.httpStatusCode` to read the code.
public struct KinescopeHTTPError: Error, Equatable {

    /// HTTP status code of the response.
    public let statusCode: Int
    /// URL of the failed request.
    public let url: URL?
    /// `error.message` from the response body, if the body was a Kinescope error object.
    public let message: String?
    /// `error.detail` from the response body, if present.
    public let detail: String?

    public init(statusCode: Int, url: URL?, message: String? = nil, detail: String? = nil) {
        self.statusCode = statusCode
        self.url = url
        self.message = message
        self.detail = detail
    }
}
