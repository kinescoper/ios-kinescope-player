import XCTest
@testable import KinescopeSDK

/// The theme slots for the Figma «Player» file (`20485:44504`): the pill bar, the glyph-only chrome button, the
/// card menu, the lit seek sides and the circle under the three dots.
final class KinescopePlayerFigmaPlayerTests: XCTestCase {

    private enum Constants {
        static let size = CGSize(width: 375, height: 211)
        static let options: [KinescopePlayerOption] = [.subtitles, .airPlay, .settings, .pip, .fullscreen, .more]
        static let black32 = UIColor(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255, alpha: 0.32)
        static let pressed = UIColor(white: 1, alpha: 0.64)
        static let white8 = UIColor(white: 1, alpha: 0.08)
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

        XCTAssertNil(theme.colors.controlBarBackground)
        XCTAssertNil(theme.colors.optionPressedBackground)
        XCTAssertNotNil(theme.colors.timelineThumbHalo)
        XCTAssertNil(theme.chromePlayButton)
        XCTAssertEqual(theme.menu.presentation, .sideSheet)
        XCTAssertFalse(theme.menu.isCard)
        XCTAssertEqual(theme.metrics.controlBarPadding, .zero)
        guard case .icon = theme.seekFeedback.style else {
            return XCTFail("The default seek feedback is the SDK's glyph")
        }
    }

    func testDefaultBarHasNoBackground() throws {
        let view = makePlayerView(theme: .default)
        let panel = try XCTUnwrap(view.controlPanel)

        XCTAssertTrue(panel.barBackground.isHidden)
    }

    // MARK: - Control bar

    func testPillBarFollowsFigma() throws {
        let view = makePlayerView(theme: makeTheme())
        let panel = try XCTUnwrap(view.controlPanel)
        panel.setIndicator(to: 769)
        view.layoutIfNeeded()

        // Figma «Control bar» 20485:47990: 343×44 at x 16, y 159, padded 8, gaps 12, rounded to a capsule.
        let pill = panel.convert(panel.barBackground.frame, to: view)
        XCTAssertEqual(pill, CGRect(x: 16, y: 159, width: 343, height: 44))
        XCTAssertFalse(panel.barBackground.isHidden)
        XCTAssertEqual(panel.barBackground.backgroundColor, Constants.black32)
        XCTAssertEqual(panel.barBackground.layer.cornerRadius, 22)
        XCTAssertEqual(panel.timeIndicator.frame.minX, 16 + 8)
        XCTAssertEqual(panel.optionsMenu.frame.maxX, Constants.size.width - 16 - 8, accuracy: 0.5)
        XCTAssertEqual(panel.optionsMenu.frame.width, 28 + 12 + 28, accuracy: 0.5)
        XCTAssertEqual(panel.timeline.frame.minX - panel.timeIndicator.frame.maxX, 12, accuracy: 0.5)
        XCTAssertEqual(panel.optionsMenu.frame.minX - panel.timeline.frame.maxX, 12, accuracy: 0.5)
        XCTAssertEqual(panel.convert(panel.optionsMenu.frame, to: view).midY, 159 + 22, accuracy: 0.5)
    }

    func testPressedOptionShowsACircle() throws {
        let view = makePlayerView(theme: makeTheme())
        let buttons = view.allSubviews { $0 is OptionButton }.compactMap { $0 as? OptionButton }
        let more = try XCTUnwrap(buttons.first { $0.option == .more })
        let circle = try XCTUnwrap(more.pressedCircle)
        view.layoutIfNeeded()

        // Figma «Settings 3» State=Hovered 20485:48137: a 32-point circle behind the glyph.
        XCTAssertTrue(circle.isHidden)
        XCTAssertEqual(circle.bounds.size, CGSize(width: 32, height: 32))
        XCTAssertEqual(circle.center, CGPoint(x: more.bounds.midX, y: more.bounds.midY))
        XCTAssertEqual(circle.backgroundColor, Constants.white8)
        XCTAssertFalse(more.adjustsImageWhenHighlighted)

        more.isHighlighted = true
        XCTAssertFalse(circle.isHidden)
        more.isHighlighted = false
        XCTAssertTrue(circle.isHidden)
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

        // Figma «M / Play» 20485:44511 in the paused Controls: a 56-point glyph, no circle.
        XCTAssertEqual(overlay.playButtonStyle.diameter, 56)
        XCTAssertTrue(overlay.playButtonStyle.isGlyphOnly)
        XCTAssertEqual(overlay.playButtonFrameInOverlay.width, 56, accuracy: 0.5)
        XCTAssertEqual(overlay.playButtonFrameInOverlay.midX, Constants.size.width / 2, accuracy: 0.5)
    }

    func testGlyphOnlyButtonTintsTheGlyphWhenPressed() throws {
        var theme = makeTheme()
        theme.colors.optionPressedBackground = nil
        let view = makePlayerView(theme: theme)
        let overlay = try XCTUnwrap(view.overlay)
        let glyph = try XCTUnwrap(overlay.playPauseGlyphView)

        overlay.setPlayButtonPressed(true)
        XCTAssertEqual(glyph.tintColor, Constants.pressed)

        overlay.setPlayButtonPressed(false)
        XCTAssertEqual(glyph.tintColor, .white)
    }

    func testGlyphOnlyButtonShowsThePressedCircle() throws {
        let view = makePlayerView(theme: makeTheme())
        let overlay = try XCTUnwrap(view.overlay)
        overlay.setPlayButtonPressed(true)

        let circles = overlay.allSubviews {
            $0.layer.cornerRadius == 28 && $0.alpha == 1 && ($0.backgroundColor?.cgColor.alpha ?? 0) > 0
        }
        XCTAssertEqual(circles.map(\.backgroundColor), [Constants.white8])
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

        // Figma «Settings/Normal» 20485:44516: 280 wide, 16 from the trailing edge, 44 from the bottom, 6 corners,
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
        colors.controlBarBackground = Constants.black32
        colors.optionPressedBackground = Constants.white8
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
