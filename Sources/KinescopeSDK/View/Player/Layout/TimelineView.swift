//
//  TimelineView.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 31.03.2021.
//
// swiftlint:disable implicitly_unwrapped_optional

import UIKit

protocol TimelineInput {

    /// Update timeline position manualy
    ///
    /// - parameter position: Value from `0` (start) to `1` (end)
    func setTimeline(to position: CGFloat)

    /// Update timeline position manualy
    ///
    /// - parameter progress: Value from `0` (start) to `1` (end)
    func setBufferred(progress: CGFloat)
}

protocol TimelineOutput: AnyObject {

    /// Callback of user initiated timeline changes like circle dragging
    ///
    /// - parameter position: Value from `0` (start) to `1` (end)
    func onTimelinePositionChanged(to position: CGFloat)

    /// Triggers update
    func onUpdate()

}

class TimelineView: UIControl {

    private weak var circleView: UIView!
    private weak var activeCircleView: UIView!
    private weak var futureProgress: UIView!
    private weak var pastProgress: UIView!
    private weak var preloadProgress: UIView!

    private let config: KinescopePlayerTimelineConfiguration
    private let theme: KinescopePlayerTheme

    private var isTouching = false {
        didSet {
            activeCircleView.isHidden = !isTouching
            circleView.isHidden = !(isTouching || showsIdleThumb)
        }
    }

    private var showsIdleThumb: Bool {
        theme.metrics.timelineThumbVisibleWhenIdle
    }

    /// Track inset from each edge: room for the thumb when it is always shown.
    private var trackInset: CGFloat {
        showsIdleThumb ? config.circleRadius : .zero
    }

    /// Last positions, to lay the parts out again when the size changes.
    private var position: CGFloat = .zero
    private var bufferedProgress: CGFloat = .zero

    weak var output: TimelineOutput?

    init(config: KinescopePlayerTimelineConfiguration, theme: KinescopePlayerTheme = .default) {
        self.config = config
        self.theme = theme
        super.init(frame: .zero)
        setupInitialState(with: config)

        addTarget(self, action: #selector(endTouch),
                  for: [UIControl.Event.touchUpOutside, UIControl.Event.touchUpInside])
        addTarget(self, action: #selector(continueTouch),
                  for: [UIControl.Event.touchDragInside, UIControl.Event.touchDragOutside])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !isTouching {
            updateFrames(with: getCoordinateFrom(current: position))
        }
        updatePreloadFrames(with: getCoordinateFrom(preload: bufferedProgress))
    }

    /// A thin bar still takes taps at least 44 points tall.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extra = max(0, (UIView.minimumHitSide - bounds.height) / 2)
        return bounds.insetBy(dx: 0, dy: -extra).contains(point)
    }

}

// MARK: - Accessibility

extension TimelineView {

    /// One VoiceOver swipe moves playback by this share of the video.
    static let accessibilityStep: CGFloat = 0.05

    override var accessibilityValue: String? {
        get {
            NumberFormatter.localizedString(from: NSNumber(value: Double(position)), number: .percent)
        }
        set {
            super.accessibilityValue = newValue
        }
    }

    override func accessibilityIncrement() {
        seekByAccessibility(to: position + Self.accessibilityStep)
    }

    override func accessibilityDecrement() {
        seekByAccessibility(to: position - Self.accessibilityStep)
    }

    private func seekByAccessibility(to position: CGFloat) {
        let position = min(max(position, 0), 1)
        setTimeline(to: position)
        output?.onTimelinePositionChanged(to: position)
        output?.onUpdate()
    }

}

// MARK: - Touches

private extension TimelineView {

    @objc
    func continueTouch(control: TimelineView, withEvent event: UIEvent) {
        guard let touch = event.touches(for: control)?.first else {
            return
        }
        isTouching = true

        let point = touch.location(in: self)
        let relativePosition = getRelativePosition(from: point.x)
        output?.onTimelinePositionChanged(to: relativePosition)
        updateFrames(with: point.x)
    }

    @objc
    func endTouch(control: TimelineView, withEvent event: UIEvent) {
        guard let touch = event.touches(for: control)?.first else {
            return
        }

        isTouching = false

        let point = touch.location(in: self)
        let relativePosition = getRelativePosition(from: point.x)
        output?.onTimelinePositionChanged(to: relativePosition)
        output?.onUpdate()
        updateFrames(with: point.x)
    }

}

// MARK: - TimelineInput

extension TimelineView: TimelineInput {

    func setTimeline(to position: CGFloat) {
        guard !isTouching else {
            return
        }
        self.position = position

        let coordinate = getCoordinateFrom(current: position)
        updateFrames(with: coordinate)
    }

    func setBufferred(progress: CGFloat) {
        bufferedProgress = progress
        let coordinate = getCoordinateFrom(preload: progress)
        updatePreloadFrames(with: coordinate)
    }

}

// MARK: - Private

private extension TimelineView {

    func setupInitialState(with config: KinescopePlayerTimelineConfiguration) {

        backgroundColor = .clear
        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        accessibilityLabel = theme.accessibilityLabels.timeline

        let futureProgress = createLine(with: config.inactiveColor, and: config.lineHeight)
        addSubview(futureProgress)
        self.futureProgress = futureProgress

        let preloadProgress = createLine(with: bufferedColor, and: config.lineHeight)
        addSubview(preloadProgress)
        self.preloadProgress = preloadProgress

        let pastProgress = createLine(with: config.activeColor, and: config.lineHeight)
        addSubview(pastProgress)
        self.pastProgress = pastProgress

        let activeCircleView = createCircle(with: UIColor(red: 1, green: 1, blue: 1, alpha: 0.16), radius: config.circleRadius + 4)
        addSubview(activeCircleView)
        self.activeCircleView = activeCircleView
        self.activeCircleView.isHidden = true

        let circleView = createCircle(with: thumbColor, radius: config.circleRadius)
        circleView.isHidden = !showsIdleThumb
        addSubview(circleView)
        self.circleView = circleView
    }

    /// The theme's color when a theme is set, else the configuration's, as before themes.
    var bufferedColor: UIColor {
        theme.colors.timelineBuffered == KinescopePlayerTheme.Colors.default.timelineBuffered
            ? config.inactiveColor
            : theme.colors.timelineBuffered
    }

    var thumbColor: UIColor {
        theme.colors.timelineThumb == KinescopePlayerTheme.Colors.default.timelineThumb
            ? config.activeColor
            : theme.colors.timelineThumb
    }

    func createLine(with color: UIColor, and height: CGFloat) -> UIView {
        let view = UIView(frame: .init(origin: .zero, size: .init(width: .zero, height: height)))
        view.backgroundColor = color
        view.layer.cornerRadius = min(theme.metrics.timelineCornerRadius, height / 2)
        view.isUserInteractionEnabled = false
        return view
    }

    func createCircle(with color: UIColor, radius: CGFloat) -> UIView {
        let view = UIView(frame: .init(origin: .zero, size: .init(width: radius * 2, height: radius * 2)))
        view.backgroundColor = color
        view.layer.cornerRadius = radius
        view.isUserInteractionEnabled = false
        return view
    }

    func updateFrames(with circleX: CGFloat) {

        let normalizedX = getNormalisedCoordinate(from: circleX)

        let centerY = frame.height / 2

        circleView.center = .init(x: normalizedX, y: centerY)
        activeCircleView.center = .init(x: normalizedX, y: centerY)

        let progressOrigin = CGPoint(x: trackInset, y: centerY - config.lineHeight / 2)

        futureProgress.frame = .init(origin: progressOrigin,
                                     size: .init(width: max(frame.width - trackInset * 2, .zero),
                                                 height: config.lineHeight))

        pastProgress.frame = .init(origin: progressOrigin,
                                     size: .init(width: max(normalizedX - trackInset, .zero),
                                                 height: config.lineHeight))
    }

    func updatePreloadFrames(with position: CGFloat) {

        let normalizedX = getNormalisedCoordinate(from: position)

        let centerY = frame.height / 2

        let progressOrigin = CGPoint(x: trackInset, y: centerY - config.lineHeight / 2)

        preloadProgress.frame = .init(origin: progressOrigin,
                                      size: .init(width: max(normalizedX - trackInset, .zero),
                                                  height: config.lineHeight))
    }

    var trackWidth: CGFloat {
        max(frame.width - trackInset * 2, .zero)
    }

    /// Convert circle center coordinate to relative value from `0` to `1`
    func getRelativePosition(from coordinate: CGFloat) -> CGFloat {
        guard trackWidth > 0 else {
            return .zero
        }
        let normalisedCoordinate = getNormalisedCoordinate(from: coordinate) - trackInset
        return normalisedCoordinate / trackWidth
    }

    /// Convert relative value from `0` to `1` to circle center coordinate
    func getCoordinateFrom(current position: CGFloat) -> CGFloat {
        position * trackWidth + trackInset
    }

    /// Convert relative value from `0` to `1` to the end of the buffered part
    func getCoordinateFrom(preload position: CGFloat) -> CGFloat {
        position * trackWidth + trackInset
    }

    /// Keep circle center x on the track
    func getNormalisedCoordinate(from coordinate: CGFloat) -> CGFloat {
        if coordinate < trackInset {
            return trackInset
        } else if coordinate > frame.width - trackInset {
            return frame.width - trackInset
        } else {
            return coordinate
        }
    }

}
