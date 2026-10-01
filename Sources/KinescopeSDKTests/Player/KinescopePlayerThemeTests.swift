import XCTest
@testable import KinescopeSDK

final class KinescopePlayerThemeTests: XCTestCase {

    private enum Constants {
        static let pressed = UIColor(red: 0x61 / 255, green: 0x61 / 255, blue: 0xfc / 255, alpha: 1)
        static let pressedOverlay = UIColor(white: 1, alpha: 0.16)
        static let size = CGSize(width: 375, height: 211)
        static let options: [KinescopePlayerOption] = [.subtitles, .airPlay, .settings, .pip, .fullscreen, .more]
    }

    // MARK: - Defaults

    func testDefaultConfigurationKeepsTheSDKLook() {
        let configuration = KinescopePlayerViewConfiguration.default
        let metrics = configuration.theme.metrics

        XCTAssertEqual(metrics.controlBarInsets, UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        XCTAssertEqual(metrics.controlBarSpacing, 16)
        XCTAssertEqual(metrics.optionSpacing, 8)
        XCTAssertTrue(metrics.timelineThumbVisibleWhenIdle)
        XCTAssertTrue(metrics.timeReservesHours)
        XCTAssertNil(configuration.theme.colors.iconPressed)
        XCTAssertNil(configuration.theme.colors.playButtonBackgroundPressed)
    }

    func testThemedDefaultMatchesDefaultNestedConfigurations() throws {
        let themed = KinescopePlayerViewConfiguration.themed(.default)
        let defaults = KinescopePlayerViewConfiguration.default
        let panel = try XCTUnwrap(themed.controlPanel)
        let defaultPanel = try XCTUnwrap(defaults.controlPanel)
        let overlay = try XCTUnwrap(themed.overlay)
        let defaultOverlay = try XCTUnwrap(defaults.overlay)

        XCTAssertEqual(panel.preferedHeight, defaultPanel.preferedHeight)
        XCTAssertEqual(panel.timeline.activeColor, defaultPanel.timeline.activeColor)
        XCTAssertEqual(panel.timeline.inactiveColor, defaultPanel.timeline.inactiveColor)
        XCTAssertEqual(panel.timeline.lineHeight, defaultPanel.timeline.lineHeight)
        XCTAssertEqual(panel.timeline.circleRadius, defaultPanel.timeline.circleRadius)
        XCTAssertEqual(panel.optionsMenu.iconSize, defaultPanel.optionsMenu.iconSize)
        XCTAssertEqual(panel.optionsMenu.normalColor, defaultPanel.optionsMenu.normalColor)
        XCTAssertEqual(panel.optionsMenu.highlightedColor, defaultPanel.optionsMenu.highlightedColor)
        XCTAssertEqual(panel.timeIndicator.fontSize, defaultPanel.timeIndicator.fontSize)
        XCTAssertEqual(overlay.playBackgroundRadius, defaultOverlay.playBackgroundRadius)
        XCTAssertEqual(overlay.playBackgroundColor, defaultOverlay.playBackgroundColor)
        XCTAssertEqual(overlay.backgroundColor, defaultOverlay.backgroundColor)
        XCTAssertEqual(themed.sideMenu.item.titleFont, defaults.sideMenu.item.titleFont)
        XCTAssertEqual(themed.sideMenu.bar.titleFont, defaults.sideMenu.bar.titleFont)
    }

    func testThemedFillsNestedConfigurationsFromTheTheme() throws {
        let configuration = KinescopePlayerViewConfiguration.themed(makeTheme())
        let panel = try XCTUnwrap(configuration.controlPanel)
        let overlay = try XCTUnwrap(configuration.overlay)

        XCTAssertEqual(panel.preferedHeight, 28)
        XCTAssertEqual(panel.optionsMenu.iconSize, 28)
        XCTAssertEqual(panel.optionsMenu.highlightedColor, Constants.pressed)
        XCTAssertEqual(panel.timeline.circleRadius, 6)
        XCTAssertEqual(overlay.playBackgroundRadius, 32)
        XCTAssertEqual(overlay.playImage.renderingMode, .alwaysTemplate)
    }

    // MARK: - Icons

    func testIconsFallBackToBundledImages() {
        let icons = KinescopePlayerTheme.Icons([.more: UIImage()])

        XCTAssertNotNil(icons.custom(.more))
        XCTAssertNil(icons.custom(.pip))
        XCTAssertEqual(icons.image(for: .more)?.renderingMode, .alwaysTemplate)
        XCTAssertNotNil(icons.image(for: .pip))
        // The settings rows have no glyph of their own: they get one only from a theme.
        let themeOnly: Set<KinescopePlayerIcon> = [.menuPlaybackSpeed, .menuSubtitles, .menuQuality]
        for icon in KinescopePlayerIcon.allCases where !themeOnly.contains(icon) {
            XCTAssertNotNil(icon.bundledImageName, "\(icon) has no bundled image")
        }
        for icon in themeOnly {
            XCTAssertNil(icons.image(for: icon))
        }
    }

    func testFullscreenHostShowsTheExitIcon() {
        let exit = UIImage(systemName: "arrow.down.right.and.arrow.up.left")
        let enter = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
        var theme = KinescopePlayerTheme.default
        theme.icons = .init { icon in
            switch icon {
            case .fullscreen: return enter
            case .exitFullscreen: return exit
            default: return nil
            }
        }

        let inline = OptionButton(option: .fullscreen, theme: theme)
        let fullscreen = OptionButton(option: .fullscreen, theme: theme, isFullscreen: true)

        XCTAssertEqual(inline.image(for: .normal)?.pngData(),
                       enter?.withRenderingMode(.alwaysTemplate).pngData())
        XCTAssertEqual(fullscreen.image(for: .normal)?.pngData(),
                       exit?.withRenderingMode(.alwaysTemplate).pngData())
    }

    // MARK: - Pressed states

    func testOptionButtonTakesThePressedColor() {
        let button = OptionButton(option: .more, theme: makeTheme(), normalColor: .white)

        XCTAssertEqual(button.tintColor, .white)
        XCTAssertFalse(button.adjustsImageWhenHighlighted)
        button.isHighlighted = true
        XCTAssertEqual(button.tintColor, Constants.pressed)
        button.isHighlighted = false
        XCTAssertEqual(button.tintColor, .white)
    }

    func testOptionButtonKeepsSystemDimmingWithoutAPressedColor() {
        let button = OptionButton(option: .more)

        XCTAssertTrue(button.adjustsImageWhenHighlighted)
        button.isHighlighted = true
        XCTAssertEqual(button.tintColor, .white)
    }

    func testPlayButtonTakesThePressedBackground() throws {
        let theme = makeTheme()
        let overlay = PlayerOverlayView(config: try XCTUnwrap(KinescopePlayerViewConfiguration.themed(theme).overlay),
                                        theme: theme)
        let circle = try XCTUnwrap(overlay.firstSubview { $0.layer.cornerRadius == 32 })

        overlay.setPlayButtonPressed(true)
        XCTAssertEqual(circle.backgroundColor, theme.colors.playButtonBackgroundPressed)
        overlay.setPlayButtonPressed(false)
        XCTAssertEqual(circle.backgroundColor, theme.colors.playButtonBackground)
    }

    func testPlayButtonLaysThePressedOverlayOverItsBackground() throws {
        var theme = makeTheme()
        theme.colors.playButtonBackgroundPressed = nil
        theme.colors.playButtonPressedOverlay = Constants.pressedOverlay
        let overlay = PlayerOverlayView(config: try XCTUnwrap(KinescopePlayerViewConfiguration.themed(theme).overlay),
                                        theme: theme)
        let circles = overlay.allSubviews { $0.layer.cornerRadius == 32 }
        XCTAssertEqual(circles.count, 2)
        let background = try XCTUnwrap(circles.first)
        let layer = try XCTUnwrap(circles.last)
        XCTAssertEqual(layer.backgroundColor, Constants.pressedOverlay)
        XCTAssertEqual(layer.alpha, 0)

        overlay.setPlayButtonPressed(true)
        XCTAssertEqual(layer.alpha, 1)
        XCTAssertEqual(background.backgroundColor, theme.colors.playButtonBackground, "the fill stays under the layer")
        overlay.setPlayButtonPressed(false)
        XCTAssertEqual(layer.alpha, 0)
    }

    // MARK: - Start screen

    func testDefaultThemeHasNoStartScreen() {
        let view = makePlayerView(configuration: .default)

        XCTAssertEqual(KinescopePlayerTheme.default.startScreen, .sdk)
        XCTAssertFalse(view.isAwaitingFirstPlay)
        view.stopLoader()
        XCTAssertTrue(view.previewView.isHidden)
        XCTAssertEqual(view.overlay?.isStartScreen, false)
    }

    func testStartScreenShowsThePosterAndThePlayButtonOnly() throws {
        let view = makePlayerView(configuration: .themed(makeTheme(startScreen: .posterAndPlayButton)))
        view.controlPanel?.isHidden = true
        let overlay = try XCTUnwrap(view.overlay)

        view.startLoader()
        XCTAssertFalse(overlay.isHidden, "the play button while the video loads")
        XCTAssertTrue(overlay.isStartScreen)
        XCTAssertTrue(view.progressView.isHidden, "no indicator under the play button")
        view.stopLoader()

        XCTAssertFalse(view.previewView.isHidden)
        XCTAssertFalse(overlay.isHidden)
        XCTAssertTrue(overlay.isStartScreen)
        XCTAssertFalse(overlay.isSelected)
        XCTAssertEqual(view.controlPanel?.isHidden, true)
        let content = try XCTUnwrap(overlay.subviews.first)
        XCTAssertEqual(content.alpha, 1)
        XCTAssertEqual(content.backgroundColor, .clear, "no dimming")
        XCTAssertTrue(overlay.allSubviews { $0 is VideoNameView }.allSatisfy(\.isHidden), "no title")
        // The chrome's timer does not hide the button.
        overlay.isSelected = false
        XCTAssertEqual(content.alpha, 1)
    }

    func testStartScreenWaitsWithASpinnerAndLeavesOnPlay() throws {
        let view = makePlayerView(configuration: .themed(makeTheme(startScreen: .posterAndPlayButton)))
        view.controlPanel?.isHidden = true
        let overlay = try XCTUnwrap(view.overlay)
        view.stopLoader()

        view.change(timeControlStatus: .waitingToPlayAtSpecifiedRate)
        XCTAssertTrue(overlay.isHidden)
        XCTAssertFalse(view.previewView.isHidden)
        // The item becomes ready while the started playback waits: still no button.
        view.stopLoader()
        XCTAssertTrue(overlay.isHidden)
        // The playback gave up: the button is back.
        view.change(timeControlStatus: .paused)
        XCTAssertFalse(overlay.isHidden)
        XCTAssertTrue(overlay.isStartScreen)

        view.change(timeControlStatus: .playing)
        XCTAssertFalse(view.isAwaitingFirstPlay)
        XCTAssertFalse(overlay.isStartScreen)
        XCTAssertTrue(overlay.isSelected)
        XCTAssertTrue(view.previewView.isHidden)
        XCTAssertEqual(view.controlPanel?.isHidden, false)
        XCTAssertEqual(overlay.subviews.first?.backgroundColor, KinescopePlayerTheme.Colors.default.overlayDim)

        // Pausing later is the usual chrome, not the start screen.
        view.change(timeControlStatus: .paused)
        XCTAssertFalse(overlay.isStartScreen)
    }

    func testPosterIsPlacedLikeTheVideo() {
        let fit = makePlayerView(configuration: .default)
        let fill = makePlayerView(configuration: KinescopePlayerViewConfigurationBuilder(configuration: .default)
            .setGravity(.resizeAspectFill)
            .build())

        XCTAssertEqual(fit.previewView.contentMode, .scaleAspectFit)
        XCTAssertEqual(fill.previewView.contentMode, .scaleAspectFill)
    }

    // MARK: - Geometry

    func testCompactPlayButtonMatchesTheVideoCard() {
        let metrics = KinescopePlayerTheme.Metrics.compact

        // Figma 69:20042 and the app's AppPlayButton: a 64-point circle, the 24-point glyph at its size, centered.
        XCTAssertEqual(metrics.playButtonDiameter, 64)
        XCTAssertEqual(metrics.playButtonGlyphScale, 1)
        XCTAssertEqual(metrics.playButtonGlyphOffset, .zero)
    }

    func testCompactControlBarFollowsFigma() throws {
        let view = makePlayerView(configuration: .themed(makeTheme()))
        let panel = try XCTUnwrap(view.controlPanel)
        panel.setIndicator(to: 769)
        view.layoutIfNeeded()

        // Figma 136:19210: bar 16 from the sides and 8 from the bottom, 28 high, items 12 apart.
        XCTAssertEqual(panel.frame.maxY, Constants.size.height)
        XCTAssertEqual(panel.frame.height, 28 + 8)
        XCTAssertEqual(panel.timeIndicator.frame.minX, 16)
        XCTAssertEqual(panel.optionsMenu.frame.maxX, Constants.size.width - 16, accuracy: 0.5)
        XCTAssertEqual(panel.optionsMenu.frame.width, 28 + 12 + 28, accuracy: 0.5)
        XCTAssertEqual(panel.timeline.frame.minX - panel.timeIndicator.frame.maxX, 12, accuracy: 0.5)
        XCTAssertEqual(panel.optionsMenu.frame.minX - panel.timeline.frame.maxX, 12, accuracy: 0.5)
        XCTAssertEqual(panel.optionsMenu.frame.midY, panel.frame.height - 8 - 14, accuracy: 0.5)
    }

    func testCompactTimelineIsWiderThanTheDefaultOne() throws {
        let compact = makePlayerView(configuration: .themed(makeTheme()))
        let standard = makePlayerView(configuration: .default)
        for view in [compact, standard] {
            view.controlPanel?.setIndicator(to: 769)
            view.layoutIfNeeded()
        }

        let compactWidth = try XCTUnwrap(compact.controlPanel?.timeline.frame.width)
        let standardWidth = try XCTUnwrap(standard.controlPanel?.timeline.frame.width)
        XCTAssertGreaterThan(compactWidth, standardWidth)
    }

    func testExpandedOptionsFitTheBar() throws {
        let view = makePlayerView(configuration: .themed(makeTheme()))
        let panel = try XCTUnwrap(view.controlPanel)
        panel.expanded = true
        view.setNeedsLayout()
        view.layoutIfNeeded()

        let count = CGFloat(Constants.options.count)
        XCTAssertEqual(panel.optionsMenu.frame.width, count * 28 + (count - 1) * 12, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(panel.optionsMenu.frame.minX, 16)
    }

    func testCompactTimelineHasNoIdleThumbAndSpansTheTrack() throws {
        let timeline = TimelineView(config: try XCTUnwrap(KinescopePlayerViewConfiguration.themed(makeTheme())
                                                              .controlPanel?.timeline),
                                    theme: makeTheme())
        timeline.frame = CGRect(x: 0, y: 0, width: 200, height: 28)
        timeline.setTimeline(to: 0.5)
        timeline.setBufferred(progress: 0.75)
        timeline.layoutIfNeeded()

        let lines = timeline.subviews.filter { $0.frame.height == 4 }
        XCTAssertEqual(lines.map(\.frame.minX), [0, 0, 0])
        XCTAssertEqual(lines.map(\.frame.width), [200, 150, 100])
        XCTAssertTrue(lines.allSatisfy { $0.layer.cornerRadius == 2 })
        let thumbs = timeline.subviews.filter { $0.frame.height != 4 }
        XCTAssertTrue(thumbs.allSatisfy(\.isHidden))
    }

    // MARK: - Private

    private func makeTheme(startScreen: KinescopePlayerTheme.StartScreen = .sdk) -> KinescopePlayerTheme {
        var colors = KinescopePlayerTheme.Colors.default
        colors.iconPressed = Constants.pressed
        colors.playButtonBackground = Constants.pressed.withAlphaComponent(0.64)
        colors.playButtonBackgroundPressed = Constants.pressed
        return KinescopePlayerTheme(
            icons: .init { icon in icon == .play ? UIImage(systemName: "play.fill") : nil },
            colors: colors,
            metrics: .compact,
            startScreen: startScreen
        )
    }

    private func makePlayerView(configuration: KinescopePlayerViewConfiguration) -> KinescopePlayerView {
        let view = KinescopePlayerView(frame: CGRect(origin: .zero, size: Constants.size))
        view.setLayout(with: configuration)
        view.set(options: Constants.options)
        view.controlPanel?.set(live: nil)
        // As after the first frame: the bar is hidden until playback starts.
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
