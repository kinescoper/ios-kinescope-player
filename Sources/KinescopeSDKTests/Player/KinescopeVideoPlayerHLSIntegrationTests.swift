import AVFoundation
import XCTest
@testable import KinescopeSDK

/// Plays a real AES-128 HLS stream from a loopback server through `KinescopeVideoPlayer`.
final class KinescopeVideoPlayerHLSIntegrationTests: XCTestCase {

    private enum Constants {
        static let videoId = "integration"
        static let referer = "https://referer.example/"
        static let timeout: TimeInterval = 30
    }

    private struct Dependencies: KinescopePlayerDependencies {
        let inspectorMock = KinescopeInspectableMock()
        let strategy = SequentialPlayingStrategy()

        var drmFactory: DataProtectionHandlerFactory { DataProtectionHandlerFactoryStub() }
        var inspector: KinescopeInspectable { inspectorMock }
        var assetDownloader: KinescopeAssetDownloadable { KinescopeAssetDownloadableMock() }
        var attachmentDownloader: KinescopeAttachmentDownloadable { KinescopeAttachmentDownloaderMock() }

        func provide(for config: KinescopePlayerConfig) -> PlayingStrategy {
            strategy
        }
    }

    private final class DelegateSpy: KinescopeVideoPlayerDelegate {
        var onReady: (() -> Void)?
        var onFinish: (() -> Void)?
        var onFailure: ((KinescopePlaybackFailure) -> Void)?
        var onErrorLogEntry: (() -> Void)?
        private(set) var errorLogEntries = [KinescopePlaybackErrorLogEntry]()

        func player(changedItemStatusTo status: AVPlayerItem.Status) {
            if status == .readyToPlay {
                onReady?()
            }
        }

        func playerDidFinish() {
            onFinish?()
        }

        func player(didFailWith failure: KinescopePlaybackFailure) {
            onFailure?(failure)
        }

        func player(didReceiveErrorLogEntry entry: KinescopePlaybackErrorLogEntry) {
            errorLogEntries.append(entry)
            onErrorLogEntry?()
        }

        func player(didSelectCustomOptionWith optionId: AnyHashable, anchoredAt view: UIView) { }
    }

    private var server: LocalHTTPServer?
    private var player: KinescopeVideoPlayer?
    private var view: KinescopePlayerView?
    private let delegate = DelegateSpy()

    override func tearDown() {
        if let view {
            player?.detach(view: view)
        }
        player?.stop()
        server?.stop()
        player = nil
        server = nil
        view = nil
        super.tearDown()
    }

    func testRefererReachesEveryHLSRequest() throws {
        let server = try makeServer(forbidSegments: false)
        let player = makePlayer(server: server)

        let ready = expectation(description: "ready")
        ready.assertForOverFulfill = false
        delegate.onReady = { ready.fulfill() }

        player.prepare()
        wait(for: [ready], timeout: Constants.timeout)

        XCTAssertEqual(player.duration ?? 0, 2, accuracy: 0.1)
        XCTAssertEqual(player.currentTime, 0, accuracy: 0.01)

        // The playback clock does not advance in a hostless test process, so segments are pulled by buffering.
        player.play()
        let buffered = expectation(for: NSPredicate { _, _ in
            Set(server.requests.map(\.path)).contains("/segment1.ts")
        }, evaluatedWith: nil)
        wait(for: [buffered], timeout: Constants.timeout)
        let requested = Set(server.requests.map(\.path))
        XCTAssertTrue(requested.isSuperset(of: ["/master.m3u8", "/variant.m3u8", "/key.bin", "/segment0.ts", "/segment1.ts"]),
                      "requested: \(requested)")
        for request in server.requests {
            XCTAssertEqual(request.header("Referer"), Constants.referer, "no Referer on \(request.path)")
        }
    }

    func testFinishIsReportedOnlyForOwnItem() throws {
        let server = try makeServer(forbidSegments: false)
        let player = makePlayer(server: server)
        var finishCount = 0
        delegate.onFinish = { finishCount += 1 }

        player.prepare()
        let item = try XCTUnwrap(player.strategy.player.currentItem)

        let foreignItem = AVPlayerItem(url: server.baseURL.appendingPathComponent("master.m3u8"))
        NotificationCenter.default.post(name: AVPlayerItem.didPlayToEndTimeNotification, object: foreignItem)
        XCTAssertEqual(finishCount, 0)

        NotificationCenter.default.post(name: AVPlayerItem.didPlayToEndTimeNotification, object: item)
        XCTAssertEqual(finishCount, 1)
    }

    func testSegmentFailureIsReportedWithHTTPStatus() throws {
        let server = try makeServer(forbidSegments: true)
        let player = makePlayer(server: server)

        let failed = expectation(description: "failed")
        failed.assertForOverFulfill = false
        var failure: KinescopePlaybackFailure?
        delegate.onFailure = {
            failure = $0
            failed.fulfill()
        }

        let logged = expectation(description: "error log entry")
        logged.assertForOverFulfill = false
        delegate.onErrorLogEntry = { logged.fulfill() }

        player.play()
        wait(for: [failed, logged], timeout: Constants.timeout)

        XCTAssertEqual(failure?.httpStatusCode, 403, "error log: \(String(describing: failure?.errorLog))")
        XCTAssertEqual(failure?.willRetry, false)
        XCTAssertTrue(delegate.errorLogEntries.contains { $0.httpStatusCode == 403 })
    }

    /// The owner's P0: in full screen the play/pause button was missing and, once the control bar hid, a tap did not
    /// bring it back. The full screen view is attached to a player that is already playing, and its overlay (the
    /// play/pause button and the tap target) stayed hidden because no status change came to unhide it.
    func testFullscreenViewOfAPlayingPlayerShowsControlsAndTakesTaps() throws {
        let server = try makeServer(forbidSegments: false)
        let player = makePlayer(server: server)
        let inlineView = try XCTUnwrap(view)

        let ready = expectation(description: "ready")
        ready.assertForOverFulfill = false
        delegate.onReady = { ready.fulfill() }
        player.prepare()
        wait(for: [ready], timeout: Constants.timeout)
        player.play()
        let playing = expectation(for: NSPredicate { _, _ in player.strategy.player.timeControlStatus == .playing },
                                  evaluatedWith: nil)
        wait(for: [playing], timeout: Constants.timeout)

        // What `didPresentFullscreen` does: the inline view is detached, the controller attaches its own view.
        player.detach(view: inlineView)
        let controller = KinescopeFullscreenViewController(
            player: player,
            config: .init(orientation: .landscapeRight, orientationMask: .landscape, backgroundColor: .black),
            playerViewConfig: .default
        )
        controller.loadViewIfNeeded()
        controller.view.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        controller.viewDidAppear(false)
        let fullscreenView = try XCTUnwrap(controller.view.subviews.compactMap { $0 as? KinescopePlayerView }.first)
        defer { player.detach(view: fullscreenView) }
        let overlay = try XCTUnwrap(fullscreenView.overlay)
        let controlPanel = try XCTUnwrap(fullscreenView.controlPanel)

        XCTAssertFalse(overlay.isHidden, "no play/pause button and no tap target")
        XCTAssertFalse(controlPanel.isHidden)
        XCTAssertTrue(controlPanel.optionsMenu.options.contains(.fullscreen), "no way out of full screen")

        // A tap hides the chrome, the next one brings it back.
        fullscreenView.showOverlay(true)
        XCTAssertTrue(overlay.isSelected)
        fullscreenView.showOverlay(false)
        XCTAssertFalse(overlay.isSelected)
        XCTAssertFalse(overlay.isHidden, "a hidden overlay takes no taps")
        fullscreenView.showOverlay(true)
        XCTAssertTrue(overlay.isSelected)
        XCTAssertFalse(controlPanel.isHidden)
    }

    // MARK: - Private

    private func makeServer(forbidSegments: Bool) throws -> LocalHTTPServer {
        let fixtures = try XCTUnwrap(Bundle.module.url(forResource: "HLS", withExtension: nil, subdirectory: "Fixtures"))
        let master = """
        #EXTM3U
        #EXT-X-STREAM-INF:BANDWIDTH=200000,RESOLUTION=64x64,CODECS="avc1.42c00a"
        variant.m3u8

        """
        let server = try LocalHTTPServer { request in
            if request.path == "/master.m3u8" {
                return .init(status: 200, contentType: "application/vnd.apple.mpegurl", body: Data(master.utf8))
            }
            if forbidSegments && request.path.hasSuffix(".ts") {
                return .init(status: 403, contentType: "text/plain", body: Data())
            }
            let name = String(request.path.dropFirst())
            guard !name.contains("/"), let body = try? Data(contentsOf: fixtures.appendingPathComponent(name)) else {
                return .notFound()
            }
            let contentType = name.hasSuffix(".m3u8") ? "application/vnd.apple.mpegurl"
                : name.hasSuffix(".ts") ? "video/mp2t" : "application/octet-stream"
            return .init(status: 200, contentType: contentType, body: body)
        }
        try server.start()
        self.server = server
        return server
    }

    private func makePlayer(server: LocalHTTPServer) -> KinescopeVideoPlayer {
        let dependencies = Dependencies()
        let hlsLink = server.baseURL.appendingPathComponent("master.m3u8").absoluteString
        dependencies.inspectorMock.videoSuccessMock[Constants.videoId] = .stub(id: Constants.videoId, hlsLink: hlsLink)

        let player = KinescopeVideoPlayer(config: .init(videoId: Constants.videoId,
                                                        repeatingMode: .init(attempts: 0, interval: .never),
                                                        referer: Constants.referer),
                                          dependencies: dependencies)
        player.strategy.player.isMuted = true
        // A hostless test process keeps the player in `waitingToMinimizeStalls` even with the whole stream buffered.
        player.strategy.player.automaticallyWaitsToMinimizeStalling = false
        let view = KinescopePlayerView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        player.setDelegate(delegate: delegate)
        player.attach(view: view)
        self.player = player
        self.view = view
        return player
    }

}
