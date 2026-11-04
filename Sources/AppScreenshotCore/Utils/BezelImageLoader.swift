//
//  BezelImageLoader.swift
//  AppScreenshotKit
//
//  Created by Shuhei Shitamori on 2025/04/25.
//

import Foundation

struct BezelImageLoader {

    func imageData(_ device: AppScreenshotDevice, resourceBaseURL: URL) throws -> Data {
        let imageFileNameCandidates = imageFileNameCandidates(device)
        let fileURLs =
            FileManager.default.enumerator(
                at: resourceBaseURL,
                includingPropertiesForKeys: nil
            )?
            .allObjects as? [URL] ?? []
        guard
            let imageURL = fileURLs.first(where: { url in
                imageFileNameCandidates.contains(url.lastPathComponent)
            })
        else {
            throw AppScreenshotKitError(
                message:
                    "No image file found: \(imageFileNameCandidates[0]) in \(resourceBaseURL.path(percentEncoded: false))"
            )
        }

        return try Data(contentsOf: imageURL)
    }

    private func imageFileNameCandidates(_ device: AppScreenshotDevice) -> [String] {
        let deviceNames =
            switch device.model {
            case .iPadPro11M5: [#"iPad Pro (M5) 11""#]
            case .iPadPro13M5: [#"iPad Pro (M5) 13""#]
            case .iPadPro11M4: [device.model.rawValue, "iPad Pro 11(M4)"]
            case .iPadPro13M4: [device.model.rawValue, "iPad Pro 13 (M4)"]
            case .iPadAir11M2: [device.model.rawValue, "iPad Air 11 (M2)"]
            case .iPadAir13M2: [device.model.rawValue, "iPad Air 13 (M2)"]
            case .iPhoneDuoOuter, .iPhoneDuoInner: ["iPhone Duo"]
            default: [device.model.rawValue]
            }
        let orientation = device.orientation.rawValue
        let pose =
            switch device.model {
            case .iPhoneDuoOuter: "Outer Closed \(orientation)"
            case .iPhoneDuoInner: "Inner Open \(orientation)"
            default: orientation
            }
        return deviceNames.map { "\($0) - \(device.color.rawValue) - \(pose).png" }
    }
}
