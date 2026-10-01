import XCTest
@testable import KinescopeSDK

/// The theme slots for the Figma «Player» file, the mobile player component (`7316:33975`): the bar geometry, the
/// start button growing while pressed, the glyph-only chrome button, the card menu and the lit seek sides.
final class KinescopePlayerFigmaPlayerTests: XCTestCase {

    private enum Constants {
        static let size = CGSize(width: 375, height: 211)
        static let options: [KinescopePlayerOption] = [.subtitles, .airPlay, .settings, .pip, .fullscreen, .more]
        static let accent = UIColor(red: 0x61 / 255, green: 0x61 / 255, blue: 0xfc / 255, alpha: 1)
        static let pressed = UIColor(white: 1, alpha: 0.64)
    }

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window = nil
        super.tearDown()
    }

    // MARK: - Defaults

    func testDefaultThemeKeepsTheSDKLook() {
        let theme = KinescopePlayerTheme.default

        XCTAssertNil(theme.metrics.playButtonPressedDiameter)
        XCTAssertNotNil(theme.colors.timelineThumbHalo)
        XCTAssertNil(theme.chromePlayButton)
        XCTAssertEqual(theme.menu.presentation, .sideSheet)
        XCTAssertFalse(theme.menu.isCard)
        guard case .icon = theme.seekFeedback.style else {
            return XCTFail("The default seek feedback is the SDK's glyph")
        }
    }

    // MARK: - Control bar

    func testControlBarFollowsTheMobileComponent() throws {
        let view = makePlayerView(theme: makeTheme())
        let panel = try XCTUnwrap(view.controlPanel)
        panel.setIndicator(to: 769)
        view.layoutIfNeeded()

        // Figma «Control bar» 9481:131395 in Type=Mobile 7316:33975: a 343×28 row at x 16, y 175, gaps 12.
        XCTAssertEqual(panel.frame.maxY, Constants.size.height)
        XCTAssertEqual(panel.frame.height, 28 + 8)
        XCTAssertEqual(panel.timeIndicator.frame.minX, 16)
        XCTAssertEqual(panel.optionsMenu.frame.maxX, Constants.size.width - 16, accuracy: 0.5)
        XCTAssertEqual(panel.optionsMenu.frame.width, 28 + 12 + 28, accuracy: 0.5)
        XCTAssertEqual(panel.timeline.frame.minX - panel.timeIndicator.frame.maxX, 12, accuracy: 0.5)
        XCTAssertEqual(panel.optionsMenu.frame.minX - panel.timeline.frame.maxX, 12, accuracy: 0.5)
        XCTAssertEqual(panel.convert(panel.optionsMenu.frame, to: view).midY, 175 + 14, accuracy: 0.5)
    }

    func testDraggedThumbHasNoHaloWithoutAColor() throws {
        let theme = makeTheme()
        let timeline = TimelineView(config: try XCTUnwrap(KinescopePlayerViewConfiguration.themed(theme)
                                                              .controlPanel?.timeline),
                                    theme: theme)
        timeline.frame = CGRect(x: 0, y: 0, width: 200, height: 28)
        timeline.setTimeline(to: 0.5)
        timeline.isTouching = true
        timeline.layoutIfNeeded()

        let shown = timeline.subviews.filter { !$0.isHidden && $0.frame.height != 4 }
        // Figma «Timeline» Hovered 9532:116646: one 16-point accent circle.
        XCTAssertEqual(shown.count, 1)
        XCTAssertEqual(shown.first?.frame.size, CGSize(width: 16, height: 16))
        XCTAssertEqual(shown.first?.center.x ?? 0, 100, accuracy: 0.5)
    }

    // MARK: - Play button

    func testStartScreenAndChromeDrawDifferentButtons() throws {
        let view = makePlayerView(theme: makeTheme(startScreen: .posterAndPlayButton))
        let overlay = try XCTUnwrap(view.overlay)
        view.stopLoader()
        view.layoutIfNeeded()

        // Figma «Play button» 543:7372: a 72-point circle, the 36-point glyph 2 points right of the center.
        XCTAssertTrue(overlay.isStartScreen)
        XCTAssertEqual(overlay.playButtonStyle.diameter, 72)
        XCTAssertEqual(overlay.playButtonFrameInOverlay.width, 72, accuracy: 0.5)
        XCTAssertFalse(overlay.playButtonStyle.isGlyphOnly)

        view.skipStartScreen()
        view.layoutIfNeeded()

        // Figma «M / Play» 2908:16201 in the paused Controls: a 56-point glyph, no circle.
        XCTAssertEqual(overlay.playButtonStyle.diameter, 56)
        XCTAssertTrue(overlay.playButtonStyle.isGlyphOnly)
        XCTAssertEqual(overlay.playButtonFrameInOverlay.width, 56, accuracy: 0.5)
        XCTAssertEqual(overlay.playButtonFrameInOverlay.midX, Constants.size.width / 2, accuracy: 0.5)
    }

    func testGlyphOnlyButtonTintsTheGlyphWhenPressed() throws {
        var theme = makeTheme()
        let view = makePlayerView(theme: theme)
        let overlay = try XCTUnwrap(view.overlay)
        let glyph = try XCTUnwrap(overlay.playPauseGlyphView)

        overlay.setPlayButtonPressed(true)
        XCTAssertEqual(glyph.tintColor, Constants.pressed)

        overlay.setPlayButtonPressed(false)
        XCTAssertEqual(glyph.tintColor, .white)
    }

    func testStartButtonGrowsWhenPressed() throws {
        let view = makePlayerView(theme: makeTheme(startScreen: .posterAndPlayButton))
        let overlay = try XCTUnwrap(view.overlay)
        view.stopLoader()
        view.layoutIfNeeded()
        let centerX = overlay.playButtonFrameInOverlay.midX

        // Figma «Play button» Hovered 12403:87948: an 80-point circle in Surface/player/play_button/hover.
        overlay.setPlayButtonPressed(true)
        let circles = overlay.allSubviews { $0.layer.cornerRadius == 36 && $0.backgroundColor == Constants.accent }
        let circle = try XCTUnwrap(circles.first)
        XCTAssertEqual(circle.frame.width, 80, accuracy: 0.5)
        XCTAssertEqual(overlay.convert(circle.center, from: circle.superview).x, centerX, accuracy: 0.5)

        overlay.setPlayButtonPressed(false)
        XCTAssertEqual(circle.frame.width, 72, accuracy: 0.5)
        XCTAssertEqual(circle.backgroundColor, Constants.accent.withAlphaComponent(0.64))
    }

    func testMorphingGlyphIsScaledForTheChrome() throws {
        let view = makePlayerView(theme: makeTheme(startScreen: .posterAndPlayButton))
        let overlay = try XCTUnwrap(view.overlay)
        let glyph = try XCTUnwrap(overlay.playPauseGlyphView)
        view.stopLoader()
        XCTAssertEqual(glyph.transform, .identity)

        view.skipStartScreen()
        let ratio = (56.0 / 24.0) / (36.0 / 24.0)
        XCTAssertEqual(glyph.transform.a, ratio, accuracy: 0.001)
        XCTAssertEqual(glyph.transform.d, ratio, accuracy: 0.001)
    }

    // MARK: - Menu

    func testSettingsCardFollowsFigma() throws {
        let view = makePlayerView(theme: makeTheme())
        view.didSelect(option: .settings)
        let card = try XCTUnwrap(view.subviews.compactMap { $0 as? SideMenu }.last)

        // Figma «Settings/Normal» 9494:114269: 280 wide, 16 from the trailing edge, 44 from the bottom, 6 corners,
        // three 36-point rows padded 8, no title row.
        XCTAssertEqual(card.frame.width, 280)
        XCTAssertEqual(card.frame.maxX, Constants.size.width - 16)
        XCTAssertEqual(card.frame.maxY, Constants.size.height - 44)
        XCTAssertEqual(card.frame.height, 8 + 3 * 36 + 8)
        XCTAssertEqual(card.layer.cornerRadius, 6)
        XCTAssertNil(card.allSubviews { $0 is SideMenuBar }.first)
        XCTAssertEqual(card.accessibilityLabel, L10n.Player.settings)
        XCTAssertTrue(card.accessibilityViewIsModal)
    }

    func testSettingsRowsTakeTheThemeGlyphs() throws {
        let view = makePlayerView(theme: makeTheme())
        view.didSelect(option: .settings)
        let card = try XCTUnwrap(view.subviews.compactMap { $0 as? SideMenu }.last)
        card.layoutIfNeeded()
        let table = try XCTUnwrap(card.allSubviews { $0 is UITableView }.first as? UITableView)
        table.layoutIfNeeded()

        let cells = table.visibleCells.compactMap { $0 as? DisclosureCell }
        XCTAssertEqual(cells.count, 3)
        for cell in cells {
            let glyphs = cell.allSubviews { ($0 as? UIImageView)?.image != nil && !$0.isHidden }
            // The row glyph and the chevron.
            XCTAssertEqual(glyphs.count, 2)
        }
    }

    func testNestedCardReplacesItsParentAndHasABackRow() throws {
        let view = makePlayerView(theme: makeTheme())
        view.didSelect(option: .settings)
        let root = try XCTUnwrap(view.subviews.compactMap { $0 as? SideMenu }.last)
        view.sideMenuDidSelect(item: .disclosure(title: L10n.Player.playbackSpeed, value: nil), rowIndex: 0, sideMenu: root)
        let nested = try XCTUnwrap(view.subviews.compactMap { $0 as? SideMenu }.last)

        XCTAssertTrue(root.isHidden)
        XCTAssertFalse(nested.isHidden)
        let bar = try XCTUnwrap(nested.allSubviews { $0 is SideMenuBar }.first)
        nested.layoutIfNeeded()
        XCTAssertEqual(bar.frame.minY, 8)
        XCTAssertEqual(bar.frame.height, 36)
        let buttons = bar.allSubviews { $0 is UIButton }
        XCTAssertEqual(buttons.map(\.accessibilityLabel), [L10n.Player.back])

        view.sideMenuWillBeDismissed(nested, withRoot: false)
        XCTAssertFalse(root.isHidden)
    }

    func testCardScrollsWhenThePlayerIsLow() throws {
        let view = makePlayerView(theme: makeTheme())
        let rates = RateProvider()
        view.bind(playingRateProvider: rates, videoQualityProvider: rates, subtitlesProvider: SubtitlesProvider(source: rates))
        view.didSelect(option: .settings)
        let root = try XCTUnwrap(view.subviews.compactMap { $0 as? SideMenu }.last)
        view.sideMenuDidSelect(item: .disclosure(title: L10n.Player.playbackSpeed, value: nil), rowIndex: 0, sideMenu: root)
        let nested = try XCTUnwrap(view.subviews.compactMap { $0 as? SideMenu }.last)

        // Eight speeds and the back row do not fit in 211 points: the card reaches the top margin and scrolls.
        XCTAssertEqual(nested.frame.minY, 8)
        XCTAssertEqual(nested.frame.maxY, Constants.size.height - 44)
        XCTAssertGreaterThan(nested.preferredHeight, nested.frame.height)
    }

    // MARK: - Seek feedback

    func testSideAreaLightsTheTappedSide() throws {
        let view = makePlayerView(theme: makeTheme())
        let overlay = try XCTUnwrap(view.overlay)
        let forward = try XCTUnwrap(overlay.seekForwardArea)
        let backward = try XCTUnwrap(overlay.seekBackwardArea)
        view.layoutIfNeeded()

        // Figma «Rewind» 18600:33369: 163 of 375 points on each side.
        XCTAssertEqual(forward.frame.width, 163, accuracy: 0.5)
        XCTAssertEqual(forward.frame.maxX, Constants.size.width, accuracy: 0.5)
        XCTAssertEqual(backward.frame.minX, 0)
        XCTAssertEqual(forward.alpha, 0)

        overlay.accessibilityFastForward()
        // Lit at once, then fading out.
        XCTAssertNotNil(forward.layer.animation(forKey: "opacity"))
        XCTAssertNil(backward.layer.animation(forKey: "opacity"))
        let label = try XCTUnwrap(forward.allSubviews { $0 is UILabel }.first as? UILabel)
        XCTAssertEqual(label.text, L10n.Player.seekSeconds(15))
        XCTAssertFalse(forward.isAccessibilityElement)
    }

    // MARK: - Private

    private final class RateProvider: SideMenuItemsProvider, SubtitlesSource {
        let selectedTitle = KinescopePlayingRate.normal.title
        var items: [SideMenu.Item] {
            KinescopePlayingRate.allCases.map { .checkmark(title: NSAttributedString(string: $0.title)) }
        }
        let currentSubtitles: String? = nil
        let availableSubtitles: [String] = []
    }

    private func makeTheme(startScreen: KinescopePlayerTheme.StartScreen = .sdk) -> KinescopePlayerTheme {
        var colors = KinescopePlayerTheme.Colors.default
        colors.playButtonBackground = Constants.accent.withAlphaComponent(0.64)
        colors.playButtonBackgroundPressed = Constants.accent
        colors.timelineThumbHalo = nil
        colors.iconPressed = Constants.pressed
        let glyphs: [KinescopePlayerIcon: String] = [
            .play: "play.fill", .pause: "pause.fill",
            .menuPlaybackSpeed: "gauge", .menuSubtitles: "captions.bubble", .menuQuality: "slider.horizontal.3"
        ]
        return KinescopePlayerTheme(
            icons: .init { icon in glyphs[icon].flatMap { UIImage(systemName: $0) } },
            colors: colors,
            metrics: .player,
            startScreen: startScreen,
            playPauseAnimation: .morph,
            chromePlayButton: .glyphOnly,
            menu: .card,
            seekFeedback: .sideArea
        )
    }

    private func makePlayerView(theme: KinescopePlayerTheme) -> KinescopePlayerView {
        let controller = UIViewController()
        // Below the sensor housing: an inline player has no safe area insets.
        let window = UIWindow(frame: CGRect(origin: CGPoint(x: 0, y: 200), size: Constants.size))
        window.rootViewController = controller
        window.isHidden = false
        self.window = window

        let view = KinescopePlayerView(frame: CGRect(origin: .zero, size: Constants.size))
        view.setLayout(with: .themed(theme))
        controller.view.addSubview(view)
        view.set(options: Constants.options)
        view.controlPanel?.set(live: nil)
        view.controlPanel?.isHidden = false
        view.layoutIfNeeded()
        return view
    }

}

private extension UIView {

    func allSubviews(where predicate: (UIView) -> Bool) -> [UIView] {
        subviews.flatMap { subview in
            (predicate(subview) ? [subview] : []) + subview.allSubviews(where: predicate)
        }
    }

}
