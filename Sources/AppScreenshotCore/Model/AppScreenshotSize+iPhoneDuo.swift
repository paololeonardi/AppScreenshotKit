//
//  AppScreenshotSize+iPhoneDuo.swift
//  AppScreenshotKit
//

import Foundation

extension AppScreenshotSize {

    /// Color options for iPhone Duo.
    public enum IPhoneDuoColor {
        case nightSky
        case starWhite
    }

    /// Returns an AppScreenshotSize for iPhone Duo's outer display, used while the device is closed.
    ///
    /// The screenshot size follows the orientation: 1398x2034 in portrait, 2034x1398 in landscape.
    public static func iPhoneDuoOuter(
        color: IPhoneDuoColor = .nightSky,
        orientation: DeviceOrientation = .portrait
    ) -> AppScreenshotSize {
        iPhoneDuo(.outer, color: color, orientation: orientation)
    }

    /// Returns an AppScreenshotSize for iPhone Duo's inner display, used while the device is open.
    ///
    /// The screenshot size follows the orientation: 2007x2853 in portrait, 2853x2007 in landscape.
    public static func iPhoneDuoInner(
        color: IPhoneDuoColor = .nightSky,
        orientation: DeviceOrientation = .portrait
    ) -> AppScreenshotSize {
        iPhoneDuo(.inner, color: color, orientation: orientation)
    }

    enum IPhoneDuoDisplay {
        case outer
        case inner

        var model: DeviceModel {
            switch self {
            case .outer: .iPhoneDuoOuter
            case .inner: .iPhoneDuoInner
            }
        }
    }

    enum IPhoneDuoSizeOption: SizeOption {
        case w1398h2034
        case w2034h1398
        case w2007h2853
        case w2853h2007

        init(display: IPhoneDuoDisplay, orientation: DeviceOrientation) {
            self =
                switch (display, orientation) {
                case (.outer, .portrait): .w1398h2034
                case (.outer, .landscape): .w2034h1398
                case (.inner, .portrait): .w2007h2853
                case (.inner, .landscape): .w2853h2007
                }
        }

        var size: CGSize {
            switch self {
            case .w1398h2034: CGSize(width: 1398, height: 2034)
            case .w2034h1398: CGSize(width: 2034, height: 1398)
            case .w2007h2853: CGSize(width: 2007, height: 2853)
            case .w2853h2007: CGSize(width: 2853, height: 2007)
            }
        }
    }

    private static func iPhoneDuo(
        _ display: IPhoneDuoDisplay,
        color: IPhoneDuoColor,
        orientation: DeviceOrientation
    ) -> AppScreenshotSize {
        AppScreenshotSize(
            device: AppScreenshotDevice(
                orientation: orientation,
                color: color.deviceColor,
                model: display.model
            ),
            size: IPhoneDuoSizeOption(display: display, orientation: orientation)
        )
    }
}

extension AppScreenshotSize.IPhoneDuoColor: DeviceColorConvertable {
    var deviceColor: DeviceColor {
        switch self {
        case .nightSky: .nightSky
        case .starWhite: .starWhite
        }
    }
}

extension AppScreenshotSize.IPhoneDuoColor: CaseIterable {}

extension AppScreenshotSize {

    static var iPhoneDuoOuterAll: [AppScreenshotSize] {
        allCases(of: .outer)
    }

    static var iPhoneDuoInnerAll: [AppScreenshotSize] {
        allCases(of: .inner)
    }

    static var iPhoneDuoAll: [AppScreenshotSize] {
        iPhoneDuoOuterAll + iPhoneDuoInnerAll
    }

    private static func allCases(of display: IPhoneDuoDisplay) -> [AppScreenshotSize] {
        DeviceOrientation.allCases.flatMap { orientation in
            IPhoneDuoColor.allCases.map { color in
                iPhoneDuo(display, color: color, orientation: orientation)
            }
        }
    }
}
