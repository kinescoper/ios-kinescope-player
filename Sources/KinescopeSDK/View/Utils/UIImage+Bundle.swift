import UIKit

extension UIImage {
    static func image(named: String) -> UIImage {
        let traitCollection = UITraitCollection(displayScale: UIScreen.main.scale)
        let bundle = Bundle.kinescopeResources

        // swiftlint:disable:next image_name_initialization
        return UIImage(named: named, in: bundle, compatibleWith: traitCollection) ?? UIImage()
    }
}
