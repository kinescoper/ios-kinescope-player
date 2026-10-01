import XCTest
@testable import KinescopeSDK

/// Renders the player chrome into PNG files for a visual review against Figma.
///
/// Not an assertion test: it runs only when `KINESCOPE_SNAPSHOT_DIR` is set (pass it to `xcodebuild test` as
/// `TEST_RUNNER_KINESCOPE_SNAPSHOT_DIR=<dir>`), otherwise it is skipped.
final class KinescopePlayerViewSnapshotRenderer: XCTestCase {

    private enum Constants {
        static let sizes: [(name: String, size: CGSize)] = [
            ("375", CGSize(width: 375, height: 211)),
            ("343", CGSize(width: 343, height: 193))
        ]
        static let options: [KinescopePlayerOption] = [.subtitles, .airPlay, .settings, .pip, .fullscreen, .more]
    }

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    func testRenderDefault() throws {
        let directory = try outputDirectory()
        for (name, size) in Constants.sizes {
            try render(configuration: .default, size: size, into: directory, prefix: "default-\(name)")
        }
    }

    func testRenderThemed() throws {
        let directory = try outputDirectory()
        for (name, size) in Constants.sizes {
            try render(configuration: .themed(Self.appLikeTheme), size: size, into: directory, prefix: "themed-\(name)")
        }
    }

    /// The themed chrome driven by a real player on the loopback HLS fixture (AES-128, two 1-second segments):
    /// the SDK itself lays out the options, the time and the timeline. Layers are rendered without the video
    /// picture, so the frame stays black.
    func testRenderThemedWithLocalHLS() throws {
        let directory = try outputDirectory()
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
            let name = String(request.path.dropFirst())
            guard !name.contains("/"), let body = try? Data(contentsOf: fixtures.appendingPathComponent(name)) else {
                return .notFound()
            }
            let contentType = name.hasSuffix(".m3u8") ? "application/vnd.apple.mpegurl"
                : name.hasSuffix(".ts") ? "video/mp2t" : "application/octet-stream"
            return .init(status: 200, contentType: contentType, body: body)
        }
        try server.start()
        defer { server.stop() }

        let dependencies = HLSDependencies()
        let hlsLink = server.baseURL.appendingPathComponent("master.m3u8").absoluteString
        dependencies.inspectorMock.videoSuccessMock["snapshot"] = .stub(id: "snapshot", hlsLink: hlsLink)
        let player = KinescopeVideoPlayer(config: .init(videoId: "snapshot",
                                                        repeatingMode: .init(attempts: 0, interval: .never)),
                                          dependencies: dependencies)
        player.strategy.player.isMuted = true
        player.strategy.player.automaticallyWaitsToMinimizeStalling = false

        let view = makeView(configuration: .themed(Self.appLikeTheme), size: Constants.sizes[0].size)
        view.previewView.image = nil
        view.backgroundColor = .black
        player.attach(view: view)
        defer {
            player.stop()
            player.detach(view: view)
        }

        player.prepare()
        let ready = expectation(for: NSPredicate { _, _ in player.strategy.player.currentItem?.status == .readyToPlay },
                                evaluatedWith: nil)
        wait(for: [ready], timeout: 30)
        view.showOverlay(true)
        try save(view, to: directory.appendingPathComponent("hls-themed-375-1-ready.png"))

        player.play()
        let playing = expectation(for: NSPredicate { _, _ in view.controlPanel?.isHidden == false }, evaluatedWith: nil)
        wait(for: [playing], timeout: 30)
        player.pause()
        player.seek(to: 0.9)
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        view.showOverlay(true)
        try save(view, to: directory.appendingPathComponent("hls-themed-375-2-playing.png"))
    }

    private struct HLSDependencies: KinescopePlayerDependencies {
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

    /// A theme shaped like the Kinescope app's: Figma player tokens and `Metrics.compact`. Glyphs come from a
    /// `m/<name>` image of the test bundle when one is there (design system icons added for a local review
    /// run only), else from SF Symbols.
    static var appLikeTheme: KinescopePlayerTheme {
        let accent = UIColor(red: 0x61 / 255, green: 0x61 / 255, blue: 0xfc / 255, alpha: 1)
        let white32 = UIColor.white.withAlphaComponent(0.32)
        let names: [KinescopePlayerIcon: (ds: String, symbol: String)] = [
            .play: ("play-player", "play.fill"),
            .pause: ("pause-player", "pause.fill"),
            .fastForward: ("rewind-plus", "goforward.10"),
            .fastBackward: ("rewind-minus", "gobackward.10"),
            .more: ("dots-horizontal", "ellipsis"),
            .fullscreen: ("fullscreen-player", "arrow.up.left.and.arrow.down.right"),
            .exitFullscreen: ("exit-fullscreen-player", "arrow.down.right.and.arrow.up.left"),
            .settings: ("settings-player", "gearshape"),
            .airPlay: ("airplay", "airplayvideo"),
            .subtitles: ("transcription-off", "captions.bubble"),
            .subtitlesOn: ("transcription-on", "captions.bubble.fill"),
            .pip: ("mini-player", "pip"),
            .download: ("download", "arrow.down.to.line"),
            .menuBack: ("arrow-back", "chevron.left"),
            .menuClose: ("close", "xmark"),
            .menuDisclosure: ("arrow-forward", "chevron.right"),
            .menuCheckmark: ("check", "checkmark")
        ]
        let icons = KinescopePlayerTheme.Icons { icon in
            guard let name = names[icon] else {
                return nil
            }
            return UIImage(named: "m/\(name.ds)", in: Bundle.module, compatibleWith: nil)
                ?? UIImage(systemName: name.symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: 18))
        }
        let colors = KinescopePlayerTheme.Colors(
            icon: .white,
            iconPressed: accent,
            text: .white,
            timelineTrack: white32,
            timelineBuffered: white32,
            timelineProgress: accent,
            timelineThumb: accent,
            playButtonBackground: accent.withAlphaComponent(0.64),
            playButtonBackgroundPressed: accent,
            playButtonIcon: .white,
            overlayDim: UIColor.black.withAlphaComponent(0.16),
            title: .white
        )
        return KinescopePlayerTheme(icons: icons, colors: colors, metrics: .compact)
    }

    // MARK: - Private

    private func outputDirectory() throws -> URL {
        guard let path = ProcessInfo.processInfo.environment["KINESCOPE_SNAPSHOT_DIR"], !path.isEmpty else {
            throw XCTSkip("KINESCOPE_SNAPSHOT_DIR is not set")
        }
        let url = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func render(configuration: KinescopePlayerViewConfiguration,
                        size: CGSize,
                        into directory: URL,
                        prefix: String) throws {
        let view = makeView(configuration: configuration, size: size)

        // Paused before the first play: the overlay with the play button.
        view.stopLoader()
        view.overlay?.set(playing: false)
        view.didTap(isSelected: false)
        view.controlPanel?.isHidden = true
        view.previewView.isHidden = false
        try save(view, to: directory.appendingPathComponent("\(prefix)-1-paused.png"))

        // Playing with the chrome shown: collapsed control bar.
        view.change(timeControlStatus: .playing)
        view.overlay?.isSelected = true
        view.controlPanel?.alpha = 1
        view.controlPanel?.isHidden = false
        view.controlPanel?.set(live: nil)
        view.controlPanel?.setIndicator(to: 769)
        view.layoutIfNeeded()
        view.controlPanel?.setBufferred(progress: 0.8)
        view.controlPanel?.setTimeline(to: 0.55)
        try save(view, to: directory.appendingPathComponent("\(prefix)-2-playing.png"))

        // The three dots tapped: every option.
        view.controlPanel?.expanded = true
        try save(view, to: directory.appendingPathComponent("\(prefix)-3-expanded.png"))

        // The play/pause button and the three dots held down.
        view.controlPanel?.expanded = false
        view.overlay?.setPlayButtonPressed(true)
        let more = Self.optionButtons(in: view).first { $0.option == .more }
        more?.isHighlighted = true
        try save(view, to: directory.appendingPathComponent("\(prefix)-4-pressed.png"))
        more?.isHighlighted = false
        view.overlay?.setPlayButtonPressed(false)
    }

    private func makeView(configuration: KinescopePlayerViewConfiguration, size: CGSize) -> KinescopePlayerView {
        let controller = UIViewController()
        controller.view.backgroundColor = .black
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = controller
        window.isHidden = false
        self.window = window

        let view = KinescopePlayerView(frame: CGRect(origin: .zero, size: size))
        view.setLayout(with: configuration)
        view.previewView.image = Self.backdrop(size: size)
        view.previewView.contentMode = .scaleAspectFill
        controller.view.addSubview(view)
        view.set(options: Constants.options)
        view.layoutIfNeeded()
        return view
    }

    private func save(_ view: UIView, to url: URL) throws {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        // A hostless test process has no on-screen window, so `drawHierarchy` draws nothing; render the layers.
        let image = UIGraphicsImageRenderer(bounds: view.bounds, format: format).image { context in
            view.layer.render(in: context.cgContext)
        }
        try XCTUnwrap(image.pngData()).write(to: url)
    }

    private static func optionButtons(in view: UIView) -> [OptionButton] {
        view.subviews.flatMap { subview -> [OptionButton] in
            (subview as? OptionButton).map { [$0] } ?? optionButtons(in: subview)
        }
    }

    /// A stand-in for a video frame: a mid-tone gradient, so white chrome and dim overlays stay readable.
    private static func backdrop(size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            let colors = [UIColor(red: 0.35, green: 0.45, blue: 0.55, alpha: 1).cgColor,
                          UIColor(red: 0.55, green: 0.4, blue: 0.35, alpha: 1).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])
            guard let gradient else {
                return
            }
            context.cgContext.drawLinearGradient(gradient,
                                                 start: .zero,
                                                 end: CGPoint(x: size.width, y: size.height),
                                                 options: [])
        }
    }

}
