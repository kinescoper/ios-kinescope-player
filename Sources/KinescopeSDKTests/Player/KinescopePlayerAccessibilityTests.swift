import XCTest
@testable import KinescopeSDK

/// VoiceOver labels, tap targets, the themed loader and the play/pause morph.
final class KinescopePlayerAccessibilityTests: XCTestCase {

    private enum Constants {
        static let size = CGSize(width: 343, height: 193)
        static let options: [KinescopePlayerOption] = [.subtitles, .airPlay, .settings, .pip, .fullscreen, .more]
    }

    // MARK: - Labels

    func testDefaultLabelsAreTheSDKStrings() {
        let labels = KinescopePlayerTheme.AccessibilityLabels.default

        XCTAssertEqual(labels.play, "Play")
        XCTAssertEqual(labels.pause, "Pause")
        XCTAssertEqual(labels.more, "More options")
        XCTAssertEqual(labels.fullscreen, "Full screen")
        XCTAssertEqual(labels.exitFullscreen, "Exit full screen")
        XCTAssertEqual(labels.settings, "Settings")
        XCTAssertEqual(labels.pip, "Picture in Picture")
        XCTAssertEqual(labels.airPlay, "AirPlay")
        XCTAssertEqual(labels.timeline, "Playback position")
        XCTAssertEqual(labels.menuBack, "Back")
        XCTAssertEqual(labels.menuClose, "Close")
        XCTAssertEqual(labels.fastForward, "Skip forward")
        XCTAssertEqual(labels.fastBackward, "Skip back")
    }

    func testEveryOptionCarriesTheThemeLabel() throws {
        let view = makePlayerView(theme: makeTheme())
        let panel = try XCTUnwrap(view.controlPanel)
        panel.expanded = true
        panel.layoutIfNeeded()

        let labels = panel.optionsMenu.allSubviews { $0 is OptionButton }.map { ($0 as? OptionButton)?.accessibilityLabel }
        XCTAssertEqual(labels, ["Subs", "Gear", "PiP", "Full", "More"])
        let airPlay = try XCTUnwrap(panel.optionsMenu.firstSubview { $0 is AirPlayOptionControl })
        XCTAssertEqual(airPlay.allSubviews { $0.accessibilityLabel == "Cast" }.count, 1, "the route picker is labelled")
    }

    func testFullscreenOptionIsLabelledToLeaveInFullScreen() throws {
        let view = KinescopePlayerView(frame: CGRect(origin: .zero, size: Constants.size))
        view.isFullscreenHost = true
        view.setLayout(with: .themed(makeTheme()))
        view.set(options: [.fullscreen, .more])

        let button = try XCTUnwrap(view.controlPanel?.optionsMenu.firstSubview { ($0 as? OptionButton)?.option == .fullscreen })
        XCTAssertEqual(button.accessibilityLabel, "Leave")
    }

    func testPlayButtonIsAButtonWhoseLabelFollowsThePlayback() throws {
        let delegate = OverlayDelegateSpy()
        let theme = makeTheme()
        let overlay = PlayerOverlayView(config: try XCTUnwrap(KinescopePlayerViewConfiguration.themed(theme).overlay),
                                        theme: theme,
                                        delegate: delegate)
        overlay.frame = CGRect(origin: .zero, size: Constants.size)
        overlay.layoutIfNeeded()

        let element = try XCTUnwrap(overlay.accessibilityElements?.first as? UIAccessibilityElement)
        XCTAssertEqual(overlay.accessibilityElements?.count, 1)
        XCTAssertTrue(element.accessibilityTraits.contains(.button))
        XCTAssertEqual(element.accessibilityLabel, "Go")
        XCTAssertEqual(element.accessibilityFrameInContainerSpace.width, 64, accuracy: 0.001)
        XCTAssertEqual(element.accessibilityFrameInContainerSpace.height, 64, accuracy: 0.001)
        XCTAssertEqual(element.accessibilityCustomActions?.map(\.name), ["Ahead", "Behind"])

        XCTAssertTrue(element.accessibilityActivate())
        XCTAssertEqual(delegate.calls, ["play"])
        XCTAssertEqual(element.accessibilityLabel, "Stop")

        overlay.set(playing: false)
        XCTAssertEqual(element.accessibilityLabel, "Go")
        let forward = try XCTUnwrap(element.accessibilityCustomActions?.first)
        _ = forward.actionHandler?(forward)
        XCTAssertEqual(delegate.calls, ["play", "forward"])
    }

    func testStartScreenPlayButtonHasNoSeekActions() throws {
        let view = makePlayerView(theme: makeTheme(startScreen: .posterAndPlayButton))
        view.startLoader()

        let element = try XCTUnwrap(view.overlay?.accessibilityElements?.first as? UIAccessibilityElement)
        XCTAssertEqual(element.accessibilityLabel, "Go")
        XCTAssertNil(element.accessibilityCustomActions)
    }

    func testTimelineIsAnAdjustableSeekBar() throws {
        let output = TimelineOutputSpy()
        let theme = makeTheme()
        let timeline = TimelineView(config: try XCTUnwrap(KinescopePlayerViewConfiguration.themed(theme).controlPanel?.timeline),
                                    theme: theme)
        timeline.output = output
        timeline.frame = CGRect(x: 0, y: 0, width: 200, height: 28)
        timeline.setTimeline(to: 0.5)

        XCTAssertTrue(timeline.isAccessibilityElement)
        XCTAssertTrue(timeline.accessibilityTraits.contains(.adjustable))
        XCTAssertEqual(timeline.accessibilityLabel, "Seek")
        XCTAssertEqual(timeline.accessibilityValue, percent(0.5))

        timeline.accessibilityIncrement()
        XCTAssertEqual(try XCTUnwrap(output.positions.last), 0.55, accuracy: 0.0001)
        XCTAssertEqual(output.updates, 1)
        XCTAssertEqual(timeline.accessibilityValue, percent(0.55))
        timeline.setTimeline(to: 0.02)
        timeline.accessibilityDecrement()
        XCTAssertEqual(output.positions.last, 0, "clamped to the start")
    }

    func testSideMenuButtonsAreLabelled() throws {
        let bar = SideMenuBar(config: KinescopeSideMenuConfiguration.default.bar,
                              theme: makeTheme(),
                              model: .init(title: "Quality", isRoot: false, isDownloadable: false))

        let labels = Set(bar.allSubviews { $0 is UIButton }.compactMap(\.accessibilityLabel))
        XCTAssertEqual(labels, ["Up", "Shut"])
    }

    func testSideMenuIsModalForVoiceOver() {
        let menu = SideMenu(config: .default,
                            model: .init(title: "Settings", isRoot: true, isDownloadable: false, items: []),
                            theme: makeTheme())

        XCTAssertTrue(menu.accessibilityViewIsModal)
    }

    // MARK: - Tap targets

    func testOptionsTakeTapsOverA44PointArea() throws {
        let view = makePlayerView(theme: makeTheme())
        let panel = try XCTUnwrap(view.controlPanel)
        let menu = try XCTUnwrap(panel.optionsMenu)
        let more = try XCTUnwrap(menu.firstSubview { ($0 as? OptionButton)?.option == .more })
        XCTAssertEqual(more.bounds.size, CGSize(width: 28, height: 28))

        // 8 points above and right of the 28-point glyph, outside the bar and the menu.
        let corner = more.convert(CGPoint(x: 35, y: -7), to: view)
        XCTAssertFalse(panel.frame.contains(corner))
        XCTAssertTrue(view.hitTest(corner, with: nil)?.isDescendant(of: more) == true)

        // Between two options the nearer one takes it.
        let fullscreen = try XCTUnwrap(menu.firstSubview { ($0 as? OptionButton)?.option == .fullscreen })
        let nearFullscreen = fullscreen.convert(CGPoint(x: 31, y: 14), to: view)
        XCTAssertTrue(view.hitTest(nearFullscreen, with: nil)?.isDescendant(of: fullscreen) == true)

        // Above the bar but away from its controls: the overlay behind takes it.
        let aboveTime = panel.convert(CGPoint(x: 20, y: -3), to: view)
        XCTAssertFalse(view.hitTest(aboveTime, with: nil)?.isDescendant(of: panel) == true)
    }

    func testAirPlayPickerSpansA44PointTarget() throws {
        let control = AirPlayOptionControl(theme: makeTheme())
        control.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        control.layoutIfNeeded()

        let picker = try XCTUnwrap(control.subviews.first)
        XCTAssertEqual(picker.frame, CGRect(x: -8, y: -8, width: 44, height: 44))
        XCTAssertTrue(control.point(inside: CGPoint(x: -7, y: -7), with: nil))
    }

    // MARK: - Loader

    func testThemeLoaderReplacesTheSystemSpinner() {
        let loader = LoaderSpy()
        var theme = makeTheme()
        theme.loader = { loader }
        let view = makePlayerView(theme: theme)

        XCTAssertTrue(view.progressView === loader)
        view.startLoader()
        XCTAssertEqual(loader.states.last, true)
    }

    func testStartScreenShowsTheLoaderOnlyAfterATap() throws {
        let loader = LoaderSpy()
        var theme = makeTheme(startScreen: .posterAndPlayButton)
        theme.loader = { loader }
        let view = makePlayerView(theme: theme)
        let overlay = try XCTUnwrap(view.overlay)

        view.startLoader()
        XCTAssertEqual(loader.states.last, false)
        XCTAssertFalse(overlay.isHidden)
        view.stopLoader()
        XCTAssertEqual(loader.states.last, false, "the prepared video: the button, no loader")

        view.didPlay()
        XCTAssertEqual(loader.states.last, true)
        XCTAssertTrue(overlay.isHidden, "the loader alone after the tap")
        view.change(timeControlStatus: .playing)
        XCTAssertEqual(loader.states.last, false)
    }

    func testTapWhileTheVideoLoadsKeepsTheLoaderUntilPlayback() throws {
        let loader = LoaderSpy()
        var theme = makeTheme(startScreen: .posterAndPlayButton)
        theme.loader = { loader }
        let view = makePlayerView(theme: theme)

        view.startLoader()
        view.didPlay()
        view.stopLoader()
        XCTAssertEqual(loader.states.last, true)
        XCTAssertEqual(view.overlay?.isHidden, true)
    }

    // MARK: - Morph

    func testMorphDrawsTheGlyphAsAShapeSizedLikeTheImages() throws {
        var theme = makeTheme()
        theme.playPauseAnimation = .morph
        let overlay = PlayerOverlayView(config: try XCTUnwrap(KinescopePlayerViewConfiguration.themed(theme).overlay),
                                        theme: theme)
        overlay.frame = CGRect(origin: .zero, size: Constants.size)
        overlay.layoutIfNeeded()

        let glyph = try XCTUnwrap(overlay.playPauseGlyphView)
        XCTAssertTrue(overlay.allSubviews { $0 is UIImageView && $0.bounds.width > 0 && !$0.isHidden }
            .allSatisfy { $0.superview !== glyph.superview }, "no image under the shape")
        XCTAssertEqual(glyph.currentPoints.count, 8)
        let play = glyph.currentPoints
        XCTAssertEqual(play[5].y, play[6].y, "the triangle's tip")

        overlay.set(playing: true)
        let pause = glyph.currentPoints
        XCTAssertTrue(glyph.isPlaying)
        XCTAssertEqual(pause[0].y, pause[1].y, "a bar's flat top")
        XCTAssertEqual(pause[1].x - pause[0].x, pause[5].x - pause[4].x, accuracy: 0.001, "two equal bars")
    }

    func testMorphAnimatesThePathWhenOnScreen() throws {
        let glyph = PlayPauseGlyphView(shape: .bars(playSize: CGSize(width: 14, height: 16),
                                                     pauseSize: CGSize(width: 12, height: 14),
                                                     cornerRadius: 1),
                                       duration: 0.2)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(glyph)
        glyph.frame = CGRect(x: 0, y: 0, width: 14, height: 16)
        glyph.layoutIfNeeded()

        glyph.set(playing: true, animated: true)
        let shape = try XCTUnwrap(glyph.layer.sublayers?.first as? CAShapeLayer)
        let animation = try XCTUnwrap(shape.animation(forKey: "morph") as? CABasicAnimation)
        XCTAssertEqual(animation.duration, 0.2)
        XCTAssertEqual(animation.timingFunction, CAMediaTimingFunction(name: .easeInEaseOut))
    }

    func testPressedLayerFadesOutAfterATap() throws {
        var theme = makeTheme()
        theme.colors.playButtonPressedOverlay = .white
        theme.playPauseAnimation = .morph
        let overlay = PlayerOverlayView(config: try XCTUnwrap(KinescopePlayerViewConfiguration.themed(theme).overlay),
                                        theme: theme)
        let window = UIWindow(frame: CGRect(origin: .zero, size: Constants.size))
        window.addSubview(overlay)
        overlay.frame = window.bounds
        overlay.layoutIfNeeded()
        let layer = try XCTUnwrap(overlay.allSubviews { $0.layer.cornerRadius == 32 }.last)

        overlay.flashPlayButtonPressed()
        XCTAssertEqual(layer.alpha, 0)
        XCTAssertNotNil(layer.layer.animationKeys(), "fading out, not gone at once")
    }

    // MARK: - Private

    private func percent(_ value: Double) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: value), number: .percent)
    }

    private func makeTheme(startScreen: KinescopePlayerTheme.StartScreen = .sdk) -> KinescopePlayerTheme {
        var colors = KinescopePlayerTheme.Colors.default
        colors.playButtonBackgroundPressed = .blue
        return KinescopePlayerTheme(
            icons: .init { icon in icon == .play ? UIImage(systemName: "play.fill") : nil },
            colors: colors,
            metrics: .compact,
            startScreen: startScreen,
            accessibilityLabels: .init(play: "Go", pause: "Stop", fastForward: "Ahead", fastBackward: "Behind",
                                       timeline: "Seek", more: "More", fullscreen: "Full", exitFullscreen: "Leave",
                                       settings: "Gear", attachments: "Files", download: "Save", airPlay: "Cast",
                                       subtitles: "Subs", pip: "PiP", menuBack: "Up", menuClose: "Shut")
        )
    }

    private func makePlayerView(theme: KinescopePlayerTheme) -> KinescopePlayerView {
        let view = KinescopePlayerView(frame: CGRect(origin: .zero, size: Constants.size))
        view.setLayout(with: .themed(theme))
        view.set(options: Constants.options)
        view.controlPanel?.set(live: nil)
        view.controlPanel?.isHidden = false
        view.layoutIfNeeded()
        return view
    }

}

private final class OverlayDelegateSpy: PlayerOverlayViewDelegate {
    private(set) var calls = [String]()

    func didTap(isSelected: Bool) { calls.append("tap") }
    func didPlay() { calls.append("play") }
    func didPause() { calls.append("pause") }
    func didFastForward() { calls.append("forward") }
    func didFastBackward() { calls.append("backward") }
}

private final class TimelineOutputSpy: TimelineOutput {
    private(set) var positions = [CGFloat]()
    private(set) var updates = 0

    func onTimelinePositionChanged(to position: CGFloat) { positions.append(position) }
    func onUpdate() { updates += 1 }
}

private final class LoaderSpy: UIView, KinescopeActivityIndicating {
    private(set) var states = [Bool]()

    func showVideoProgress(isLoading: Bool) {
        states.append(isLoading)
        isHidden = !isLoading
    }
}

private extension UIView {

    func allSubviews(where predicate: (UIView) -> Bool) -> [UIView] {
        subviews.flatMap { subview in
            (predicate(subview) ? [subview] : []) + subview.allSubviews(where: predicate)
        }
    }

    func firstSubview(where predicate: (UIView) -> Bool) -> UIView? {
        for subview in subviews {
            if predicate(subview) {
                return subview
            }
            if let match = subview.firstSubview(where: predicate) {
                return match
            }
        }
        return nil
    }

}
