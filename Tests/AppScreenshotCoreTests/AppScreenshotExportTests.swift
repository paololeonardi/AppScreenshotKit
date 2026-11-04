import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import Testing

@testable import AppScreenshotCore

// macOS renders at the display's backing scale, so exact pixel sizes only hold on iOS.
#if canImport(UIKit)
    @Suite
    struct AppScreenshotExportTests {

        private struct NewDevicesScreenshot: AppScreenshot {
            static let configuration = AppScreenshotConfiguration(
                .iPhoneDuoOuter(),
                .iPhoneDuoOuter(orientation: .landscape),
                .iPhoneDuoInner(),
                .iPhoneDuoInner(orientation: .landscape),
                .iPhone69Inch(model: .iPhone18ProMax()),
                .iPad130Inch(model: .iPadPro13M5())
            )

            static func body(environment: AppScreenshotEnvironment) -> some View {
                Color.blue
            }
        }

        @Test @MainActor
        func exportsAtAppStoreScreenshotSize() throws {
            let outputs = try NewDevicesScreenshot.export()

            let pixelSizes = try outputs.map { try pixelSize(of: $0.imageData) }

            #expect(
                pixelSizes == [
                    CGSize(width: 1398, height: 2034),
                    CGSize(width: 2034, height: 1398),
                    CGSize(width: 2007, height: 2853),
                    CGSize(width: 2853, height: 2007),
                    CGSize(width: 1320, height: 2868),
                    CGSize(width: 2048, height: 2732),
                ]
            )
        }

        private func pixelSize(of imageData: Data) throws -> CGSize {
            let source = try #require(CGImageSourceCreateWithData(imageData as CFData, nil))
            let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
            return CGSize(width: image.width, height: image.height)
        }
    }
#endif
