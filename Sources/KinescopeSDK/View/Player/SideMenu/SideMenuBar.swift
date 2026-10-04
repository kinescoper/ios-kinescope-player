//
//  SideMenuBar.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 02.04.2021.
//
// swiftlint:disable implicitly_unwrapped_optional

import UIKit

protocol SideMenuBarDelegate: AnyObject {
    func closeTapped()
    func backTapped()
    func downloadAllTapped(for title: String)
}

final class SideMenuBar: UIView {

    struct Model {
        let title: String
        let isRoot: Bool
        let isDownloadable: Bool
    }

    // MARK: - Views

    private weak var backButton: UIButton!
    private weak var titleView: UILabel!
    private weak var closeButton: UIButton!
    private weak var downloadAllButton: UIButton!

    // MARK: - Properties

    private let config: KinescopeSideMenuBarConfiguration
    private let theme: KinescopePlayerTheme
    private let model: Model

    weak var delegate: SideMenuBarDelegate?

    // MARK: - Init

    init(config: KinescopeSideMenuBarConfiguration, theme: KinescopePlayerTheme = .default, model: Model) {
        self.config = config
        self.theme = theme
        self.model = model
        super.init(frame: .zero)
        setupInitialState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        .init(width: .greatestFiniteMagnitude, height: theme.menu.isCard ? theme.menu.rowHeight : config.preferedHeight)
    }

}

// MARK: - Actions

private extension SideMenuBar {

    @objc
    func onCloseTapped() {
        delegate?.closeTapped()
    }

    @objc
    func onBackTapped() {
        delegate?.backTapped()
    }

    @objc
    func onDownloadAllTapped() {
        delegate?.downloadAllTapped(for: model.title)
    }

}

// MARK: - Private

private extension SideMenuBar {

    func setupInitialState() {
        if theme.menu.isCard {
            setupCardState()
            return
        }

        configureTitle()
        configureCloseButton()

        titleView.translatesAutoresizingMaskIntoConstraints = false

        if model.isRoot {
            NSLayoutConstraint.activate([
                titleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                titleView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4),
                titleView.centerYAnchor.constraint(equalTo: centerYAnchor),
                closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])
        } else {
            configureBackButton()

            NSLayoutConstraint.activate([
                backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                titleView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
                titleView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
                titleView.centerYAnchor.constraint(equalTo: centerYAnchor),
                closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
                closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
            ])
        }

        if model.isDownloadable {
            configureDownloadButton()

            NSLayoutConstraint.activate([
                downloadAllButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
                downloadAllButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -4)
            ])
        }

    }

    /// Figma «Player» menus: a row with the back glyph 12 from the edge and the title 4 after it, no close button;
    /// the whole row goes back. A root level other than settings shows its title at the row padding.
    func setupCardState() {
        configureTitle()
        titleView.translatesAutoresizingMaskIntoConstraints = false
        let padding = theme.menu.contentInsets
        if model.isRoot {
            NSLayoutConstraint.activate([
                titleView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding.left),
                titleView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -padding.right),
                titleView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            return
        }
        configureBackButton()
        NSLayoutConstraint.activate([
            backButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: max(padding.left - 4, 0)),
            titleView.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            titleView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -padding.right),
            titleView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onBackTapped)))
    }

    func configureTitle() {
        let label = UILabel()
        label.font = config.titleFont
        label.textColor = config.titleColor
        label.text = model.title

        addSubview(label)

        self.titleView = label
    }

    func configureCloseButton() {
        let button = HitAreaButton()
        button.setImage(theme.icons.image(for: .menuClose), for: .normal)
        button.accessibilityLabel = theme.accessibilityLabels.menuClose
        button.tintColor = theme.colors.icon

        addSubview(button)
        button.squareSize(with: config.iconSize)

        button.addTarget(nil, action: #selector(onCloseTapped), for: .touchUpInside)

        self.closeButton = button
    }

    func configureBackButton() {
        let button = HitAreaButton()
        button.setImage(theme.icons.image(for: .menuBack), for: .normal)
        button.accessibilityLabel = theme.accessibilityLabels.menuBack
        button.tintColor = theme.colors.icon

        addSubview(button)
        button.squareSize(with: config.iconSize)

        button.addTarget(nil, action: #selector(onBackTapped), for: .touchUpInside)

        self.backButton = button
    }

    func configureDownloadButton() {
        let button = UIButton()
        button.setTitle(L10n.Player.downloadAll, for: .normal)
        button.titleLabel?.font = config.downloadAllFont
        button.setTitleColor(config.downloadAllColor, for: .normal)
        button.setTitleColor(config.downloadAllHighlightedColor, for: .highlighted)
        button.translatesAutoresizingMaskIntoConstraints = false

        addSubview(button)
        button.sizeToFit()
        button.addTarget(nil, action: #selector(onDownloadAllTapped), for: .touchUpInside)

        self.downloadAllButton = button
    }

}

/// A side menu icon button that takes taps at least 44 points wide and high.
private final class HitAreaButton: UIButton {

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        minimumHitArea.contains(point)
    }

}
