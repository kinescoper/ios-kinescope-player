//
//  SideMenuSlideCoordinator.swift
//  KinescopeSDK
//
//  Created by Никита Коробейников on 05.04.2021.
//

import UIKit

struct SideMenuSlideCoordinator: SideMenuCoordinator {

    // MARK: - Constants

    private enum Constants {
        static let animationDuration: TimeInterval = 0.25
    }

    // MARK: - Methods

    func present(view: SideMenu, in parent: UIView, animated: Bool) {
        if case let .card(width, cornerRadius, margins) = view.theme.menu.presentation {
            presentCard(view: view, in: parent, animated: animated,
                        width: width, cornerRadius: cornerRadius, margins: margins)
            return
        }
        parent.addSubview(view)

        let width = CGFloat.minimum(parent.frame.width, UIScreen.main.bounds.height)

        view.frame = .init(origin: .init(x: parent.frame.width, y: 0),
                           size: .init(width: width, height: parent.frame.height))

        let destinationOrigin = CGPoint(x: parent.frame.width - width, y: 0)

        if animated {
            UIView.animate(withDuration: Constants.animationDuration,
                           animations: { [weak view] in
                            view?.frame.origin = destinationOrigin
                           })
        } else {
            view.frame.origin = destinationOrigin
        }
    }

    func dismiss(view: SideMenu, from parent: UIView, animated: Bool) {
        if view.theme.menu.isCard {
            guard animated else {
                view.removeFromSuperview()
                return
            }
            UIView.animate(withDuration: Constants.animationDuration,
                           animations: { [weak view] in
                            view?.alpha = 0
                           },
                           completion: { [weak view] _ in
                            view?.removeFromSuperview()
                           })
            return
        }

        let destinationOrigin = CGPoint(x: parent.frame.width, y: 0)

        if animated {
            UIView.animate(withDuration: Constants.animationDuration,
                           animations: { [weak view] in
                            view?.frame.origin = destinationOrigin
                           },
                           completion: { [weak view] _ in
                            view?.removeFromSuperview()
                           })
        } else {
            view.removeFromSuperview()
        }

    }

    // MARK: - Card

    /// The card stands on the bottom margin at the trailing one, as tall as its rows up to the top margin.
    private func presentCard(view: SideMenu,
                             in parent: UIView,
                             animated: Bool,
                             width: CGFloat,
                             cornerRadius: CGFloat,
                             margins: UIEdgeInsets) {
        parent.addSubview(view)
        let bounds = parent.bounds.inset(by: parent.safeAreaInsets).inset(by: margins)
        let cardWidth = max(0, min(width, bounds.width))
        let height = max(0, min(view.preferredHeight, bounds.height))
        view.frame = CGRect(x: bounds.maxX - cardWidth, y: bounds.maxY - height, width: cardWidth, height: height)
        view.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true

        guard animated else {
            return
        }
        view.alpha = 0
        UIView.animate(withDuration: Constants.animationDuration) { [weak view] in
            view?.alpha = 1
        }
    }

}
