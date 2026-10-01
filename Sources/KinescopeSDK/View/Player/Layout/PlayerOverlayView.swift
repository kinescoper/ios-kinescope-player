//
//  PlayerOverlayView.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 30.03.2021.
//

import UIKit

protocol PlayerOverlayInput: VideoNameInput {
    func set(playing: Bool)
}

final class PlayerOverlayView: UIControl {

    // MARK: - Properties

    private let playBackgroundCircle = UIView()
    private let playPauseImageView = UIImageView()
    private let fastForwardImageView = UIImageView()
    private let fastBackwardImageView = UIImageView()
    private let nameView: VideoNameView
    private let contentView = UIView()
    private let config: KinescopePlayerOverlayConfiguration
    private let theme: KinescopePlayerTheme
    private weak var delegate: PlayerOverlayViewDelegate?
    private var isPlaying = false
    private var isRewind = false
    var duration: TimeInterval {
        return config.duration
    }

    // MARK: - Lifecycle

    init(config: KinescopePlayerOverlayConfiguration,
         theme: KinescopePlayerTheme = .default,
         delegate: PlayerOverlayViewDelegate? = nil) {
        self.config = config
        self.theme = theme
        self.delegate = delegate
        self.nameView = VideoNameView(config: config.nameConfiguration)
        super.init(frame: .zero)
        self.setupInitialState()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UIControl

    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.contentView.alpha = self.isSelected ? 1.0 : .zero
            }
        }
    }

    // The play button's pressed state; taps themselves stay with the gesture recognizers.

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        setPlayButtonPressed(isSelected && playButtonFrame.contains(touch.location(in: contentView)))
        return super.beginTracking(touch, with: event)
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if isPlayButtonPressed && !playButtonFrame.contains(touch.location(in: contentView)) {
            setPlayButtonPressed(false)
        }
        return super.continueTracking(touch, with: event)
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        setPlayButtonPressed(false)
        super.endTracking(touch, with: event)
    }

    override func cancelTracking(with event: UIEvent?) {
        setPlayButtonPressed(false)
        super.cancelTracking(with: event)
    }

    private(set) var isPlayButtonPressed = false

    func setPlayButtonPressed(_ pressed: Bool) {
        guard let pressedColor = theme.colors.playButtonBackgroundPressed else {
            return
        }
        isPlayButtonPressed = pressed
        playBackgroundCircle.backgroundColor = pressed ? pressedColor : config.playBackgroundColor
    }

    /// The circle and the glyph: a tap anywhere on them toggles playback.
    private var playButtonFrame: CGRect {
        playBackgroundCircle.frame.union(playPauseImageView.frame)
    }
}

// MARK: - PlayerOverlayInput

extension PlayerOverlayView: PlayerOverlayInput {
    func set(title: String, subtitle: String) {
        nameView.set(title: title, subtitle: subtitle)
    }

    func set(playing: Bool) {
        self.isPlaying = playing
        updatePlayPauseImage()
    }
}

// MARK: - Private

private extension PlayerOverlayView {
    func setupInitialState() {
        isSelected = false
        // Template glyphs from a theme; the bundled images are not templates and ignore it.
        tintColor = theme.colors.icon

        addGestureRecognizers()
        configureContentView()
    }

    func configureContentView() {
        contentView.isUserInteractionEnabled = false
        contentView.backgroundColor = config.backgroundColor
        addSubview(contentView)
        stretch(view: contentView)

        configureNameView()
        configurePlayPauseImageView()
        configureFastForwardImageView()
        configureFastBackwardImageView()
    }

    func configurePlayPauseImageView() {
        playBackgroundCircle.layer.cornerRadius = config.playBackgroundRadius
        playBackgroundCircle.backgroundColor = config.playBackgroundColor
        playPauseImageView.contentMode = .center
        if let tint = theme.colors.playButtonIcon {
            playPauseImageView.tintColor = tint
        }
        updatePlayPauseImage()

        contentView.addSubviews(playBackgroundCircle, playPauseImageView)
        playBackgroundCircle.squareSize(with: config.playBackgroundRadius * 2)
        contentView.centerChild(view: playBackgroundCircle)
        let offset = theme.metrics.playButtonGlyphOffset
        playPauseImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playPauseImageView.centerXAnchor.constraint(equalTo: playBackgroundCircle.centerXAnchor,
                                                        constant: offset.horizontal),
            playPauseImageView.centerYAnchor.constraint(equalTo: playBackgroundCircle.centerYAnchor,
                                                        constant: offset.vertical)
        ])
    }

    func updatePlayPauseImage() {
        playPauseImageView.image = isPlaying
            ? themedGlyph(config.pauseImage, icon: .pause, scale: theme.metrics.playButtonGlyphScale)
            : themedGlyph(config.playImage, icon: .play, scale: theme.metrics.playButtonGlyphScale)
    }

    /// When the theme supplies the glyph, it is drawn at the theme's scale; otherwise the image stays as is.
    func themedGlyph(_ image: UIImage, icon: KinescopePlayerIcon, scale: CGFloat? = nil) -> UIImage {
        guard theme.icons.custom(icon) != nil else {
            return image
        }
        return image.scaled(by: scale ?? theme.metrics.iconGlyphScale)
    }

    func configureFastForwardImageView() {
        fastForwardImageView.image = themedGlyph(config.fastForwardImage, icon: .fastForward)
        fastForwardImageView.alpha = .zero
        addSubview(fastForwardImageView)
        rightCenterChild(view: fastForwardImageView)
    }

    func configureFastBackwardImageView() {
        fastBackwardImageView.image = themedGlyph(config.fastBackwardImage, icon: .fastBackward)
        fastBackwardImageView.alpha = .zero
        addSubview(fastBackwardImageView)
        leftCenterChild(view: fastBackwardImageView)
    }

    func configureNameView() {
        contentView.addSubview(nameView)
        contentView.topChildWithSafeArea(view: nameView)
    }

    func addGestureRecognizers() {
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                             action: #selector(singleTapAction))
        singleTapGestureRecognizer.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGestureRecognizer)

        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self,
                                                             action: #selector(doubleTapAction))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGestureRecognizer)

        singleTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
    }

}

// MARK: - Actions

private extension PlayerOverlayView {
    @objc
    func playPauseAction() {
        isPlaying.toggle()

        updatePlayPauseImage()
        if isPlaying {
            delegate?.didPlay()
        } else {
            delegate?.didPause()
        }
    }

    @objc
    func singleTapAction(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: contentView)

        if isSelected && playButtonFrame.contains(location) {
            playPauseAction()
        } else {
            isRewind = false
            delegate?.didTap(isSelected: isSelected)
        }
    }

    @objc
    func doubleTapAction(recognizer: UITapGestureRecognizer) {
        isRewind = true

        let location = recognizer.location(in: self)
        let rightFrame = CGRect(x: contentView.center.x + 24.0,
                                y: .zero,
                                width: contentView.bounds.width - contentView.center.x + 24.0,
                                height: contentView.bounds.height)

        let leftFrame = CGRect(x: .zero,
                               y: .zero,
                               width: contentView.bounds.width - contentView.center.x - 24.0,
                               height: contentView.bounds.height)

        if rightFrame.contains(location) {
            delegate?.didFastForward()

            fastForwardImageView.alpha = 1.0
            UIView.animate(
                withDuration: 0.6,
                animations: {
                    self.fastForwardImageView.transform = .init(scaleX: 2.0, y: 2.0)
                    self.fastForwardImageView.alpha = .zero
                },
                completion: { _ in
                    self.fastForwardImageView.alpha = .zero
                    self.fastForwardImageView.transform = .identity
                }
            )
        } else if leftFrame.contains(location) {
            delegate?.didFastBackward()

            fastBackwardImageView.alpha = 1.0
            UIView.animate(
                withDuration: 0.6,
                animations: {
                    self.fastBackwardImageView.transform = .init(scaleX: 2.0, y: 2.0)
                    self.fastBackwardImageView.alpha = .zero
                },
                completion: { _ in
                    self.fastBackwardImageView.alpha = .zero
                    self.fastBackwardImageView.transform = .identity
                }
            )
        }
    }
}
