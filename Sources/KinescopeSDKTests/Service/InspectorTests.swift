import XCTest
@testable import KinescopeSDK

final class InspectorTests: XCTestCase {

    func testHTTPErrorsAreClassified() {
        let cases: [(Int, Int?)] = [(404, 404), (403, 403), (401, 401), (500, 500)]
        for (status, expected) in cases {
            let error = inspect(failingWith: KinescopeHTTPError(statusCode: status, url: nil))
            XCTAssertEqual(error?.httpStatusCode, expected)
        }
        if case .notFound = inspect(failingWith: KinescopeHTTPError(statusCode: 404, url: nil)) {} else {
            XCTFail("404 must map to .notFound")
        }
        if case .denied = inspect(failingWith: KinescopeHTTPError(statusCode: 403, url: nil)) {} else {
            XCTFail("403 must map to .denied")
        }
    }

    func testTransportErrorHasNoHTTPStatus() {
        let error = inspect(failingWith: URLError(.notConnectedToInternet))
        XCTAssertNil(error?.httpStatusCode)
    }

    func testRefererIsPassedToService() {
        let service = RecordingVideoService()
        let inspector = Inspector(videosService: service)

        inspector.video(id: "1", referer: "https://example.org/", onSuccess: { _ in }, onError: { _ in })
        inspector.video(id: "2", onSuccess: { _ in }, onError: { _ in })

        XCTAssertEqual(service.referers, ["https://example.org/", nil])
    }

    // MARK: - Private

    private final class RecordingVideoService: VideosService {
        private(set) var referers = [String?]()

        func getVideo(by id: String, referer: String?, completion: @escaping (Result<KinescopeVideo, Error>) -> Void) {
            referers.append(referer)
            completion(.success(.stub(id: id)))
        }
    }

    private func inspect(failingWith error: Error) -> KinescopeInspectError? {
        let service = VideoServiceMock()
        service.singleVideoMock["id"] = .failure(error)
        var result: KinescopeInspectError?
        Inspector(videosService: service).video(id: "id", onSuccess: { _ in }, onError: { result = $0 })
        return result
    }

}
