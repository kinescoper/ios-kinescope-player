//
//  PlayPauseGlyphView.swift
//  KinescopeSDK
//

import UIKit

/// The play/pause glyph as one shape that morphs between the play triangle and the pause bars, like media3's
/// animated play/pause on Android. Both are two quadrilaterals with the points in the same order, so the path
/// animation moves each point straight to its place: the triangle's halves become the bars.
final class PlayPauseGlyphView: UIView {

    private let shapeLayer = CAShapeLayer()
    private let playSize: CGSize
    private let pauseSize: CGSize
    private let duration: TimeInterval
    private let cornerRadius: CGFloat
    private(set) var isPlaying = false

    /// - parameter playSize: Box of the triangle, pointing right.
    /// - parameter pauseSize: Box of the two bars.
    init(playSize: CGSize, pauseSize: CGSize, duration: TimeInterval, cornerRadius: CGFloat) {
        self.playSize = playSize
        self.pauseSize = pauseSize
        self.duration = duration
        self.cornerRadius = cornerRadius
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        shapeLayer.lineJoin = .round
        shapeLayer.lineWidth = cornerRadius * 2
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: max(playSize.width, pauseSize.width), height: max(playSize.height, pauseSize.height))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shapeLayer.path = path(playing: isPlaying)
        CATransaction.commit()
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

    func set(playing: Bool, animated: Bool) {
        guard playing != isPlaying else {
            return
        }
        isPlaying = playing
        let target = path(playing: playing)
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
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        shapeLayer.path = target
        shapeLayer.add(animation, forKey: "morph")
    }

    /// Points of the current shape, for tests: the left part, then the right one, four points each.
    var currentPoints: [CGPoint] {
        points(playing: isPlaying)
    }

}

// MARK: - Private

private extension PlayPauseGlyphView {

    func updateColor() {
        let color = tintColor.resolvedColor(with: traitCollection).cgColor
        shapeLayer.fillColor = color
        shapeLayer.strokeColor = color
    }

    func path(playing: Bool) -> CGPath {
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
