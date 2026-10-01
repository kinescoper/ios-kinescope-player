//
//  Bundle+Resources.swift
//  KinescopeSDK
//

import Foundation

extension Bundle {

    /// The SDK's strings and images. Found without `Bundle.module`, which stops the process when the host does not
    /// carry the resource bundle (an app's unit test bundle); then the SDK's code bundle, where strings fall back
    /// to their keys and images to empty ones.
    static let kinescopeResources: Bundle = {
        let code = Bundle(for: ResourcesToken.self)
        #if SWIFT_PACKAGE
        let name = "KinescopeSDK_KinescopeSDK.bundle"
        let places = [Bundle.main.resourceURL,
                      code.resourceURL,
                      code.bundleURL,
                      code.bundleURL.deletingLastPathComponent(),
                      Bundle.main.bundleURL]
        for case let place? in places {
            if let bundle = Bundle(url: place.appendingPathComponent(name)) {
                return bundle
            }
        }
        #endif
        if let resource = code.resourcePath, let bundle = Bundle(path: resource + "/KinescopeSDK.bundle") {
            return bundle
        }
        return code
    }()

}

private final class ResourcesToken {}
