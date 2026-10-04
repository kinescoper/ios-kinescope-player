//
//  PlayerControlOptionsView.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 31.03.2021.
//

import UIKit

protocol PlayerControlOptionsInput {

    func getCustomOptionView(by id: AnyHashable) -> UIView?

    /// Set available options
    ///
    /// - parameter options: Set of option
    func set(options: [KinescopePlayerOption])
    func set(subtitleOn: Bool)
}

protocol PlayerControlOptionsOutput: AnyObject {

    /// Callback of user initiated expand action. Called on three dots tapped.
    ///
    /// - parameter expanded: Value of `true` when all options expanded. `false` when visible only `2` options.
    func didOptions(expanded: Bool)

    /// Callback of user initiated selection of option. Called on button tapped.
    ///
    /// - parameter option: Option assosiated with button which were tapped
    func didSelect(option: KinescopePlayerOption)

}

class PlayerControlOptionsView: UIControl {

    private let stackView = UIStackView()

    private let config: KinescopePlayerOptionsConfiguration
    private let theme: KinescopePlayerTheme
    private let isFullscreen: Bool
    private(set) var options: [KinescopePlayerOption] = []
    private var isSubtitleOn = false
    
    private var customOptionsTagMap: [AnyHashable: Int] = [:]

    weak var output: PlayerControlOptionsOutput?

    init(config: KinescopePlayerOptionsConfiguration, theme: KinescopePlayerTheme = .default, isFullscreen: Bool = false) {
        self.config = config
        self.theme = theme
        self.isFullscreen = isFullscreen
        super.init(frame: .zero)
        setupInitialState(with: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let count = CGFloat(stackView.arrangedSubviews.count)
        guard count > 0 else {
            return .init(width: .zero, height: config.iconSize)
        }
        return .init(width: config.iconSize * count + stackView.spacing * (count - 1), height: config.iconSize)
    }

    var isExpanded: Bool = false {
        didSet {
            fillStack(with: options, expanded: isExpanded)
        }
    }

    // Options are smaller than a 44-point target: a touch near one goes to the nearest option whose grown area
    // takes it, also past this view's frame.

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        minimumHitArea.insetBy(dx: -UIView.minimumHitSide / 2, dy: 0).contains(point)
            && optionHit(at: point, with: event) != nil
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01, let option = optionHit(at: point, with: event) else {
            return super.hitTest(point, with: event)
        }
        return option.hitTest(convert(point, to: option), with: event) ?? option
    }

}

// MARK: - Input

extension PlayerControlOptionsView: PlayerControlOptionsInput {

    func getCustomOptionView(by id: AnyHashable) -> UIView? {
        let buttonTag = customOptionsTagMap[id]
        return stackView.arrangedSubviews
            .first(where: { $0.tag == buttonTag })
    }

    func set(options: [KinescopePlayerOption]) {
        self.options = options
        self.isExpanded = false

        fillStack(with: options, expanded: isExpanded)
    }

    func set(subtitleOn: Bool) {
        self.isSubtitleOn = subtitleOn

        let button = stackView.arrangedSubviews
            .compactMap { $0 as? OptionButton }
            .first { $0.option == .subtitles }

        button?.isSelected = subtitleOn
    }

}

// MARK: - Private

private extension PlayerControlOptionsView {

    func setupInitialState(with config: KinescopePlayerOptionsConfiguration) {

        configureStack()
    }

    func configureStack() {
        stackView.axis = .horizontal
        stackView.spacing = theme.metrics.optionSpacing
        stackView.alignment = .trailing
        stackView.distribution = .fill
        stackView.backgroundColor = .clear

        addSubview(stackView)
        stretch(view: stackView)
    }

    func createButton(from option: KinescopePlayerOption, at index: Int) -> UIView {
        switch option {
        case .airPlay:
            let button = AirPlayOptionControl(theme: theme, tintColor: config.normalColor)
            button.tintColor = config.normalColor
            button.squareSize(with: config.iconSize)
            button.tag = index
            return button
        default:
            let button = OptionButton(option: option,
                                      theme: theme,
                                      normalColor: config.normalColor,
                                      isFullscreen: isFullscreen)

            if let optionId = option.optionId {
                customOptionsTagMap[optionId] = index
            }
            
            button.tag = index
            button.squareSize(with: config.iconSize)

            button.addTarget(nil, action: #selector(buttonTapped(sender:)), for: .touchUpInside)

            return button
        }
    }

    func fillStack(with options: [KinescopePlayerOption], expanded: Bool) {
        guard !options.isEmpty else {
            return
        }

        clearStack()

        let collapsedCount = max(theme.metrics.collapsedOptionsCount, 1)
        let filteredOptions = expanded
            ? options
            : Array(options.suffix(collapsedCount))

        filteredOptions
            .enumerated()
            .map { index, option in
                createButton(from: option, at: index)
            }
            .forEach { [weak self] button in
                self?.stackView.addArrangedSubview(button)
            }

        set(subtitleOn: isSubtitleOn)
        invalidateIntrinsicContentSize()
    }

    func clearStack() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
            stackView.removeArrangedSubview($0)
        }
    }

    func optionHit(at point: CGPoint, with event: UIEvent?) -> UIView? {
        stackView.arrangedSubviews
            .filter { !$0.isHidden && $0.isUserInteractionEnabled && $0.point(inside: convert(point, to: $0), with: event) }
            .min { distance(from: point, to: $0) < distance(from: point, to: $1) }
    }

    func distance(from point: CGPoint, to view: UIView) -> CGFloat {
        let center = convert(view.center, from: view.superview)
        return hypot(point.x - center.x, point.y - center.y)
    }

    @objc
    func buttonTapped(sender: OptionButton) {
        let option = sender.option

        Kinescope.shared.logger?.log(message: "Options menu button tapped: \(option)",
                                     level: KinescopeLoggerLevel.player)

        output?.didSelect(option: option)
    }

}
