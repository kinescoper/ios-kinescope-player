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
    private let playPressedCircle = UIView()
    private let playPauseImageView = UIImageView()
    /// The glyph when the theme morphs it (``KinescopePlayerTheme/PlayPauseAnimation/morphsGlyph``).
    private(set) var playPauseGlyphView: PlayPauseGlyphView?
    /// VoiceOver's play/pause button: the circle is drawn, not a view, and it answers wherever the overlay is
    /// shown, also while the chrome is hidden.
    private(set) lazy var playButtonElement = PlayButtonAccessibilityElement(overlay: self)
    private let fastForwardImageView = UIImageView()
    private let fastBackwardImageView = UIImageView()
    /// ``KinescopePlayerTheme/SeekFeedback/Style/sideArea`` in place of the growing glyphs.
    private(set) var seekForwardArea: SeekFeedbackView?
    private(set) var seekBackwardArea: SeekFeedbackView?
    private let nameView: VideoNameView
    private let contentView = UIView()
    private let config: KinescopePlayerOverlayConfiguration
    private let theme: KinescopePlayerTheme
    private weak var delegate: PlayerOverlayViewDelegate?
    private var isPlaying = false
    private var isRewind = false
    /// Only the play button, before playback starts (``KinescopePlayerTheme/StartScreen/posterAndPlayButton``).
    private(set) var isStartScreen = false
    private var circleSizeConstraints: [NSLayoutConstraint] = []
    private var glyphCenterConstraints: [NSLayoutConstraint] = []
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
            guard !isStartScreen else {
                return
            }
            UIView.animate(withDuration: 0.1) {
                self.contentView.alpha = self.isSelected ? 1.0 : .zero
            }
        }
    }

    /// The play button is on screen: the chrome is shown or the start screen is.
    private var isPlayButtonShown: Bool {
        isSelected || isStartScreen
    }

    // The play button's pressed state; taps themselves stay with the gesture recognizers.

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        setPlayButtonPressed(isPlayButtonShown && playButtonFrame.contains(touch.location(in: contentView)))
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

    /// The pressed state comes at once and goes over ``KinescopePlayerTheme/PlayPauseAnimation/duration``, so a
    /// quick tap is seen too.
    func setPlayButtonPressed(_ pressed: Bool) {
        let colors = theme.colors
        let style = playButtonStyle
        let isGlyphOnly = style.isGlyphOnly
        guard isGlyphOnly
            ? colors.iconPressed != nil
            : colors.playButtonBackgroundPressed != nil || colors.playButtonPressedOverlay != nil else {
            return
        }
        let wasPressed = isPlayButtonPressed
        isPlayButtonPressed = pressed
        let pressedBackground = colors.playButtonBackgroundPressed ?? style.background
        let changes = {
            if isGlyphOnly {
                // A glyph without a fill changes its colour.
                self.setPlayGlyphTint(pressed ? colors.iconPressed : nil)
            } else {
                self.playBackgroundCircle.backgroundColor = pressed ? pressedBackground : style.background
                self.playPressedCircle.alpha = pressed && colors.playButtonPressedOverlay != nil ? 1 : 0
            }
        }
        let duration = theme.playPauseAnimation.duration
        if wasPressed && !pressed && duration > 0 && window != nil {
            UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction],
                           animations: changes)
        } else {
            playPressedCircle.layer.removeAllAnimations()
            playBackgroundCircle.layer.removeAllAnimations()
            changes()
        }
    }

    /// The pressed state of a tap that has already ended, as VoiceOver's activation: in, then fading out.
    func flashPlayButtonPressed() {
        setPlayButtonPressed(true)
        setPlayButtonPressed(false)
    }

    override var accessibilityElements: [Any]? {
        get {
            [playButtonElement]
        }
        set {
            super.accessibilityElements = newValue
        }
    }

    /// Shows only the play button over a clear background, whatever `isSelected` is, or brings the usual chrome
    /// back (hidden until the next tap).
    func setStartScreen(_ shown: Bool) {
        guard isStartScreen != shown else {
            return
        }
        isStartScreen = shown
        contentView.backgroundColor = shown ? .clear : config.backgroundColor
        nameView.isHidden = shown
        contentView.alpha = isPlayButtonShown ? 1.0 : .zero
        applyPlayButtonStyle()
        playButtonElement.update(isPlaying: isPlaying)
    }

    /// The circle and the glyph in the overlay's space.
    var playButtonFrameInOverlay: CGRect {
        contentView.layoutIfNeeded()
        return convert(playButtonFrame, from: contentView)
    }

    /// The circle and the glyph: a tap anywhere on them toggles playback.
    private var playButtonFrame: CGRect {
        playBackgroundCircle.frame.union(playPauseImageView.frame)
    }
}

// MARK: - Play button style

extension PlayerOverlayView {

    /// The play button as drawn now: the start screen's, or ``KinescopePlayerTheme/chromePlayButton`` with the chrome.
    struct PlayButtonStyle {
        let diameter: CGFloat
        let background: UIColor
        let glyphScale: CGFloat
        let glyphOffset: UIOffset

        var isGlyphOnly: Bool {
            background.cgColor.alpha == 0
        }
    }

    var startPlayButtonStyle: PlayButtonStyle {
        PlayButtonStyle(diameter: config.playBackgroundRadius * 2,
                        background: config.playBackgroundColor,
                        glyphScale: theme.metrics.playButtonGlyphScale,
                        glyphOffset: theme.metrics.playButtonGlyphOffset)
    }

    var playButtonStyle: PlayButtonStyle {
        guard !isStartScreen, let chrome = theme.chromePlayButton else {
            return startPlayButtonStyle
        }
        return PlayButtonStyle(diameter: chrome.diameter,
                               background: chrome.background,
                               glyphScale: chrome.glyphScale,
                               glyphOffset: chrome.glyphOffset)
    }

}

// MARK: - PlayerOverlayInput

extension PlayerOverlayView: PlayerOverlayInput {
    func set(title: String, subtitle: String) {
        nameView.set(title: title, subtitle: subtitle)
    }

    func set(playing: Bool) {
        self.isPlaying = playing
        updatePlayPauseImage(animated: true)
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
        configureSeekAreas()
    }

    func configureSeekAreas() {
        let feedback = theme.seekFeedback
        guard case let .sideArea(fill, widthRatio, edgeDepth) = feedback.style else {
            return
        }
        let seconds = Int(KinescopeVideoPlayer.fastSeekInterval)
        let backward = SeekFeedbackView(side: .backward, feedback: feedback, fill: fill, edgeDepth: edgeDepth,
                                        seconds: seconds)
        let forward = SeekFeedbackView(side: .forward, feedback: feedback, fill: fill, edgeDepth: edgeDepth,
                                       seconds: seconds)
        addSubviews(backward, forward)
        NSLayoutConstraint.activate([
            backward.topAnchor.constraint(equalTo: topAnchor),
            backward.bottomAnchor.constraint(equalTo: bottomAnchor),
            backward.leadingAnchor.constraint(equalTo: leadingAnchor),
            backward.widthAnchor.constraint(equalTo: widthAnchor, multiplier: widthRatio),
            forward.topAnchor.constraint(equalTo: topAnchor),
            forward.bottomAnchor.constraint(equalTo: bottomAnchor),
            forward.trailingAnchor.constraint(equalTo: trailingAnchor),
            forward.widthAnchor.constraint(equalTo: widthAnchor, multiplier: widthRatio)
        ])
        seekBackwardArea = backward
        seekForwardArea = forward
    }

    func configurePlayPauseImageView() {
        playPressedCircle.backgroundColor = theme.colors.playButtonPressedOverlay
        playPressedCircle.alpha = 0
        playPauseImageView.contentMode = .center
        if let tint = theme.colors.playButtonIcon {
            playPauseImageView.tintColor = tint
        }

        contentView.addSubviews(playBackgroundCircle, playPressedCircle, playPauseImageView)
        if theme.playPauseAnimation.morphsGlyph {
            configurePlayPauseGlyphView()
        }
        contentView.centerChild(view: playBackgroundCircle)
        contentView.centerChild(view: playPressedCircle)
        circleSizeConstraints = [playBackgroundCircle, playPressedCircle].flatMap { circle in
            [circle.widthAnchor.constraint(equalToConstant: 0), circle.heightAnchor.constraint(equalToConstant: 0)]
        }
        playPauseImageView.translatesAutoresizingMaskIntoConstraints = false
        glyphCenterConstraints = [
            playPauseImageView.centerXAnchor.constraint(equalTo: playBackgroundCircle.centerXAnchor),
            playPauseImageView.centerYAnchor.constraint(equalTo: playBackgroundCircle.centerYAnchor)
        ]
        NSLayoutConstraint.activate(circleSizeConstraints + glyphCenterConstraints)
        applyPlayButtonStyle()
    }

    /// Sizes, fills and scales the button for the start screen or the chrome.
    func applyPlayButtonStyle() {
        let style = playButtonStyle
        circleSizeConstraints.forEach { $0.constant = style.diameter }
        glyphCenterConstraints.first?.constant = style.glyphOffset.horizontal
        glyphCenterConstraints.last?.constant = style.glyphOffset.vertical
        for circle in [playBackgroundCircle, playPressedCircle] {
            circle.layer.cornerRadius = style.diameter / 2
        }
        playBackgroundCircle.backgroundColor = style.background
        playPressedCircle.alpha = 0
        isPlayButtonPressed = false
        setPlayGlyphTint(nil)
        // The morphing glyph is built at the start screen's scale.
        let start = startPlayButtonStyle
        let ratio = theme.icons.custom(.play) != nil && start.glyphScale > 0 ? style.glyphScale / start.glyphScale : 1
        playPauseGlyphView?.transform = CGAffineTransform(scaleX: ratio, y: ratio)
        updatePlayPauseImage(animated: false)
    }

    /// `nil`: the glyph's own tint.
    func setPlayGlyphTint(_ color: UIColor?) {
        let tint = color ?? theme.colors.playButtonIcon ?? theme.colors.icon
        playPauseImageView.tintColor = tint
        playPauseGlyphView?.tintColor = tint
    }

    /// Draws the glyph in place of the images, as big as they are.
    func configurePlayPauseGlyphView() {
        let scale = theme.metrics.playButtonGlyphScale
        let playSize = themedGlyph(config.playImage, icon: .play, scale: scale).size
        let pauseSize = themedGlyph(config.pauseImage, icon: .pause, scale: scale).size
        let animation = theme.playPauseAnimation
        let glyphView = PlayPauseGlyphView(playSize: playSize,
                                           pauseSize: pauseSize,
                                           duration: animation.duration,
                                           cornerRadius: animation.glyphCornerRadius)
        if let tint = theme.colors.playButtonIcon {
            glyphView.tintColor = tint
        }
        contentView.addSubview(glyphView)
        glyphView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            glyphView.centerXAnchor.constraint(equalTo: playPauseImageView.centerXAnchor),
            glyphView.centerYAnchor.constraint(equalTo: playPauseImageView.centerYAnchor)
        ])
        playPauseImageView.isHidden = true
        playPauseGlyphView = glyphView
    }

    func updatePlayPauseImage(animated: Bool) {
        playButtonElement.update(isPlaying: isPlaying)
        if let playPauseGlyphView {
            playPauseGlyphView.set(playing: isPlaying, animated: animated)
        }
        let scale = playButtonStyle.glyphScale
        playPauseImageView.image = isPlaying
            ? themedGlyph(config.pauseImage, icon: .pause, scale: scale)
            : themedGlyph(config.playImage, icon: .play, scale: scale)
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

        updatePlayPauseImage(animated: true)
        if isPlaying {
            delegate?.didPlay()
        } else {
            delegate?.didPause()
        }
    }

    @objc
    func singleTapAction(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: contentView)

        if isPlayButtonShown && playButtonFrame.contains(location) {
            playPauseAction()
        } else if isStartScreen {
            return
        } else {
            isRewind = false
            delegate?.didTap(isSelected: isSelected)
        }
    }

    @objc
    func doubleTapAction(recognizer: UITapGestureRecognizer) {
        guard !isStartScreen else {
            return
        }
        isRewind = true

        let location = recognizer.location(in: self)
        if fastForwardFrame.contains(location) {
            fastForward()
        } else if fastBackwardFrame.contains(location) {
            fastBackward()
        }
    }

    var fastForwardFrame: CGRect {
        CGRect(x: contentView.center.x + 24.0,
               y: .zero,
               width: contentView.bounds.width - contentView.center.x + 24.0,
               height: contentView.bounds.height)
    }

    var fastBackwardFrame: CGRect {
        CGRect(x: .zero,
               y: .zero,
               width: contentView.bounds.width - contentView.center.x - 24.0,
               height: contentView.bounds.height)
    }

    func fastForward() {
        delegate?.didFastForward()
        if let seekForwardArea {
            seekForwardArea.flash(duration: theme.seekFeedback.duration)
            return
        }

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
    }

    func fastBackward() {
        delegate?.didFastBackward()
        if let seekBackwardArea {
            seekBackwardArea.flash(duration: theme.seekFeedback.duration)
            return
        }

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

// MARK: - Accessibility

/// The play/pause button for VoiceOver: its label follows the state, activating it plays or pauses like a tap, and
/// the double-tap seeks are its custom actions.
final class PlayButtonAccessibilityElement: UIAccessibilityElement {

    private weak var overlay: PlayerOverlayView?
    private let labels: KinescopePlayerTheme.AccessibilityLabels

    init(overlay: PlayerOverlayView) {
        self.overlay = overlay
        self.labels = overlay.accessibilityLabels
        super.init(accessibilityContainer: overlay)
        accessibilityTraits = .button
        accessibilityLabel = labels.play
    }

    func update(isPlaying: Bool) {
        accessibilityLabel = isPlaying ? labels.pause : labels.play
        accessibilityCustomActions = overlay?.isStartScreen == true ? nil : [
            UIAccessibilityCustomAction(name: labels.fastForward) { [weak self] _ in
                self?.overlay?.accessibilityFastForward() != nil
            },
            UIAccessibilityCustomAction(name: labels.fastBackward) { [weak self] _ in
                self?.overlay?.accessibilityFastBackward() != nil
            }
        ]
    }

    override var accessibilityFrameInContainerSpace: CGRect {
        get {
            overlay?.playButtonFrameInOverlay ?? .zero
        }
        set {
            super.accessibilityFrameInContainerSpace = newValue
        }
    }

    override func accessibilityActivate() -> Bool {
        overlay?.accessibilityPlayPause() != nil
    }

}

extension PlayerOverlayView {

    var accessibilityLabels: KinescopePlayerTheme.AccessibilityLabels {
        theme.accessibilityLabels
    }

    func accessibilityPlayPause() {
        flashPlayButtonPressed()
        playPauseAction()
    }

    func accessibilityFastForward() {
        fastForward()
    }

    func accessibilityFastBackward() {
        fastBackward()
    }

}
