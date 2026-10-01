import XCTest
@testable import KinescopeSDK

/// The center play/pause control made like the Android SDK's `KinescopePlayPauseMorphView`: its glyph paths, an
/// 83 ms `fast_out_slow_in` morph, a 108% press zoom, replay after the end, shown while paused without the chrome.
final class KinescopePlayerAndroidPlayPauseTests: XCTestCase {

    private enum Constants {
        static let size = CGSize(width: 375, height: 211)
    }

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    // MARK: - Glyph paths

    func testPathsMatchTheAndroidDrawables() throws {
        let viewport = CGRect(x: 0, y: 0, width: 24, height: 24)
        let play = KinescopeGlyphPaths.playPause(playing: false, in: viewport).boundingBoxOfPath
        let pause = KinescopeGlyphPaths.playPause(playing: true, in: viewport).boundingBoxOfPath

        // ic_center_play_glyph: the triangle from x 1.52 to 22.7; ic_center_pause_glyph: bars 4…20 × 1.33…22.67.
        XCTAssertEqual(play.minX, 1.52, accuracy: 0.05)
        XCTAssertEqual(play.maxX, 22.7, accuracy: 0.05)
        XCTAssertEqual(pause.minX, 4, accuracy: 0.01)
        XCTAssertEqual(pause.maxX, 20, accuracy: 0.01)
        XCTAssertEqual(pause.minY, 1.333, accuracy: 0.01)
        XCTAssertEqual(pause.maxY, 22.666, accuracy: 0.01)
    }

    func testPlayAndPauseHaveTheSameElementsToMorph() {
        let rect = CGRect(x: 0, y: 0, width: 34, height: 34)
        let play = elements(of: KinescopeGlyphPaths.playPause(playing: false, in: rect))
        let pause = elements(of: KinescopeGlyphPaths.playPause(playing: true, in: rect))

        XCTAssertEqual(play, pause)
        XCTAssertEqual(play.count, 1 + 30 + 1 + 1 + 6 + 1)
    }

    func testReplayPathIsTheRewindDrawable() {
        let path = KinescopeGlyphPaths.replay(in: CGRect(x: 0, y: 0, width: 48, height: 48)).boundingBoxOfPath

        // ic_controls_rewind: a circular arrow about 35.5 of the 48-point viewport wide.
        XCTAssertEqual(path.width, 35.5, accuracy: 0.5)
        XCTAssertEqual(path.midY, 24, accuracy: 2)
    }

    // MARK: - Animation

    func testAndroidPresetFollowsKinescopePlayPauseMorphView() {
        let animation = KinescopePlayerTheme.PlayPauseAnimation.android
        var points: [Float] = [0, 0, 0, 0]
        animation.timingFunction.getControlPoint(at: 1, values: &points[0])
        animation.timingFunction.getControlPoint(at: 2, values: &points[2])

        XCTAssertEqual(animation.duration, 0.083)
        XCTAssertEqual(points, [0.4, 0, 0.2, 1], "fast_out_slow_in")
        XCTAssertEqual(animation.pressScale, 1.08)
        XCTAssertEqual(animation.pressDuration, 0.09)
        XCTAssertEqual(KinescopePlayerTheme.PlayButton.android.diameter, 56)
        XCTAssertEqual(KinescopePlayerTheme.PlayButton.android.glyphScale * 24, 34, accuracy: 0.001)
        XCTAssertTrue(KinescopePlayerTheme.PlayButton.android.showsWhilePaused)
    }

    func testMorphRunsWithTheAndroidPace() throws {
        let view = makePlayerView()
        let glyph = try XCTUnwrap(view.overlay?.playPauseGlyphView)

        view.overlay?.set(playing: true)

        let morph = try XCTUnwrap(glyph.layer.sublayers?.first?.animation(forKey: "morph") as? CABasicAnimation)
        XCTAssertEqual(morph.duration, 0.083)
        XCTAssertEqual(glyph.isPlaying, true)
    }

    // MARK: - Size and press

    func testChromeGlyphIsA34PointSquare() throws {
        let view = makePlayerView()
        let overlay = try XCTUnwrap(view.overlay)
        let glyph = try XCTUnwrap(overlay.playPauseGlyphView)
        view.layoutIfNeeded()

        XCTAssertEqual(glyph.frame.width, 34, accuracy: 0.5)
        XCTAssertEqual(overlay.playButtonFrameInOverlay.width, 56, accuracy: 0.5)
    }

    func testPressZoomsTheGlyphWithoutRecolouringIt() throws {
        let view = makePlayerView()
        let overlay = try XCTUnwrap(view.overlay)
        let glyph = try XCTUnwrap(overlay.playPauseGlyphView)
        let base = glyph.transform.a
        let tint = glyph.tintColor

        overlay.setPlayButtonPressed(true)
        XCTAssertEqual(glyph.transform.a, base * 1.08, accuracy: 0.001)
        XCTAssertEqual(glyph.tintColor, tint)

        overlay.setPlayButtonPressed(false)
        XCTAssertEqual(glyph.transform.a, base, accuracy: 0.001)
    }

    // MARK: - Visibility

    func testPausedButtonStaysWithoutTheChrome() throws {
        let view = makePlayerView()
        let overlay = try XCTUnwrap(view.overlay)
        overlay.isSelected = false

        overlay.set(playing: false)
        XCTAssertEqual(overlay.contentView.alpha, 1)
        XCTAssertEqual(overlay.contentView.backgroundColor, .clear, "no dimming without the chrome")

        overlay.set(playing: true)
        XCTAssertEqual(overlay.contentView.alpha, 0)

        overlay.isSelected = true
        XCTAssertEqual(overlay.contentView.alpha, 1)
        XCTAssertNotEqual(overlay.contentView.backgroundColor, .clear)
    }

    func testButtonHidesWhileLoading() throws {
        let view = makePlayerView()
        let overlay = try XCTUnwrap(view.overlay)
        let glyph = try XCTUnwrap(overlay.playPauseGlyphView)
        overlay.isSelected = true

        view.change(timeControlStatus: .waitingToPlayAtSpecifiedRate)
        XCTAssertEqual(glyph.alpha, 0)

        view.change(timeControlStatus: .paused)
        XCTAssertEqual(glyph.alpha, 1)
    }

    func testReplayAfterTheEnd() throws {
        let view = makePlayerView()
        let overlay = try XCTUnwrap(view.overlay)
        let glyph = try XCTUnwrap(overlay.playPauseGlyphView)
        overlay.set(playing: true)

        overlay.set(ended: true)
        overlay.set(playing: false)
        XCTAssertTrue(glyph.isReplay)
        XCTAssertEqual(overlay.contentView.alpha, 1, "replay shows without the chrome too")

        overlay.set(playing: true)
        XCTAssertFalse(glyph.isReplay)
        XCTAssertTrue(glyph.isPlaying)
    }

    // MARK: - Private

    private func elements(of path: CGPath) -> [Int32] {
        var types: [Int32] = []
        path.applyWithBlock { element in
            types.append(element.pointee.type.rawValue)
        }
        return types
    }

    private func makePlayerView() -> KinescopePlayerView {
        var theme = KinescopePlayerTheme(metrics: .player,
                                         playPauseAnimation: .android,
                                         chromePlayButton: .android)
        theme.metrics.playButtonGlyphScale = 36.0 / 24.0
        let controller = UIViewController()
        let window = UIWindow(frame: CGRect(origin: CGPoint(x: 0, y: 200), size: Constants.size))
        window.rootViewController = controller
        window.isHidden = false
        self.window = window

        let view = KinescopePlayerView(frame: CGRect(origin: .zero, size: Constants.size))
        view.setLayout(with: .themed(theme))
        controller.view.addSubview(view)
        view.overlay?.isHidden = false
        view.layoutIfNeeded()
        return view
    }

}
