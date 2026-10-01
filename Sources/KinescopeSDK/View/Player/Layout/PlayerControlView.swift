//
//  PlayerControlView.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 23.03.2021.
//
// swiftlint:disable implicitly_unwrapped_optional

import UIKit

protocol PlayerControlInput: TimelineInput, TimeIndicatorInput, PlayerControlOptionsInput { 
    func set(live: Bool?)
}

protocol PlayerControlOutput: TimelineOutput {
    func didSelect(option: KinescopePlayerOption)
}

class PlayerControlView: UIControl {
    
    private(set) var liveIndicator: LiveIndicatorView!
    private(set) var timeIndicator: TimeIndicatorView!
    private(set) var timeline: TimelineView!
    private(set) var optionsMenu: PlayerControlOptionsView!
    /// The bar's own background (``KinescopePlayerTheme/Colors/controlBarBackground``), inside the insets.
    private(set) var barBackground = UIView()

    private let config: KinescopeControlPanelConfiguration
    private let theme: KinescopePlayerTheme
    private let isFullscreen: Bool

    weak var output: PlayerControlOutput?

    init(config: KinescopeControlPanelConfiguration, theme: KinescopePlayerTheme = .default, isFullscreen: Bool = false) {
        self.config = config
        self.theme = theme
        self.isFullscreen = isFullscreen
        super.init(frame: .zero)
        setupInitialState(with: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The bar is lower than a 44-point target: touches just outside it reach the options and the timeline when
    /// their grown areas take them; anything else there stays with the views behind.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.contains(point) || [optionsMenu, timeline].contains { control in
            guard let control, !control.isHidden, control.alpha > 0.01 else {
                return false
            }
            return control.point(inside: convert(point, to: control), with: event)
        }
    }

    override var intrinsicContentSize: CGSize {
        let insets = theme.metrics.controlBarInsets
        let padding = theme.metrics.controlBarPadding
        let height = config.preferedHeight + insets.top + insets.bottom + padding.top + padding.bottom
        return .init(width: .greatestFiniteMagnitude, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        barBackground.layer.cornerRadius = min(theme.metrics.controlBarCornerRadius, barBackground.bounds.height / 2)
    }

    // MARK: - Internal Properties

    var expanded: Bool = false {
        didSet {
            optionsMenu.isExpanded = self.expanded
            let alpha: CGFloat = self.expanded ? 0.0 : 1.0
            self.timeIndicator.alpha = alpha
            self.timeline.alpha = alpha
        }
    }

}

// MARK: - PlayerControlInput

extension PlayerControlView: PlayerControlInput {

    func getCustomOptionView(by id: AnyHashable) -> UIView? {
        optionsMenu.getCustomOptionView(by: id)
    }

    func set(live: Bool?) {
        if let live {
            timeIndicator.isHidden = true
            liveIndicator.isHidden = false
            liveIndicator.set(animated: live)
        } else {
            liveIndicator.isHidden = true
            timeIndicator.isHidden = false
        }
    }

    func setTimeline(to position: CGFloat) {
        timeline.setTimeline(to: position)
    }

    func setBufferred(progress: CGFloat) {
        timeline.setBufferred(progress: progress)
    }

    func setIndicator(to time: TimeInterval) {
        timeIndicator.setIndicator(to: time)
    }

    func set(options: [KinescopePlayerOption]) {
        optionsMenu.set(options: options)
    }

    func set(subtitleOn: Bool) {
        optionsMenu.set(subtitleOn: subtitleOn)
    }

}

// MARK: - PlayerControlOptionsOutput

extension PlayerControlView: PlayerControlOptionsOutput {

    func didOptions(expanded: Bool) {
        self.expanded = expanded
    }

    func didSelect(option: KinescopePlayerOption) {
        switch option {
        case .more:
            self.expanded.toggle()
        default:
            break
        }
        output?.didSelect(option: option)
    }

}

// MARK: - TimelineOutput

extension PlayerControlView: TimelineOutput {

    func onUpdate() {
        output?.onUpdate()
    }

    func onTimelinePositionChanged(to position: CGFloat) {
        output?.onTimelinePositionChanged(to: position)
    }

}

// MARK: - Private

private extension PlayerControlView {

    func setupInitialState(with config: KinescopeControlPanelConfiguration) {
        // configure control panel

        backgroundColor = config.backgroundColor
        
        liveIndicator = LiveIndicatorView(config: config.liveIndicator)
        timeIndicator = TimeIndicatorView(config: config.timeIndicator, theme: theme)
        timeline = TimelineView(config: config.timeline, theme: theme)
        optionsMenu = PlayerControlOptionsView(config: config.optionsMenu, theme: theme, isFullscreen: isFullscreen)

        barBackground.backgroundColor = theme.colors.controlBarBackground
        barBackground.isHidden = theme.colors.controlBarBackground == nil
        barBackground.isUserInteractionEnabled = false
        barBackground.layer.cornerCurve = .continuous
        barBackground.layer.masksToBounds = true

        addSubviews(barBackground, liveIndicator, timeIndicator, timeline, optionsMenu)

        setupConstraints()

        optionsMenu.output = self
        timeline.output = self
    }

    func setupConstraints() {
        timeIndicator.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        timeIndicator.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        timeline.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        timeline.setContentHuggingPriority(.defaultLow, for: .horizontal)

        // Expanded options win over the time and the timeline, which are hidden meanwhile.
        optionsMenu.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        optionsMenu.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let insets = theme.metrics.controlBarInsets
        let padding = theme.metrics.controlBarPadding
        let spacing = theme.metrics.controlBarSpacing
        let content = UILayoutGuide()
        addLayoutGuide(content)

        NSLayoutConstraint.activate([
            barBackground.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            barBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            barBackground.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            barBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
            content.topAnchor.constraint(equalTo: barBackground.topAnchor, constant: padding.top),
            content.leadingAnchor.constraint(equalTo: barBackground.leadingAnchor, constant: padding.left),
            content.trailingAnchor.constraint(equalTo: barBackground.trailingAnchor, constant: -padding.right),
            content.bottomAnchor.constraint(equalTo: barBackground.bottomAnchor, constant: -padding.bottom),
            liveIndicator.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            liveIndicator.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            timeIndicator.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            timeIndicator.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            timeline.leadingAnchor.constraint(equalTo: timeIndicator.trailingAnchor, constant: spacing),
            timeline.topAnchor.constraint(equalTo: content.topAnchor),
            timeline.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            timeline.trailingAnchor.constraint(equalTo: optionsMenu.leadingAnchor, constant: -spacing),
            optionsMenu.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            optionsMenu.trailingAnchor.constraint(equalTo: content.trailingAnchor)
        ])

    }

}
