//
//  NotificationsBag.swift
//  KinescopeSDK
//
//  Created by Nikita Korobeinikov on 26.02.2024.
//

import Foundation

final class NotificationsBag: GenericBag<NotificationSubKey, SelectorBasedObserverFactory> {
    
    // Weak: the player owns this bag, a strong reference made every player leak.
    // Selector-based observers are unregistered by NotificationCenter on deallocation.
    private weak var observer: AnyObject?

    init(observer: AnyObject) {
        self.observer = observer
    }

    override func addObserver(for key: NotificationSubKey, using factory: SelectorBasedObserverFactory) {
        guard let observer, let selector = factory.provide() else {
            return
        }
        NotificationCenter.default.addObserver(observer,
                                               selector: selector,
                                               name: key.notificationName,
                                               object: factory.object)
    }

    override func removeAll() {
        super.removeAll()
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

}
