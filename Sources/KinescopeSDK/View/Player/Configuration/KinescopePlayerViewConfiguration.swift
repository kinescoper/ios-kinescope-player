//
//  KinescopePlayerViewConfiguration.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 30.03.2021.
//

import AVFoundation
import UIKit

/// Appearance preferences of player view
public struct KinescopePlayerViewConfiguration {
    
    let gravity: AVLayerVideoGravity
    let previewService: PreviewService?
    let activityIndicator: KinescopeActivityIndicator
    let overlay: KinescopePlayerOverlayConfiguration?
    let controlPanel: KinescopeControlPanelConfiguration?
    let errorOverlay: KinescopeErrorConfiguration?
    let sideMenu: KinescopeSideMenuConfiguration
    let shadowOverlay: KinescopePlayerShadowOverlayConfiguration?
    let announceSnack: KinescopeAnnounceConfiguration
    let theme: KinescopePlayerTheme
    
    /// - parameter gravity: `AVLayerVideoGravity` value defines how the video is displayed within a layer’s bounds rectangle
    /// - parameter previewService: Implementation of service to load posters into imageView. Set `nil` to disable previews.
    /// - parameter activityIndicator: Custom indicator view used to indicate process of video downloading
    /// - parameter overlay: Configuration of overlay with tapGesture to play/pause video
    ///  Set `nil` to hide overlay (usefull for videos collection with autoplaying)
    /// - parameter controlPanel: Configuration of control panel with play/pause buttons and other controls
    /// Set `nil` to hide control panel
    /// - parameter errorOverlay: Configuration for error view
    /// Set `nil` to hide control panel
    /// - parameter sideMenu: Configuration of side menu with setings
    /// - parameter shadowOverlay: Configuration of shadow overlay beneath side menu
    /// - parameter announceSnack: Configuration of snack bar to announce events.
    /// - parameter theme: Icons, pressed states and geometry of the chrome that the nested configurations do not
    /// cover. To derive the nested configurations from a theme too, use `themed(_:)`.
    public init(gravity: AVLayerVideoGravity,
                previewService: PreviewService?,
                activityIndicator: KinescopeActivityIndicator,
                overlay: KinescopePlayerOverlayConfiguration?,
                controlPanel: KinescopeControlPanelConfiguration?,
                errorOverlay: KinescopeErrorConfiguration?,
                sideMenu: KinescopeSideMenuConfiguration,
                shadowOverlay: KinescopePlayerShadowOverlayConfiguration?,
                announceSnack: KinescopeAnnounceConfiguration,
                theme: KinescopePlayerTheme = .default) {
        self.gravity = gravity
        self.previewService = previewService
        self.activityIndicator = activityIndicator
        self.overlay = overlay
        self.controlPanel = controlPanel
        self.errorOverlay = errorOverlay
        self.sideMenu = sideMenu
        self.shadowOverlay = shadowOverlay
        self.announceSnack = announceSnack
        self.theme = theme
    }
    
}

// MARK: - Defaults

public extension KinescopePlayerViewConfiguration {
    
    static func builder() -> KinescopePlayerViewConfigurationBuilder {
        .init(configuration: .default)
    }

    static let `default`: KinescopePlayerViewConfiguration = .init(
        gravity: .resizeAspect,
        previewService: PreviewNetworkService(),
        activityIndicator: UIActivityIndicatorView(style: .whiteLarge),
        overlay: .default,
        controlPanel: .default,
        errorOverlay: .default,
        sideMenu: .default,
        shadowOverlay: .default,
        announceSnack: .default
    )

    /// Configuration drawn with `theme`: the nested configurations take their colors, fonts, sizes and images
    /// from it, the rest of the chrome reads the theme directly.
    static func themed(_ theme: KinescopePlayerTheme) -> Self {
        let colors = theme.colors
        let fonts = theme.fonts
        let metrics = theme.metrics
        let image = { (icon: KinescopePlayerIcon) in theme.icons.image(for: icon) ?? UIImage() }
        let sideMenu = KinescopeSideMenuConfiguration.builder()
        if let background = theme.menu.background {
            _ = sideMenu.setBackgroundColor(background)
        }
        let shadow = KinescopePlayerShadowOverlayConfiguration.builder()
        if let dimming = theme.menu.dimming {
            _ = shadow.setColor(dimming)
        }
        return .builder()
            .setOverlay(
                KinescopePlayerOverlayConfigurationBuilder(configuration: .default)
                    .setPlayImage(image(.play))
                    .setPauseImage(image(.pause))
                    .setFastForwardImage(image(.fastForward))
                    .setFastBackwardImage(image(.fastBackward))
                    .setPlayBackgroundRadius(metrics.playButtonDiameter / 2)
                    .setPlayBackgroundColor(colors.playButtonBackground)
                    .setBackgroundColor(colors.overlayDim)
                    .setNameConfiguration(
                        KinescopeVideoNameConfigurationBuilder(configuration: .default)
                            .setTitleFont(fonts.title)
                            .setTitleColor(colors.title)
                            .setSubtitleFont(fonts.subtitle)
                            .setSubtitleColor(colors.title)
                            .build()
                    )
                    .build()
            )
            .setControlPanel(
                .builder()
                    .setPreferedHeight(metrics.controlBarHeight)
                    .setTimeIndicator(
                        .builder()
                            .setColor(colors.text)
                            .setFontSize(fonts.time.pointSize)
                            .build()
                    )
                    .setTimeline(
                        .builder()
                            .setActiveColor(colors.timelineProgress)
                            .setInactiveColor(colors.timelineTrack)
                            .setLineHeight(metrics.timelineHeight)
                            .setCircleRadius(metrics.timelineThumbRadius)
                            .build()
                    )
                    .setOptionsMenu(
                        .builder()
                            .setNormalColor(colors.icon)
                            .setHighlightedColor(colors.iconPressed ?? KinescopePlayerOptionsConfiguration.default.highlightedColor)
                            .setIconSize(metrics.optionSize)
                            .build()
                    )
                    .build()
            )
            .setSideMenu(
                sideMenu
                    .setItem(
                        .builder()
                            .setTitleFont(fonts.menuItem)
                            .setValueFont(fonts.menuValue)
                            .build()
                    )
                    .setBar(
                        .builder()
                            .setTitleFont(fonts.menuTitle)
                            .build()
                    )
                    .build()
            )
            .setShadowOverlay(shadow.build())
            .setTheme(theme)
            .build()
    }

    static func accentTimeLineAndPlayButton(with color: UIColor) -> Self {
        .builder()
            .setControlPanel(
                .builder()
                    .setTimeline(
                        .builder()
                            .setActiveColor(color)
                            .build()
                    )
                    .build()
            )
            .setOverlay(
                .builder()
                    .setPlayBackgroundColor(color)
                    .build()
            )
            .build()
    }

}

// MARK: - Builder

public class KinescopePlayerViewConfigurationBuilder {
    
    private var gravity: AVLayerVideoGravity
    private var previewService: PreviewService?
    private var activityIndicator: KinescopeActivityIndicator
    private var overlay: KinescopePlayerOverlayConfiguration?
    private var controlPanel: KinescopeControlPanelConfiguration?
    private var errorOverlay: KinescopeErrorConfiguration?
    private var sideMenu: KinescopeSideMenuConfiguration
    private var shadowOverlay: KinescopePlayerShadowOverlayConfiguration?
    private var announceSnack: KinescopeAnnounceConfiguration
    private var theme: KinescopePlayerTheme
    
    public init(configuration: KinescopePlayerViewConfiguration = .default) {
        self.gravity = configuration.gravity
        self.previewService = configuration.previewService
        self.activityIndicator = configuration.activityIndicator
        self.overlay = configuration.overlay
        self.controlPanel = configuration.controlPanel
        self.errorOverlay = configuration.errorOverlay
        self.sideMenu = configuration.sideMenu
        self.shadowOverlay = configuration.shadowOverlay
        self.announceSnack = configuration.announceSnack
        self.theme = configuration.theme
    }
    
    public func setGravity(_ gravity: AVLayerVideoGravity) -> Self {
        self.gravity = gravity
        return self
    }
    
    public func setPreviewService(_ previewService: PreviewService?) -> Self {
        self.previewService = previewService
        return self
    }
    
    public func setActivityIndicator(_ activityIndicator: KinescopeActivityIndicator) -> Self {
        self.activityIndicator = activityIndicator
        return self
    }
    
    public func setOverlay(_ overlay: KinescopePlayerOverlayConfiguration?) -> Self {
        self.overlay = overlay
        return self
    }
    
    public func setControlPanel(_ controlPanel: KinescopeControlPanelConfiguration?) -> Self {
        self.controlPanel = controlPanel
        return self
    }
    
    public func setErrorOverlay(_ errorOverlay: KinescopeErrorConfiguration?) -> Self {
        self.errorOverlay = errorOverlay
        return self
    }
    
    public func setSideMenu(_ sideMenu: KinescopeSideMenuConfiguration) -> Self {
        self.sideMenu = sideMenu
        return self
    }
    
    public func setShadowOverlay(_ shadowOverlay: KinescopePlayerShadowOverlayConfiguration?) -> Self {
        self.shadowOverlay = shadowOverlay
        return self
    }
    
    public func setAnnounceSnack(_ announceSnack: KinescopeAnnounceConfiguration) -> Self {
        self.announceSnack = announceSnack
        return self
    }
    
    /// Theme for what the nested configurations do not cover; they stay as set. See `KinescopePlayerTheme`.
    public func setTheme(_ theme: KinescopePlayerTheme) -> Self {
        self.theme = theme
        return self
    }
    
    public func build() -> KinescopePlayerViewConfiguration {
        .init(
            gravity: gravity,
            previewService: previewService,
            activityIndicator: activityIndicator,
            overlay: overlay,
            controlPanel: controlPanel,
            errorOverlay: errorOverlay,
            sideMenu: sideMenu,
            shadowOverlay: shadowOverlay,
            announceSnack: announceSnack,
            theme: theme
        )
    }
}
