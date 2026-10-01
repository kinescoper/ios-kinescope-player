//
//  KinescopePlayerTheme.swift
//  KinescopeSDK
//

import UIKit

/// Glyphs of the player chrome that a ``KinescopePlayerTheme`` can replace.
public enum KinescopePlayerIcon: Hashable, CaseIterable {
    /// Play glyph of the button at the center of the overlay.
    case play
    /// Pause glyph of the button at the center of the overlay.
    case pause
    /// Shown on a double tap at the right part of the overlay.
    case fastForward
    /// Shown on a double tap at the left part of the overlay.
    case fastBackward
    /// Options menu: three dots that expand the menu.
    case more
    /// Options menu: enter full screen.
    case fullscreen
    /// Options menu: leave full screen, shown in place of ``fullscreen`` while the player is full screen.
    case exitFullscreen
    /// Options menu: settings side menu.
    case settings
    /// Options menu: attachments side menu.
    case attachments
    /// Options menu: download side menu.
    case download
    /// Options menu: AirPlay route picker.
    case airPlay
    /// Options menu: AirPlay route picker while a wireless route is active.
    case airPlayActive
    /// Options menu: subtitles while they are off.
    case subtitles
    /// Options menu: subtitles while they are on.
    case subtitlesOn
    /// Options menu: Picture in Picture.
    case pip
    /// Side menu: back to the previous level.
    case menuBack
    /// Side menu: close.
    case menuClose
    /// Side menu: row that opens a nested level.
    case menuDisclosure
    /// Side menu: the selected row.
    case menuCheckmark
}

/// Visual theme of the player chrome: icons, colors, fonts and metrics.
///
/// Lets an app draw the player with its own design system without the SDK depending on it. ``default`` keeps
/// the SDK's own look. Apply a theme with ``KinescopePlayerViewConfiguration/themed(_:)`` (it also fills the
/// colors, fonts and sizes of the nested configurations from the theme) or with
/// ``KinescopePlayerViewConfigurationBuilder/setTheme(_:)`` on top of hand-made nested configurations.
public struct KinescopePlayerTheme {

    public var icons: Icons
    public var colors: Colors
    public var fonts: Fonts
    public var metrics: Metrics

    public init(icons: Icons = .default,
                colors: Colors = .default,
                fonts: Fonts = .default,
                metrics: Metrics = .default) {
        self.icons = icons
        self.colors = colors
        self.fonts = fonts
        self.metrics = metrics
    }

    /// The SDK's own look.
    public static let `default` = KinescopePlayerTheme()

}

// MARK: - Icons

public extension KinescopePlayerTheme {

    /// Supplies glyphs for ``KinescopePlayerIcon``; `nil` falls back to the SDK's bundled image.
    ///
    /// Supplied glyphs are drawn as templates tinted with ``Colors/icon`` (``Colors/playButtonIcon`` on the play
    /// button), centered in their frame at their own size times ``Metrics/iconGlyphScale``: pass glyphs cut to
    /// their path, like design system icons, and they are not stretched to the frame.
    struct Icons {

        private let provider: (KinescopePlayerIcon) -> UIImage?

        /// - parameter provider: Called on the main thread while the chrome is built.
        public init(_ provider: @escaping (KinescopePlayerIcon) -> UIImage?) {
            self.provider = provider
        }

        public init(_ images: [KinescopePlayerIcon: UIImage]) {
            self.provider = { images[$0] }
        }

        public static let `default` = Icons { _ in nil }

        /// The supplied glyph, if any.
        public func custom(_ icon: KinescopePlayerIcon) -> UIImage? {
            provider(icon)
        }

        /// The supplied glyph as a template, or the bundled image as is.
        func image(for icon: KinescopePlayerIcon) -> UIImage? {
            if let custom = provider(icon) {
                return custom.withRenderingMode(.alwaysTemplate)
            }
            return icon.bundledImageName.map { UIImage.image(named: $0) }
        }

    }

}

// MARK: - Colors

public extension KinescopePlayerTheme {

    struct Colors {
        /// Option icons and the AirPlay glyph.
        public var icon: UIColor
        /// Option icons while pressed. `nil` keeps the system dimming of a pressed button.
        public var iconPressed: UIColor?
        /// Current time next to the timeline.
        public var text: UIColor
        /// Timeline: the whole track.
        public var timelineTrack: UIColor
        /// Timeline: the buffered part.
        public var timelineBuffered: UIColor
        /// Timeline: the played part.
        public var timelineProgress: UIColor
        /// Timeline: the thumb.
        public var timelineThumb: UIColor
        /// Background of the play/pause button.
        public var playButtonBackground: UIColor
        /// Background of the play/pause button while pressed. `nil`: no pressed state.
        public var playButtonBackgroundPressed: UIColor?
        /// Tint of the play/pause glyph. `nil` draws the image as is.
        public var playButtonIcon: UIColor?
        /// Dimming of the video while the chrome is shown.
        public var overlayDim: UIColor
        /// Video title and subtitle over the video.
        public var title: UIColor

        public init(icon: UIColor,
                    iconPressed: UIColor?,
                    text: UIColor,
                    timelineTrack: UIColor,
                    timelineBuffered: UIColor,
                    timelineProgress: UIColor,
                    timelineThumb: UIColor,
                    playButtonBackground: UIColor,
                    playButtonBackgroundPressed: UIColor?,
                    playButtonIcon: UIColor?,
                    overlayDim: UIColor,
                    title: UIColor) {
            self.icon = icon
            self.iconPressed = iconPressed
            self.text = text
            self.timelineTrack = timelineTrack
            self.timelineBuffered = timelineBuffered
            self.timelineProgress = timelineProgress
            self.timelineThumb = timelineThumb
            self.playButtonBackground = playButtonBackground
            self.playButtonBackgroundPressed = playButtonBackgroundPressed
            self.playButtonIcon = playButtonIcon
            self.overlayDim = overlayDim
            self.title = title
        }

        public static let `default` = Colors(
            icon: .white,
            iconPressed: nil,
            text: .white,
            timelineTrack: UIColor(red: 1, green: 1, blue: 1, alpha: 0.32),
            timelineBuffered: UIColor(red: 1, green: 1, blue: 1, alpha: 0.32),
            timelineProgress: UIColor(red: 0.38, green: 0.38, blue: 0.988, alpha: 1),
            timelineThumb: UIColor(red: 0.38, green: 0.38, blue: 0.988, alpha: 1),
            playButtonBackground: UIColor(red: 0.38, green: 0.38, blue: 0.988, alpha: 1),
            playButtonBackgroundPressed: nil,
            playButtonIcon: nil,
            overlayDim: UIColor.black.withAlphaComponent(0.3),
            title: UIColor.white.withAlphaComponent(0.8)
        )
    }

}

// MARK: - Fonts

public extension KinescopePlayerTheme {

    struct Fonts {
        /// Current time next to the timeline; the SDK makes its digits monospaced.
        public var time: UIFont
        /// Video title over the video.
        public var title: UIFont
        /// Video subtitle over the video.
        public var subtitle: UIFont
        /// Side menu: title of a level.
        public var menuTitle: UIFont
        /// Side menu: row title.
        public var menuItem: UIFont
        /// Side menu: row value.
        public var menuValue: UIFont

        public init(time: UIFont,
                    title: UIFont,
                    subtitle: UIFont,
                    menuTitle: UIFont,
                    menuItem: UIFont,
                    menuValue: UIFont) {
            self.time = time
            self.title = title
            self.subtitle = subtitle
            self.menuTitle = menuTitle
            self.menuItem = menuItem
            self.menuValue = menuValue
        }

        public static let `default` = Fonts(
            time: .systemFont(ofSize: 14),
            title: .systemFont(ofSize: 14.0, weight: .medium),
            subtitle: .systemFont(ofSize: 12.0),
            menuTitle: .systemFont(ofSize: 14.0, weight: .medium),
            menuItem: .systemFont(ofSize: 14.0, weight: .regular),
            menuValue: .systemFont(ofSize: 12.0)
        )
    }

}

// MARK: - Metrics

public extension KinescopePlayerTheme {

    struct Metrics {
        /// Control bar insets inside the player, on top of its safe area.
        public var controlBarInsets: UIEdgeInsets
        /// Control bar height, without insets.
        public var controlBarHeight: CGFloat
        /// Gap between the time, the timeline and the options menu.
        public var controlBarSpacing: CGFloat
        /// Square frame of an option button.
        public var optionSize: CGFloat
        /// Gap between option buttons.
        public var optionSpacing: CGFloat
        /// Options shown while the menu is collapsed, the three dots included.
        public var collapsedOptionsCount: Int
        /// Scale of a supplied glyph inside its frame: `28 / 24` draws a 24-point design system icon in a 28-point
        /// frame like a Figma instance resized from 24 to 28.
        public var iconGlyphScale: CGFloat
        /// Diameter of the play/pause button.
        public var playButtonDiameter: CGFloat
        /// Scale of a supplied play/pause glyph inside the button.
        public var playButtonGlyphScale: CGFloat
        /// Shift of the play/pause glyph from the button center, for an optical center of a glyph cut to its path.
        public var playButtonGlyphOffset: UIOffset
        /// Height of the timeline track.
        public var timelineHeight: CGFloat
        /// Corner radius of the timeline track and its parts.
        public var timelineCornerRadius: CGFloat
        /// Radius of the timeline thumb.
        public var timelineThumbRadius: CGFloat
        /// `false` shows the thumb only while the timeline is dragged and lets the track reach its edges.
        public var timelineThumbVisibleWhenIdle: Bool
        /// `true` reserves the width of `H:MM:SS` for the time; `false` sizes it to the current text.
        public var timeReservesHours: Bool

        public init(controlBarInsets: UIEdgeInsets,
                    controlBarHeight: CGFloat,
                    controlBarSpacing: CGFloat,
                    optionSize: CGFloat,
                    optionSpacing: CGFloat,
                    collapsedOptionsCount: Int,
                    iconGlyphScale: CGFloat,
                    playButtonDiameter: CGFloat,
                    playButtonGlyphScale: CGFloat,
                    playButtonGlyphOffset: UIOffset,
                    timelineHeight: CGFloat,
                    timelineCornerRadius: CGFloat,
                    timelineThumbRadius: CGFloat,
                    timelineThumbVisibleWhenIdle: Bool,
                    timeReservesHours: Bool) {
            self.controlBarInsets = controlBarInsets
            self.controlBarHeight = controlBarHeight
            self.controlBarSpacing = controlBarSpacing
            self.optionSize = optionSize
            self.optionSpacing = optionSpacing
            self.collapsedOptionsCount = collapsedOptionsCount
            self.iconGlyphScale = iconGlyphScale
            self.playButtonDiameter = playButtonDiameter
            self.playButtonGlyphScale = playButtonGlyphScale
            self.playButtonGlyphOffset = playButtonGlyphOffset
            self.timelineHeight = timelineHeight
            self.timelineCornerRadius = timelineCornerRadius
            self.timelineThumbRadius = timelineThumbRadius
            self.timelineThumbVisibleWhenIdle = timelineThumbVisibleWhenIdle
            self.timeReservesHours = timeReservesHours
        }

        /// The SDK's own geometry.
        public static let `default` = Metrics(
            controlBarInsets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16),
            controlBarHeight: 40,
            controlBarSpacing: 16,
            optionSize: 24,
            optionSpacing: 8,
            collapsedOptionsCount: 2,
            iconGlyphScale: 1,
            playButtonDiameter: 96,
            playButtonGlyphScale: 1,
            playButtonGlyphOffset: .zero,
            timelineHeight: 4,
            timelineCornerRadius: 0,
            timelineThumbRadius: 8,
            timelineThumbVisibleWhenIdle: true,
            timeReservesHours: true
        )

        /// Kinescope mobile app player (Figma Kinescope-App `136:19210` control bar, `1649:26934` play button):
        /// bar 16 from the sides and 8 from the bottom, gap 12, 28-point options 12 apart, 72-point play button
        /// with a 24-point glyph drawn at 36 and moved 2 to the right like the Figma `M / Play` instance, rounded
        /// 4-point track without an idle thumb, time as wide as its text.
        public static let compact = Metrics(
            controlBarInsets: UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16),
            controlBarHeight: 28,
            controlBarSpacing: 12,
            optionSize: 28,
            optionSpacing: 12,
            collapsedOptionsCount: 2,
            iconGlyphScale: 28.0 / 24.0,
            playButtonDiameter: 72,
            playButtonGlyphScale: 1.5,
            playButtonGlyphOffset: UIOffset(horizontal: 2, vertical: 0),
            timelineHeight: 4,
            timelineCornerRadius: 2,
            timelineThumbRadius: 6,
            timelineThumbVisibleWhenIdle: false,
            timeReservesHours: false
        )
    }

}

// MARK: - Bundled images

extension KinescopePlayerIcon {

    /// SDK asset for the icon; `nil` where the SDK has none of its own.
    var bundledImageName: String? {
        switch self {
        case .play:
            return "play"
        case .pause:
            return "pause"
        case .fastForward:
            return "fastForward"
        case .fastBackward:
            return "fastBackward"
        case .more:
            return "more"
        case .fullscreen, .exitFullscreen:
            return "fullscreen"
        case .settings:
            return "settings"
        case .attachments:
            return "attachments"
        case .download:
            return "download"
        case .airPlay:
            return "airPlay"
        case .airPlayActive:
            return "airPlayActive"
        case .subtitles:
            return "subtitles"
        case .subtitlesOn:
            return "subtitlesSelected"
        case .pip:
            return "pip"
        case .menuBack:
            return "back"
        case .menuClose:
            return "close"
        case .menuDisclosure:
            return "forward"
        case .menuCheckmark:
            return "checkmark"
        }
    }

}
