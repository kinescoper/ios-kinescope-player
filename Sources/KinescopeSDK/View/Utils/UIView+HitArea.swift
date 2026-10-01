//
//  UIView+HitArea.swift
//  KinescopeSDK
//

import UIKit

extension UIView {

    /// The smallest side of a tap target (Human Interface Guidelines).
    static let minimumHitSide: CGFloat = 44

    /// `bounds` grown around its center to at least ``minimumHitSide`` on each side.
    var minimumHitArea: CGRect {
        let dx = max(0, (Self.minimumHitSide - bounds.width) / 2)
        let dy = max(0, (Self.minimumHitSide - bounds.height) / 2)
        return bounds.insetBy(dx: -dx, dy: -dy)
    }

}
