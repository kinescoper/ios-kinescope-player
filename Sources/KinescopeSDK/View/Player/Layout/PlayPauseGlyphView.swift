//
//  PlayPauseGlyphView.swift
//  KinescopeSDK
//

import UIKit

/// The play/pause glyph as one shape that morphs between play and pause.
///
/// ``Shape/bars``: two quadrilaterals with the points in the same order, like media3's animated play/pause, so the
/// triangle's halves become the bars. ``Shape/kinescope``: the Android SDK's paths (``KinescopeGlyphPaths``), with
/// the replay glyph after the end.
final class PlayPauseGlyphView: UIView {

    enum Shape {
        /// - parameter playSize: Box of the triangle, pointing right.
        /// - parameter pauseSize: Box of the two bars.
        case bars(playSize: CGSize, pauseSize: CGSize, cornerRadius: CGFloat)
        /// - parameter side: Square the 24-point viewport of the play and pause paths is drawn in.
        case kinescope(side: CGFloat)
    }

    private let shapeLayer = CAShapeLayer()
    private let shape: Shape
    private let duration: TimeInterval
    private let timingFunction: CAMediaTimingFunction
    private(set) var isPlaying = false
    /// The replay glyph after the end, ``Shape/kinescope`` only.
    private(set) var isReplay = false

    init(shape: Shape,
         duration: TimeInterval,
         timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)) {
        self.shape = shape
        self.duration = duration
        self.timingFunction = timingFunction
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        if case let .bars(_, _, cornerRadius) = shape {
            shapeLayer.lineJoin = .round
            shapeLayer.lineWidth = cornerRadius * 2
        }
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        switch shape {
        case let .bars(playSize, pauseSize, _):
            return CGSize(width: max(playSize.width, pauseSize.width), height: max(playSize.height, pauseSize.height))
        case let .kinescope(side):
            return CGSize(width: side, height: side)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        setPath(currentPath, animated: false)
        updateColor()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateColor()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColor()
    }

    /// Morphs to play or pause; leaving the replay glyph is not animated, like on Android.
    func set(playing: Bool, animated: Bool) {
        let leavingReplay = isReplay
        guard playing != isPlaying || leavingReplay else {
            return
        }
        isPlaying = playing
        isReplay = false
        setPath(currentPath, animated: animated && !leavingReplay)
    }

    /// Shows the replay glyph after the end (``Shape/kinescope``); the other shape keeps the play glyph.
    func setReplay() {
        guard case .kinescope = shape else {
            set(playing: false, animated: false)
            return
        }
        isPlaying = false
        isReplay = true
        shapeLayer.removeAnimation(forKey: "morph")
        setPath(currentPath, animated: false)
    }

    /// Points of the current shape, for tests: the left part, then the right one, four points each
    /// (``Shape/bars`` only).
    var currentPoints: [CGPoint] {
        points(playing: isPlaying)
    }

    /// The drawn path, for tests.
    var currentPath: CGPath {
        switch shape {
        case .bars:
            return barsPath(playing: isPlaying)
        case let .kinescope(side):
            if isReplay {
                // Android insets the replay glyph by 5 of 56 points and play/pause by 11: a 46-point square.
                let replaySide = side * 46 / 34
                return KinescopeGlyphPaths.replay(in: square(replaySide))
            }
            return KinescopeGlyphPaths.playPause(playing: isPlaying, in: square(side))
        }
    }

}

// MARK: - Private

private extension PlayPauseGlyphView {

    func setPath(_ target: CGPath, animated: Bool) {
        shapeLayer.fillRule = isReplay ? .evenOdd : .nonZero
        guard animated, duration > 0, window != nil else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            shapeLayer.path = target
            CATransaction.commit()
            return
        }
        let animation = CABasicAnimation(keyPath: "path")
        animation.fromValue = shapeLayer.presentation()?.path ?? shapeLayer.path
        animation.toValue = target
        animation.duration = duration
        animation.timingFunction = timingFunction
        shapeLayer.path = target
        shapeLayer.add(animation, forKey: "morph")
    }

    func updateColor() {
        let color = tintColor.resolvedColor(with: traitCollection).cgColor
        shapeLayer.fillColor = color
        if case .bars = shape {
            shapeLayer.strokeColor = color
        }
    }

    func square(_ side: CGFloat) -> CGRect {
        CGRect(x: (bounds.width - side) / 2, y: (bounds.height - side) / 2, width: side, height: side)
    }

    func barsPath(playing: Bool) -> CGPath {
        let points = points(playing: playing)
        let path = CGMutablePath()
        path.addLines(between: Array(points[0..<4]))
        path.closeSubpath()
        path.addLines(between: Array(points[4..<8]))
        path.closeSubpath()
        return path
    }

    /// Eight points centered in the bounds, inset by the stroke that rounds the corners.
    func points(playing: Bool) -> [CGPoint] {
        guard case let .bars(playSize, pauseSize, cornerRadius) = shape else {
            return []
        }
        let size = playing ? pauseSize : playSize
        let inset = cornerRadius
        let width = max(size.width - inset * 2, 0)
        let height = max(size.height - inset * 2, 0)
        let origin = CGPoint(x: (bounds.width - width) / 2, y: (bounds.height - height) / 2)
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x, y: origin.y + y)
        }
        if playing {
            // Media3 proportions: each bar a third of the box, a third between them.
            let bar = width / 3
            return [
                point(0, 0), point(bar, 0), point(bar, height), point(0, height),
                point(width - bar, 0), point(width, 0), point(width, height), point(width - bar, height)
            ]
        }
        let middle = width / 2
        return [
            point(0, 0), point(middle, height / 4), point(middle, height * 3 / 4), point(0, height),
            point(middle, height / 4), point(width, height / 2), point(width, height / 2), point(middle, height * 3 / 4)
        ]
    }

}
