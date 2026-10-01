//
//  DisclosureCell.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 05.04.2021.
//
// swiftlint:disable implicitly_unwrapped_optional

import UIKit

final class DisclosureCell: UITableViewCell {

    struct Model {
        let title: String
        let value: NSAttributedString?
        let config: KinescopeSideMenuItemConfiguration
    }

    // MARK: - Views

    private weak var titleLabel: UILabel!
    private weak var valueLabel: UILabel!
    private weak var iconView: UIImageView!
    private let leadingIconView = UIImageView()
    private var model: Model?
    private var titleLeading: NSLayoutConstraint?
    private var valueTrailing: NSLayoutConstraint?
    private var iconTrailing: NSLayoutConstraint?

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupInitialState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UITableViewCell

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        guard
            let highlightedColor = model?.config.highlightedColor
        else {
            return
        }

        let color = highlighted ? highlightedColor : .clear

        UIView.animate(withDuration: 0.3) {
            self.backgroundColor = color
        }
    }

    // MARK: - Methods

    /// The theme's glyph; `nil` keeps the bundled one.
    func set(icon: UIImage?, tintColor: UIColor) {
        guard let icon else {
            return
        }
        iconView?.image = icon
        iconView?.tintColor = tintColor
    }

    /// The card menu's row: a glyph before the title and the row padding (Figma «Player» `Settings/Normal` item:
    /// glyph, 4, title; value, 4, chevron). `nil` insets keep the side sheet's row.
    func set(leadingIcon: UIImage?, tintColor: UIColor, insets: UIEdgeInsets?) {
        leadingIconView.image = leadingIcon
        leadingIconView.tintColor = tintColor
        leadingIconView.isHidden = leadingIcon == nil
        let iconWidth = leadingIcon.map { $0.size.width + 4 } ?? 0
        titleLeading?.constant = (insets?.left ?? 16) + iconWidth
        valueTrailing?.constant = insets == nil ? -16 : -4
        iconTrailing?.constant = -(insets?.right ?? 8)
    }

    func configure(with model: Model) {
        self.model = model
        setupAppearance(with: model.config)

        titleLabel.text = model.title
        valueLabel.attributedText = model.value
    }

}

// MARK: - Private

private extension DisclosureCell {

    func setupInitialState() {
        selectionStyle = .none
        backgroundColor = .clear

        setupLayout()

    }

    func setupLayout() {

        let titleLabel = UILabel()
        let valueLabel = UILabel()
        let iconView = UIImageView(image: .image(named: "forward"))

        leadingIconView.contentMode = .center
        leadingIconView.isHidden = true
        addSubviews(titleLabel, valueLabel, iconView, leadingIconView)

        let titleLeading = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        let valueTrailing = valueLabel.trailingAnchor.constraint(equalTo: iconView.leadingAnchor, constant: -16)
        let iconTrailing = iconView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLeading,
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            valueTrailing,
            iconTrailing,
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leadingIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            leadingIconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -4)
        ])
        self.titleLeading = titleLeading
        self.valueTrailing = valueTrailing
        self.iconTrailing = iconTrailing

        self.titleLabel = titleLabel
        self.valueLabel = valueLabel
        self.iconView = iconView

    }

    func setupAppearance(with config: KinescopeSideMenuItemConfiguration) {
        titleLabel.font = config.titleFont
        titleLabel.textColor = config.titleColor

        valueLabel.font = config.valueFont
        valueLabel.textColor = config.valueColor
    }

}
