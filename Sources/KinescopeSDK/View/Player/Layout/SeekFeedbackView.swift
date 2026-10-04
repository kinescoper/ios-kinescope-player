//
//  SeekFeedbackView.swift
//  KinescopeSDK
//

import UIKit

/// One side of ``KinescopePlayerTheme/SeekFeedback/Style/sideArea``: the lit area with three arrows and the seek
/// length, drawn for the right side and mirrored for the left.
final class SeekFeedbackView: UIView {

    enum Side {
        case backward
        case forward
    }

    private let side: Side
    private let fill: UIColor
    private let edgeDepth: CGFloat
    private let areaLayer = CAShapeLayer()
    private let arrowsLayer = CAShapeLayer()
    private let label = UILabel()

    private enum Constants {
        /// Figma `Arrow`: three triangles in 31×12, 4 above the text.
        static let arrowsSize = CGSize(width: 31, height: 12)
        static let gap: CGFloat = 4
    }

    init(side: Side, feedback: KinescopePlayerTheme.SeekFeedback, fill: UIColor, edgeDepth: CGFloat, seconds: Int) {
        self.side = side
        self.fill = fill
        self.edgeDepth = edgeDepth
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        alpha = 0

        layer.addSublayer(areaLayer)
        layer.addSublayer(arrowsLayer)
        label.font = feedback.font
        label.textColor = feedback.textColor
        label.text = feedback.text(seconds)
        label.textAlignment = .center
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        areaLayer.frame = bounds
        areaLayer.fillColor = fill.resolvedColor(with: traitCollection).cgColor
        areaLayer.path = areaPath(in: bounds).cgPath
        arrowsLayer.fillColor = label.textColor.resolvedColor(with: traitCollection).cgColor

        label.sizeToFit()
        let contentHeight = Constants.arrowsSize.height + Constants.gap + label.bounds.height
        // The content is centered in the area less its bulge, like the Figma frame centered in the shape.
        let inner = side == .forward
            ? bounds.inset(by: UIEdgeInsets(top: 0, left: edgeDepth, bottom: 0, right: 0))
            : bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: edgeDepth))
        let top = bounds.midY - contentHeight / 2
        let arrowsFrame = CGRect(x: inner.midX - Constants.arrowsSize.width / 2,
                                 y: top,
                                 width: Constants.arrowsSize.width,
                                 height: Constants.arrowsSize.height)
        arrowsLayer.frame = bounds
        arrowsLayer.path = arrowsPath(in: arrowsFrame).cgPath
        label.center = CGPoint(x: inner.midX, y: arrowsFrame.maxY + Constants.gap + label.bounds.height / 2)
    }

    /// Lights the side and fades out.
    func flash(duration: TimeInterval) {
        layer.removeAllAnimations()
        alpha = 1
        UIView.animate(withDuration: duration * 0.4, delay: duration * 0.6, options: [.beginFromCurrentState]) {
            self.alpha = 0
        }
    }

    /// Figma `+60`: a rectangle whose inner edge bulges out by `edgeDepth` at mid-height.
    private func areaPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let depth = min(edgeDepth, rect.width)
        switch side {
        case .forward:
            path.move(to: CGPoint(x: rect.minX + depth, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + depth, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.minX, y: rect.midY),
                          controlPoint1: CGPoint(x: rect.minX + depth, y: rect.maxY),
                          controlPoint2: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.147))
            path.addCurve(to: CGPoint(x: rect.minX + depth, y: rect.minY),
                          controlPoint1: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.147),
                          controlPoint2: CGPoint(x: rect.minX + depth, y: rect.minY))
        case .backward:
            path.move(to: CGPoint(x: rect.maxX - depth, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - depth, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                          controlPoint1: CGPoint(x: rect.maxX - depth, y: rect.maxY),
                          controlPoint2: CGPoint(x: rect.maxX, y: rect.maxY - rect.height * 0.147))
            path.addCurve(to: CGPoint(x: rect.maxX - depth, y: rect.minY),
                          controlPoint1: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.147),
                          controlPoint2: CGPoint(x: rect.maxX - depth, y: rect.minY))
        }
        path.close()
        return path
    }

    /// Three triangles pointing the way of the seek.
    private func arrowsPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let width = rect.width / 3
        for index in 0..<3 {
            let minX = rect.minX + CGFloat(index) * width
            let maxX = minX + width - 1
            if side == .forward {
                path.move(to: CGPoint(x: minX, y: rect.minY))
                path.addLine(to: CGPoint(x: maxX, y: rect.midY))
                path.addLine(to: CGPoint(x: minX, y: rect.maxY))
            } else {
                path.move(to: CGPoint(x: maxX, y: rect.minY))
                path.addLine(to: CGPoint(x: minX, y: rect.midY))
                path.addLine(to: CGPoint(x: maxX, y: rect.maxY))
            }
            path.close()
        }
        return path
    }

}
