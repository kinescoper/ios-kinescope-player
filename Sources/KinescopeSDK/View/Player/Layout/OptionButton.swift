//
//  OptionButton.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 01.04.2021.
//

import UIKit

final class OptionButton: UIButton {

    let option: KinescopePlayerOption

    private let theme: KinescopePlayerTheme
    private let normalColor: UIColor
    /// ``KinescopePlayerTheme/Colors/optionPressedBackground`` while pressed.
    private(set) var pressedCircle: UIView?

    init(option: KinescopePlayerOption,
         theme: KinescopePlayerTheme = .default,
         normalColor: UIColor = .white,
         isFullscreen: Bool = false) {
        self.option = option
        self.theme = theme
        self.normalColor = normalColor
        super.init(frame: .zero)
        setupInitialState(isFullscreen: isFullscreen)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIButton

    override var isHighlighted: Bool {
        didSet {
            updateTint()
        }
    }

    /// A 28-point option still takes taps 44 points wide and high.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        minimumHitArea.contains(point)
    }

}

// MARK: - Private

private extension OptionButton {

    func setupInitialState(isFullscreen: Bool) {
        let scale = theme.metrics.iconGlyphScale
        let icons = theme.icons
        let themeIcon = option.themeIcon(isFullscreen: isFullscreen)
        let custom = themeIcon.flatMap { icons.custom($0) }

        let normalImage = themeIcon.flatMap { icons.image(for: $0) } ?? option.icon
        setImage(custom == nil ? normalImage : normalImage.scaled(by: scale), for: .normal)

        let selectedIcon = option.selectedThemeIcon
        if let selectedIcon, let selectedImage = icons.image(for: selectedIcon) {
            let image = icons.custom(selectedIcon) == nil ? selectedImage : selectedImage.scaled(by: scale)
            setImage(image, for: .selected)
            setImage(image, for: [.selected, .highlighted])
        } else if let iconSelected = option.iconSelected {
            setImage(iconSelected, for: .selected)
        }

        // A pressed icon changes its color or gets a circle, not the system dimming.
        if theme.colors.iconPressed != nil || theme.colors.optionPressedBackground != nil {
            adjustsImageWhenHighlighted = false
        }
        imageView?.contentMode = .center
        if let background = theme.colors.optionPressedBackground {
            configurePressedCircle(color: background)
        }
        accessibilityLabel = theme.accessibilityLabels.label(for: option, isFullscreen: isFullscreen)
        updateTint()
    }

    func updateTint() {
        let pressed = theme.colors.iconPressed
        tintColor = isHighlighted ? (pressed ?? normalColor) : normalColor
        pressedCircle?.isHidden = !isHighlighted
    }

    func configurePressedCircle(color: UIColor) {
        let circle = UIView()
        let diameter = theme.metrics.optionPressedDiameter
        circle.backgroundColor = color
        circle.layer.cornerRadius = diameter / 2
        circle.isUserInteractionEnabled = false
        circle.isHidden = true
        insertSubview(circle, at: 0)
        circle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: centerYAnchor),
            circle.widthAnchor.constraint(equalToConstant: diameter),
            circle.heightAnchor.constraint(equalToConstant: diameter)
        ])
        pressedCircle = circle
    }

}

// MARK: - Theme icons

extension KinescopePlayerOption {

    func themeIcon(isFullscreen: Bool) -> KinescopePlayerIcon? {
        switch self {
        case .more:
            return .more
        case .fullscreen:
            return isFullscreen ? .exitFullscreen : .fullscreen
        case .settings:
            return .settings
        case .attachments:
            return .attachments
        case .download:
            return .download
        case .airPlay:
            return .airPlay
        case .subtitles:
            return .subtitles
        case .pip:
            return .pip
        case .custom:
            return nil
        }
    }

    var selectedThemeIcon: KinescopePlayerIcon? {
        switch self {
        case .subtitles:
            return .subtitlesOn
        case .airPlay:
            return .airPlayActive
        default:
            return nil
        }
    }

}
