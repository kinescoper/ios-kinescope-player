import XCTest
@testable import KinescopeSDK

final class KinescopePlayerThemeTests: XCTestCase {

    private enum Constants {
        static let pressed = UIColor(red: 0x61 / 255, green: 0x61 / 255, blue: 0xfc / 255, alpha: 1)
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
        XCTAssertEqual(overlay.playBackgroundRadius, 36)
        XCTAssertEqual(overlay.playImage.renderingMode, .alwaysTemplate)
    }

    // MARK: - Icons

    func testIconsFallBackToBundledImages() {
        let icons = KinescopePlayerTheme.Icons([.more: UIImage()])

        XCTAssertNotNil(icons.custom(.more))
        XCTAssertNil(icons.custom(.pip))
        XCTAssertEqual(icons.image(for: .more)?.renderingMode, .alwaysTemplate)
        XCTAssertNotNil(icons.image(for: .pip))
        for icon in KinescopePlayerIcon.allCases {
            XCTAssertNotNil(icon.bundledImageName, "\(icon) has no bundled image")
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
        let circle = try XCTUnwrap(overlay.firstSubview { $0.layer.cornerRadius == 36 })

        overlay.setPlayButtonPressed(true)
        XCTAssertEqual(circle.backgroundColor, theme.colors.playButtonBackgroundPressed)
        overlay.setPlayButtonPressed(false)
        XCTAssertEqual(circle.backgroundColor, theme.colors.playButtonBackground)
    }

    // MARK: - Geometry

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

    private func makeTheme() -> KinescopePlayerTheme {
        var colors = KinescopePlayerTheme.Colors.default
        colors.iconPressed = Constants.pressed
        colors.playButtonBackground = Constants.pressed.withAlphaComponent(0.64)
        colors.playButtonBackgroundPressed = Constants.pressed
        return KinescopePlayerTheme(
            icons: .init { icon in icon == .play ? UIImage(systemName: "play.fill") : nil },
            colors: colors,
            metrics: .compact
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
