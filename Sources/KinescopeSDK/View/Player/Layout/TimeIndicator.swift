//
//  TimeIndicator.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 31.03.2021.
//

import UIKit

protocol TimeIndicatorInput {

    /// Update time value
    ///
    /// - parameter time: Positive time interval describes current moment in video
    func setIndicator(to time: TimeInterval)
}

class TimeIndicatorView: UIView {

    private let label = UILabel()

    private let config: KinescopePlayerTimeindicatorConfiguration
    private let theme: KinescopePlayerTheme
    private let formatter = DateFormatter()

    init(config: KinescopePlayerTimeindicatorConfiguration, theme: KinescopePlayerTheme = .default) {
        self.config = config
        self.theme = theme
        super.init(frame: .zero)
        setupInitialState(with: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let label = UILabel()
        label.font = monospacedFont()
        // Digits are monospaced, so the widest text of a format is any text of it.
        label.text = theme.metrics.timeReservesHours ? getText(from: 3600 * 24) : (self.label.text ?? getText(from: 0))
        label.sizeToFit()
        return .init(width: ceil(label.frame.size.width), height: label.font.lineHeight)
    }

}

// MARK: - TimeIndicatorInput

extension TimeIndicatorView: TimeIndicatorInput {

    func setIndicator(to time: TimeInterval) {
        let text = getText(from: time)
        let resizes = !theme.metrics.timeReservesHours && text.count != label.text?.count
        label.text = text
        if resizes {
            invalidateIntrinsicContentSize()
        }
    }

}

// MARK: - Private

private extension TimeIndicatorView {

    func setupInitialState(with config: KinescopePlayerTimeindicatorConfiguration) {
        backgroundColor = .clear
        configureLabel()
    }

    func configureLabel() {
        label.textColor = config.color
        label.font = monospacedFont()
        label.textAlignment = .right

        addSubview(label)
        stretch(view: label)

        label.text = getText(from: 0)
    }

    func getText(from time: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: time)
        let duration = KinescopeVideoDuration.from(raw: time)
        formatter.dateFormat = duration.rawValue
        return formatter.string(from: date)
    }

    func monospacedFont() -> UIFont {
        let fontFeatures = [
            [
                UIFontDescriptor.FeatureKey.featureIdentifier: kNumberSpacingType,
                UIFontDescriptor.FeatureKey.typeIdentifier: kMonospacedNumbersSelector
            ]
        ]
        let descriptorWithFeatures = theme.fonts.time.withSize(config.fontSize)
            .fontDescriptor
            .addingAttributes([UIFontDescriptor.AttributeName.featureSettings: fontFeatures])
        return UIFont(descriptor: descriptorWithFeatures, size: config.fontSize)
    }

}
