//
//  AirPlayOptionControl.swift
//  KinescopeSDK
//
//  Created by Никита Гагаринов on 13.04.2021.
//

import AVFoundation
import AVKit
import MediaPlayer

final class AirPlayOptionControl: UIControl {

    private let theme: KinescopePlayerTheme
    /// A supplied glyph over the system route picker, which cannot take an image of its own.
    private let glyphView = UIImageView()
    private weak var routePicker: UIView?

    // MARK: - Initialization

    init(theme: KinescopePlayerTheme = .default, tintColor: UIColor = .white) {
        self.theme = theme
        super.init(frame: .zero)
        self.tintColor = tintColor
        setupInitialState()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didAirPlayStateChanged),
                                               name: .MPVolumeViewWirelessRouteActiveDidChange,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didAudioRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        routePicker?.frame = minimumHitArea
    }

    /// The route picker reaches past the option's frame to a 44-point target.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        minimumHitArea.contains(point)
    }

}

// MARK: - Private Methods

private extension AirPlayOptionControl {

    var hasCustomGlyph: Bool {
        theme.icons.custom(.airPlay) != nil
    }

    func setupInitialState() {
        let systemView: UIView
        if #available(iOS 11.0, *) {
            let routePickerView = AVRoutePickerView()
            if #available(iOS 13.0, *) {
                routePickerView.prioritizesVideoDevices = true
            }
            if hasCustomGlyph {
                // The picker keeps the taps; its own glyph is hidden under the supplied one.
                routePickerView.tintColor = .clear
                routePickerView.activeTintColor = .clear
            }
            routePickerView.accessibilityLabel = theme.accessibilityLabels.airPlay
            systemView = routePickerView
        } else {
            let volumeView = MPVolumeView(frame: .zero)
            volumeView.showsVolumeSlider = false
            volumeView.setRouteButtonImage(UIImage.image(named: getImageName(for: volumeView)), for: .normal)
            systemView = volumeView
        }

        // The picker takes the taps, so it is the one grown to a 44-point target around the option.
        addSubview(systemView)
        routePicker = systemView

        if hasCustomGlyph {
            glyphView.contentMode = .center
            glyphView.isUserInteractionEnabled = false
            addSubview(glyphView)
            stretch(view: glyphView)
            updateGlyph()
        }
    }

    func getImageName(for volumeView: MPVolumeView) -> String {
        return volumeView.isWirelessRouteActive ? "airPlayActive" : "airPlay"
    }

    func updateGlyph() {
        let isActive = AVAudioSession.sharedInstance().currentRoute.outputs.contains { $0.portType == .airPlay }
        let icon: KinescopePlayerIcon = isActive && theme.icons.custom(.airPlayActive) != nil ? .airPlayActive : .airPlay
        glyphView.image = theme.icons.image(for: icon)?.scaled(by: theme.metrics.iconGlyphScale)
    }

    @objc
    func didAirPlayStateChanged(_ notification: NSNotification) {
        guard let volumeView = notification.object as? MPVolumeView else {
            return
        }
        volumeView.setRouteButtonImage(UIImage.image(named: getImageName(for: volumeView)), for: .normal)
    }

    @objc
    func didAudioRouteChange(_ notification: NSNotification) {
        guard hasCustomGlyph else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.updateGlyph()
        }
    }

}
