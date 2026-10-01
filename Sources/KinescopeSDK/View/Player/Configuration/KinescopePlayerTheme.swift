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
    /// Settings menu: leading glyph of the playback speed row. No bundled image: the row has no glyph without it.
    case menuPlaybackSpeed
    /// Settings menu: leading glyph of the subtitles row. No bundled image.
    case menuSubtitles
    /// Settings menu: leading glyph of the quality row. No bundled image.
    case menuQuality
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
    public var startScreen: StartScreen
    public var accessibilityLabels: AccessibilityLabels
    /// Makes the loading indicator of each player view. `nil` keeps
    /// ``KinescopePlayerViewConfiguration``'s `activityIndicator`.
    public var loader: (() -> KinescopeActivityIndicator)?
    public var playPauseAnimation: PlayPauseAnimation
    /// The play/pause button while the chrome is shown. `nil`: as on the start screen (``Metrics/playButtonDiameter``,
    /// ``Colors/playButtonBackground``, ``Metrics/playButtonGlyphScale``).
    public var chromePlayButton: PlayButton?
    public var menu: Menu
    /// What a double tap on a side of the video shows.
    public var seekFeedback: SeekFeedback

    public init(icons: Icons = .default,
                colors: Colors = .default,
                fonts: Fonts = .default,
                metrics: Metrics = .default,
                startScreen: StartScreen = .sdk,
                accessibilityLabels: AccessibilityLabels = .default,
                loader: (() -> KinescopeActivityIndicator)? = nil,
                playPauseAnimation: PlayPauseAnimation = .none,
                chromePlayButton: PlayButton? = nil,
                menu: Menu = .sideSheet,
                seekFeedback: SeekFeedback = .icon) {
        self.icons = icons
        self.colors = colors
        self.fonts = fonts
        self.metrics = metrics
        self.startScreen = startScreen
        self.accessibilityLabels = accessibilityLabels
        self.loader = loader
        self.playPauseAnimation = playPauseAnimation
        self.chromePlayButton = chromePlayButton
        self.menu = menu
        self.seekFeedback = seekFeedback
    }

    /// The SDK's own look.
    public static let `default` = KinescopePlayerTheme()

}

// MARK: - Start screen

public extension KinescopePlayerTheme {

    /// What a prepared player shows before playback starts for the first time.
    enum StartScreen: Hashable {
        /// The SDK's own behavior: the poster goes away once the item is ready, the chrome shows on a tap.
        case sdk
        /// The poster and the play button only, no dimming, title or control bar; a tap outside the button does
        /// nothing. The button is there while the video loads, without a loading indicator; the indicator shows
        /// only after a tap, until playback starts. The usual chrome takes over once playback starts.
        case posterAndPlayButton
    }

}

// MARK: - Accessibility

public extension KinescopePlayerTheme {

    /// VoiceOver labels of the chrome controls. ``default`` takes the SDK's own strings (English, Russian), or
    /// the app's `KinescopeLocalizable.strings` where it overrides a key.
    struct AccessibilityLabels {
        /// The play/pause button while paused.
        public var play: String
        /// The play/pause button while playing.
        public var pause: String
        /// Custom action of the play/pause button: the same as a double tap on the right part of the video.
        public var fastForward: String
        /// Custom action of the play/pause button: the same as a double tap on the left part of the video.
        public var fastBackward: String
        /// The timeline, an adjustable element: swipe up or down to seek.
        public var timeline: String
        /// Options menu: three dots that show every option.
        public var more: String
        public var fullscreen: String
        public var exitFullscreen: String
        /// Options menu: settings with the playback speed, subtitles and quality.
        public var settings: String
        public var attachments: String
        public var download: String
        public var airPlay: String
        public var subtitles: String
        public var pip: String
        /// Side menu: back to the previous level.
        public var menuBack: String
        /// Side menu: close.
        public var menuClose: String

        public init(play: String,
                    pause: String,
                    fastForward: String,
                    fastBackward: String,
                    timeline: String,
                    more: String,
                    fullscreen: String,
                    exitFullscreen: String,
                    settings: String,
                    attachments: String,
                    download: String,
                    airPlay: String,
                    subtitles: String,
                    pip: String,
                    menuBack: String,
                    menuClose: String) {
            self.play = play
            self.pause = pause
            self.fastForward = fastForward
            self.fastBackward = fastBackward
            self.timeline = timeline
            self.more = more
            self.fullscreen = fullscreen
            self.exitFullscreen = exitFullscreen
            self.settings = settings
            self.attachments = attachments
            self.download = download
            self.airPlay = airPlay
            self.subtitles = subtitles
            self.pip = pip
            self.menuBack = menuBack
            self.menuClose = menuClose
        }

        public static var `default`: AccessibilityLabels {
            AccessibilityLabels(
                play: L10n.Player.play,
                pause: L10n.Player.pause,
                fastForward: L10n.Player.fastForward,
                fastBackward: L10n.Player.fastBackward,
                timeline: L10n.Player.timeline,
                more: L10n.Player.moreOptions,
                fullscreen: L10n.Player.fullscreen,
                exitFullscreen: L10n.Player.exitFullscreen,
                settings: L10n.Player.settings,
                attachments: L10n.Player.attachments,
                download: L10n.Player.download,
                airPlay: L10n.Player.airplay,
                subtitles: L10n.Player.subtitles,
                pip: L10n.Player.pictureInPicture,
                menuBack: L10n.Player.back,
                menuClose: L10n.Player.close
            )
        }

        /// The label of an option button; `nil` for a custom option, which has none.
        func label(for option: KinescopePlayerOption, isFullscreen: Bool) -> String? {
            switch option {
            case .more:
                return more
            case .fullscreen:
                return isFullscreen ? exitFullscreen : fullscreen
            case .settings:
                return settings
            case .attachments:
                return attachments
            case .download:
                return download
            case .airPlay:
                return airPlay
            case .subtitles:
                return subtitles
            case .pip:
                return pip
            case .custom:
                return nil
            }
        }
    }

}

// MARK: - Play/pause animation

public extension KinescopePlayerTheme {

    /// How the play/pause button changes its glyph and answers a tap.
    struct PlayPauseAnimation {
        /// `true` draws the glyph as a shape that morphs between the play triangle and the pause bars, sized
        /// like the play and pause images; `false` swaps the images.
        public var morphsGlyph: Bool
        /// Length of the morph and of the pressed state fading out after a tap. `0`: no animation.
        public var duration: TimeInterval
        /// Rounding of the morphing shape's corners.
        public var glyphCornerRadius: CGFloat

        public init(morphsGlyph: Bool, duration: TimeInterval, glyphCornerRadius: CGFloat = 1) {
            self.morphsGlyph = morphsGlyph
            self.duration = duration
            self.glyphCornerRadius = glyphCornerRadius
        }

        /// The SDK's own behavior: the images swap, the pressed state goes at once.
        public static let none = PlayPauseAnimation(morphsGlyph: false, duration: 0)
        /// Like Android's media3 player: a 200 ms morph, the pressed state fading out as long.
        public static let morph = PlayPauseAnimation(morphsGlyph: true, duration: 0.2)
    }

}

// MARK: - Play button

public extension KinescopePlayerTheme {

    /// The play/pause button at the center of the overlay.
    struct PlayButton {
        /// Diameter of the button and of its background circle.
        public var diameter: CGFloat
        /// The circle. `.clear` draws the glyph alone; then a press tints the glyph with ``Colors/iconPressed``
        /// instead of filling the circle.
        public var background: UIColor
        /// Scale of a supplied play/pause glyph inside the button.
        public var glyphScale: CGFloat
        /// Shift of the glyph from the button center.
        public var glyphOffset: UIOffset

        public init(diameter: CGFloat, background: UIColor, glyphScale: CGFloat, glyphOffset: UIOffset = .zero) {
            self.diameter = diameter
            self.background = background
            self.glyphScale = glyphScale
            self.glyphOffset = glyphOffset
        }

        /// Figma «Player» `M / Play` in the paused `Controls` (`20485:44511`): a 56-point glyph without a circle,
        /// a 24-point design system icon drawn like an instance resized from 24 to 56.
        public static let glyphOnly = PlayButton(diameter: 56, background: .clear, glyphScale: 56.0 / 24.0)
    }

}

// MARK: - Seek feedback

public extension KinescopePlayerTheme {

    /// The answer to a double tap on the left or right part of the video, which seeks back or forward.
    struct SeekFeedback {

        public enum Style {
            /// The SDK's own: the ``KinescopePlayerIcon/fastForward`` or ``KinescopePlayerIcon/fastBackward`` glyph
            /// grows and fades out at the side.
            case icon
            /// Figma «Player» `Rewind` (`18600:33369`): the tapped side lit with `fill` over `widthRatio` of the
            /// width, its inner edge bulging by `edgeDepth`, with three arrows and the seek length in its center.
            case sideArea(fill: UIColor, widthRatio: CGFloat, edgeDepth: CGFloat)
        }

        public var style: Style
        /// The seek length under the arrows.
        public var font: UIFont
        public var textColor: UIColor
        /// The seek length in seconds as text; `nil` in `init` reads the SDK's strings («%d sec», «%d сек»).
        public var text: (Int) -> String
        /// How long the side stays lit.
        public var duration: TimeInterval

        public init(style: Style,
                    font: UIFont = .systemFont(ofSize: 12, weight: .medium),
                    textColor: UIColor = .white,
                    text: ((Int) -> String)? = nil,
                    duration: TimeInterval = 0.6) {
            self.style = style
            self.font = font
            self.textColor = textColor
            self.text = text ?? { L10n.Player.seekSeconds($0) }
            self.duration = duration
        }

        /// The SDK's own glyph.
        public static let icon = SeekFeedback(style: .icon)

        /// Figma «Player» `Rewind`: 163 of 375 points lit with `Surface/player/rewind/default` (white 16 %), the
        /// inner edge bulging by 32, `Lead Body/12 Medium` white text.
        public static let sideArea = SeekFeedback(
            style: .sideArea(fill: UIColor(white: 1, alpha: 0.16), widthRatio: 163.0 / 375.0, edgeDepth: 32)
        )
    }

}

// MARK: - Menu

public extension KinescopePlayerTheme {

    /// How the settings, speed, quality and subtitles menus are shown.
    struct Menu {

        public enum Presentation: Equatable {
            /// The SDK's own: a sheet over the whole height that slides in from the trailing edge, with a title
            /// bar and a close button on every level.
            case sideSheet
            /// A card in the trailing bottom corner (Figma «Player» `Settings/Normal`, `20485:44516`): no title
            /// on the root level, a back row with the title on a nested one, no close button (a tap outside closes).
            /// - parameter width: Card width, at most the player width less the margins.
            /// - parameter margins: Distance from the player edges; the card grows up from the bottom margin
            /// and scrolls once it reaches the top one.
            case card(width: CGFloat, cornerRadius: CGFloat, margins: UIEdgeInsets)
        }

        public var presentation: Presentation
        /// Background of the menu. `nil` keeps ``KinescopeSideMenuConfiguration``'s.
        public var background: UIColor?
        /// Laid behind the menu over the player. `nil` keeps ``KinescopePlayerShadowOverlayConfiguration``'s.
        public var dimming: UIColor?
        /// Height of a row, the back row included.
        public var rowHeight: CGFloat
        /// Padding of the rows inside the card: top and bottom of the list, leading and trailing of a row.
        public var contentInsets: UIEdgeInsets

        public init(presentation: Presentation,
                    background: UIColor? = nil,
                    dimming: UIColor? = nil,
                    rowHeight: CGFloat = 36,
                    contentInsets: UIEdgeInsets = .zero) {
            self.presentation = presentation
            self.background = background
            self.dimming = dimming
            self.rowHeight = rowHeight
            self.contentInsets = contentInsets
        }

        /// The SDK's own side sheet.
        public static let sideSheet = Menu(presentation: .sideSheet)

        /// Figma «Player» settings menu: a 280-point card with 6-point corners, 16 from the trailing edge and
        /// 44 from the bottom, `#111`, 36-point rows padded 16 at the sides and 8 at the top and bottom, no dimming.
        public static let card = Menu(
            presentation: .card(width: 280, cornerRadius: 6, margins: UIEdgeInsets(top: 8, left: 16, bottom: 44, right: 16)),
            background: UIColor(red: 0x11 / 255.0, green: 0x11 / 255.0, blue: 0x11 / 255.0, alpha: 1),
            dimming: .clear,
            rowHeight: 36,
            contentInsets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        )

        var isCard: Bool {
            if case .card = presentation {
                return true
            }
            return false
        }
    }

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
        /// Laid over the play/pause button background while pressed, like a design system pressed layer.
        /// `nil`: no layer. Combines with ``playButtonBackgroundPressed``.
        public var playButtonPressedOverlay: UIColor?
        /// Tint of the play/pause glyph. `nil` draws the image as is.
        public var playButtonIcon: UIColor?
        /// Dimming of the video while the chrome is shown.
        public var overlayDim: UIColor
        /// Video title and subtitle over the video.
        public var title: UIColor
        /// Background of the control bar, drawn inside ``Metrics/controlBarInsets`` with
        /// ``Metrics/controlBarCornerRadius``. `nil`: no background.
        public var controlBarBackground: UIColor?
        /// Halo around the timeline thumb while it is dragged. `nil`: no halo.
        public var timelineThumbHalo: UIColor?
        /// Circle under the three dots option, as big as the option. `nil`: no circle.
        public var moreBackground: UIColor?

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
                    title: UIColor,
                    playButtonPressedOverlay: UIColor? = nil,
                    controlBarBackground: UIColor? = nil,
                    timelineThumbHalo: UIColor? = UIColor(red: 1, green: 1, blue: 1, alpha: 0.16),
                    moreBackground: UIColor? = nil) {
            self.icon = icon
            self.iconPressed = iconPressed
            self.text = text
            self.timelineTrack = timelineTrack
            self.timelineBuffered = timelineBuffered
            self.timelineProgress = timelineProgress
            self.timelineThumb = timelineThumb
            self.playButtonBackground = playButtonBackground
            self.playButtonBackgroundPressed = playButtonBackgroundPressed
            self.playButtonPressedOverlay = playButtonPressedOverlay
            self.playButtonIcon = playButtonIcon
            self.overlayDim = overlayDim
            self.title = title
            self.controlBarBackground = controlBarBackground
            self.timelineThumbHalo = timelineThumbHalo
            self.moreBackground = moreBackground
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
        /// Padding of the time, the timeline and the options inside the control bar background.
        public var controlBarPadding: UIEdgeInsets
        /// Rounding of the control bar background, at most half its height.
        public var controlBarCornerRadius: CGFloat

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
                    timeReservesHours: Bool,
                    controlBarPadding: UIEdgeInsets = .zero,
                    controlBarCornerRadius: CGFloat = 0) {
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
            self.controlBarPadding = controlBarPadding
            self.controlBarCornerRadius = controlBarCornerRadius
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

        /// Kinescope mobile app player (Figma Kinescope-App `136:19210` control bar, `69:20042` play button):
        /// bar 16 from the sides and 8 from the bottom, gap 12, 28-point options 12 apart, 64-point play button
        /// with the 24-point glyph at its own size in the center like the video card, rounded 4-point track without
        /// an idle thumb, time as wide as its text.
        public static let compact = Metrics(
            controlBarInsets: UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16),
            controlBarHeight: 28,
            controlBarSpacing: 12,
            optionSize: 28,
            optionSpacing: 12,
            collapsedOptionsCount: 2,
            iconGlyphScale: 28.0 / 24.0,
            playButtonDiameter: 64,
            playButtonGlyphScale: 1,
            playButtonGlyphOffset: .zero,
            timelineHeight: 4,
            timelineCornerRadius: 2,
            timelineThumbRadius: 6,
            timelineThumbVisibleWhenIdle: false,
            timeReservesHours: false
        )

        /// Figma «Player» file (`20485:44504`): a pill bar 343×44 16 from the sides and 8 from the bottom, padded 8
        /// with 24-point rounding, a 28-point row with 12-point gaps, 28-point options 12 apart, the 72-point start
        /// play button with a 36-point glyph 2 points right of the center, a rounded 4-point track with a 16-point
        /// thumb only while dragged, time as wide as its text.
        public static let player = Metrics(
            controlBarInsets: UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16),
            controlBarHeight: 28,
            controlBarSpacing: 12,
            optionSize: 28,
            optionSpacing: 12,
            collapsedOptionsCount: 2,
            iconGlyphScale: 28.0 / 24.0,
            playButtonDiameter: 72,
            playButtonGlyphScale: 36.0 / 24.0,
            playButtonGlyphOffset: UIOffset(horizontal: 2, vertical: 0),
            timelineHeight: 4,
            timelineCornerRadius: 2,
            timelineThumbRadius: 8,
            timelineThumbVisibleWhenIdle: false,
            timeReservesHours: false,
            controlBarPadding: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8),
            controlBarCornerRadius: 24
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
        case .menuPlaybackSpeed, .menuSubtitles, .menuQuality:
            return nil
        }
    }

}
