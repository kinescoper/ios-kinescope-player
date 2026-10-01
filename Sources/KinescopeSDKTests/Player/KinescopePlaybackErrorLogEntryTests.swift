import XCTest
@testable import KinescopeSDK

final class KinescopePlaybackErrorLogEntryTests: XCTestCase {

    func testHTTPStatusIsTakenFromCodeCommentOrCoreMediaCode() {
        XCTAssertEqual(entry(code: 403, comment: nil).httpStatusCode, 403)
        XCTAssertEqual(entry(code: -12938, comment: "HTTP 404: File Not Found").httpStatusCode, 404)
        XCTAssertEqual(entry(code: -12660, comment: nil).httpStatusCode, 403)
        XCTAssertNil(entry(code: -12645, comment: "No response for map in 10s").httpStatusCode)
    }

    func testFailureTakesLatestHTTPStatusFromLog() {
        let failure = KinescopePlaybackFailure(source: .itemStatus,
                                               underlyingError: nil,
                                               errorLog: [entry(code: 404, comment: nil),
                                                          entry(code: -12645, comment: nil),
                                                          entry(code: 503, comment: nil),
                                                          entry(code: -1, comment: nil)],
                                               willRetry: false)
        XCTAssertEqual(failure.httpStatusCode, 503)
    }

    private func entry(code: Int, comment: String?) -> KinescopePlaybackErrorLogEntry {
        .init(date: nil, uri: nil, serverAddress: nil, errorStatusCode: code, errorDomain: "CoreMediaErrorDomain", errorComment: comment)
    }

}
