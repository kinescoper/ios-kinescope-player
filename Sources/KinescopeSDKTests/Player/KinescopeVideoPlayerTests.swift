//
//  KinescopeVideoPlayerTests.swift
//  KinescopeSDKTests
//
//  Created by Никита Коробейников on 29.03.2021.
//

import XCTest
@testable import KinescopeSDK

final class KinescopeVideoPlayerTests: XCTestCase {

    private enum Constants {
        static let hlsStub = "https://example.com/playlist.m3u8"
        static let videoId = "123"
        static let videoStub: KinescopeVideo = .stub(id: videoId, hlsLink: hlsStub)
    }

    var player: KinescopeVideoPlayer?
    var inspector: KinescopeInspectableMock?
    var downloader: KinescopeAssetDownloadableMock?
    var attachmentDownloader: KinescopeAttachmentDownloaderMock?
    var strategy: PlayingStrategyMock?

    override func setUp() {
        super.setUp()

        let inspector = KinescopeInspectableMock()
        let downloader = KinescopeAssetDownloadableMock()
        let strategy = PlayingStrategyMock()
        let attachmentDownloader = KinescopeAttachmentDownloaderMock()

        let dependencies = KinescopeVideoPlayerDependenciesMock(drmFactoryStub: .init(),
                                                                inspectorMock: inspector,
                                                                assetDownloaderMock: downloader,
                                                                strategyMock: strategy,
                                                                attachmentDownloaderMock: attachmentDownloader)

        self.player = KinescopeVideoPlayer(config: .init(videoId: Constants.videoId),
                                           dependencies: dependencies)

        self.inspector = inspector
        self.strategy = strategy
        self.attachmentDownloader = attachmentDownloader
    }

    override func tearDown() {
        super.tearDown()

        inspector = nil
        strategy = nil
    }

    func testPlayInitiateLoadingAndDelegateToStrategy() {

        // given

        inspector?.videoSuccessMock[Constants.videoId] = Constants.videoStub

        // when

        player?.play()

        // then

        XCTAssertEqual(inspector?.videoRequests.count, 1)
        XCTAssertEqual(strategy?.bindItems.count, 1)
        XCTAssertEqual(strategy?.playCalledCount, 1)
        XCTAssertEqual(strategy?.pauseCalledCount, 0)
        XCTAssertEqual(strategy?.unbindCalledCount, 0)

    }

    func testPauseDelegateToStrategy() {

        // when

        player?.pause()

        // then

        XCTAssertEqual(strategy?.bindItems.count, 0)
        XCTAssertEqual(strategy?.playCalledCount, 0)
        XCTAssertEqual(strategy?.pauseCalledCount, 1)
        XCTAssertEqual(strategy?.unbindCalledCount, 0)
    }

    func testStopDelegateToStrategy() {

        // when

        player?.stop()

        // then

        XCTAssertEqual(strategy?.bindItems.count, 0)
        XCTAssertEqual(strategy?.playCalledCount, 0)
        XCTAssertEqual(strategy?.pauseCalledCount, 1)
        XCTAssertEqual(strategy?.unbindCalledCount, 1)

    }

    func testSelectQualityDelegateToStrategy() {
        // given

        let quality: KinescopeVideoQuality = .auto(hlsLink: Constants.hlsStub)

        // when

        player?.select(quality: quality)

        // then

        XCTAssertEqual(strategy?.bindItems.count, 1)
        XCTAssertEqual(strategy?.playCalledCount, 0)
        XCTAssertEqual(strategy?.pauseCalledCount, 0)
        XCTAssertEqual(strategy?.unbindCalledCount, 0)
    }

    // MARK: - Prepare (0.3.0-kinescoper.1)

    func testPrepareLoadsAndBindsWithoutPlaying() {
        // given
        inspector?.videoSuccessMock[Constants.videoId] = Constants.videoStub

        // when
        player?.prepare()

        // then
        XCTAssertEqual(inspector?.videoRequests.count, 1)
        XCTAssertEqual(strategy?.bindItems.count, 1)
        XCTAssertEqual(strategy?.playCalledCount, 0)
    }

    func testPlayAfterPrepareKeepsBoundItem() {
        // given
        inspector?.videoSuccessMock[Constants.videoId] = Constants.videoStub
        player?.prepare()

        // when
        player?.play()

        // then
        XCTAssertEqual(inspector?.videoRequests.count, 1)
        XCTAssertEqual(strategy?.bindItems.count, 1)
        XCTAssertEqual(strategy?.playCalledCount, 1)
    }

    func testRepeatedPrepareWhileLoadingSendsOneRequest() {
        // given
        inspector?.videoSuccessMock[Constants.videoId] = Constants.videoStub
        inspector?.defersCompletion = true

        // when
        player?.prepare()
        player?.prepare()
        inspector?.completePending()

        // then
        XCTAssertEqual(inspector?.videoRequests.count, 1)
        XCTAssertEqual(strategy?.bindItems.count, 1)
        XCTAssertEqual(strategy?.playCalledCount, 0)
    }

    func testPlayWhilePreparingStartsOnceLoaded() {
        // given
        inspector?.videoSuccessMock[Constants.videoId] = Constants.videoStub
        inspector?.defersCompletion = true

        // when
        player?.prepare()
        player?.play()

        // then
        XCTAssertEqual(strategy?.playCalledCount, 0)

        // when
        inspector?.completePending()

        // then
        XCTAssertEqual(inspector?.videoRequests.count, 1)
        XCTAssertEqual(strategy?.bindItems.count, 1)
        XCTAssertEqual(strategy?.playCalledCount, 1)
    }

    func testPrepareFailureReportsErrorAndAllowsReload() {
        // given
        let delegate = DelegateSpy()
        player?.setDelegate(delegate: delegate)
        inspector?.videoErrorMock[Constants.videoId] = .unknown(KinescopeHTTPError(statusCode: 401, url: nil))

        // when
        player?.prepare()

        // then
        XCTAssertEqual(delegate.loadErrors.count, 1)
        XCTAssertEqual((delegate.loadErrors.first as? KinescopeInspectError)?.httpStatusCode, 401)
        XCTAssertEqual(strategy?.bindItems.count, 0)

        // when
        inspector?.videoErrorMock[Constants.videoId] = nil
        inspector?.videoSuccessMock[Constants.videoId] = Constants.videoStub
        player?.prepare()

        // then
        XCTAssertEqual(inspector?.videoRequests.count, 2)
        XCTAssertEqual(strategy?.bindItems.count, 1)
    }

    func testPlayAfterStopRebindsItem() {
        // given
        inspector?.videoSuccessMock[Constants.videoId] = Constants.videoStub
        player?.play()

        // when
        player?.stop()
        player?.play()

        // then
        XCTAssertEqual(inspector?.videoRequests.count, 1)
        XCTAssertEqual(strategy?.bindItems.count, 2)
    }

    // MARK: - Referer (0.3.0-kinescoper.1)

    func testConfigRefererIsPassedToVideoRequest() {
        // given
        let player = KinescopeVideoPlayer(config: .init(videoId: Constants.videoId, referer: "https://example.org/"),
                                          dependencies: makeDependencies())

        // when
        player.prepare()

        // then
        XCTAssertEqual(inspector?.videoReferers, ["https://example.org/"])
    }

    // MARK: - Position (0.3.0-kinescoper.1)

    func testPositionBeforeItemIsReady() {
        // when
        player?.seek(to: 42)

        // then
        XCTAssertEqual(player?.currentTime, 0)
        XCTAssertNil(player?.duration)
        XCTAssertEqual(strategy?.bindItems.count, 0)
    }

    func testPlayerIsReleased() {
        weak var released: KinescopeVideoPlayer?
        autoreleasepool {
            let player = KinescopeVideoPlayer(config: .init(videoId: Constants.videoId),
                                              dependencies: makeDependencies())
            player.prepare()
            released = player
        }
        XCTAssertNil(released)
    }

    // MARK: - Private

    private final class DelegateSpy: KinescopeVideoPlayerDelegate {
        private(set) var loadErrors = [Error]()

        func playerDidLoadVideo(error: Error?) {
            if let error {
                loadErrors.append(error)
            }
        }

        func player(didSelectCustomOptionWith optionId: AnyHashable, anchoredAt view: UIView) { }
    }

    private func makeDependencies() -> KinescopeVideoPlayerDependenciesMock {
        KinescopeVideoPlayerDependenciesMock(drmFactoryStub: .init(),
                                             inspectorMock: inspector ?? .init(),
                                             assetDownloaderMock: .init(),
                                             strategyMock: strategy ?? .init(),
                                             attachmentDownloaderMock: .init())
    }
}
