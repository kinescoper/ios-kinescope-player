import UIKit

extension UIImage {

    /// The image redrawn `scale` times larger, keeping its rendering mode; vector images stay sharp.
    func scaled(by scale: CGFloat) -> UIImage {
        guard scale != 1, size != .zero else {
            return self
        }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.preferred()
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image.withRenderingMode(renderingMode)
    }

}
