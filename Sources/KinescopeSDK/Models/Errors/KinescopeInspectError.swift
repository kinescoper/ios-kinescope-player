//
//  KinescopeInspectError.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 23.03.2021.
//

/// Enumeration of possible negative cases while downloading content
public enum KinescopeInspectError: Error {

    /// Network problems
    case network
    /// Video not found
    case notFound
    /// Denied by dashboard or by system when saving in local storage
    case denied
    /// Unexpected error
    case unknown(Error)

}

public extension KinescopeInspectError {

    /// HTTP status code behind the error, if the failure was a non-2xx response.
    ///
    /// Added in 0.3.0-kinescoper.1.
    var httpStatusCode: Int? {
        switch self {
        case .notFound:
            return 404
        case .denied:
            return 403
        case .network:
            return nil
        case .unknown(let error):
            return (error as? KinescopeHTTPError)?.statusCode
        }
    }

}
