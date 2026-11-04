import Foundation
import Testing

@testable import AppScreenshotCore

@Suite
final class BezelImageLoaderTests {

    private let tempRootURL: URL

    init() throws {
        tempRootURL = FileManager.default.temporaryDirectory.appending(
            path: "BezelImageLoaderTests-\(UUID().uuidString)"
        )
        try FileManager.default.createDirectory(
            at: tempRootURL,
            withIntermediateDirectories: true
        )
    }

    deinit {
        try? FileManager.default.removeItem(at: tempRootURL)
    }

    // MARK: - Helpers

    private static let device = AppScreenshotDevice(
        orientation: .portrait,
        color: .black,
        model: .iPhone16ProMax
    )

    /// Expected file name for `Self.device` per the loader's naming rule.
    private static let expectedFileName = "iPhone 16 Pro Max - Black - Portrait.png"

    /// Bezel images are downloaded into a nested directory tree such as
    /// `<base>/Bezels/Apple-Sketch-Library-Product-Bezels/<filename>.png`.
    /// Recreate that nesting to make sure the loader walks subdirectories.
    @discardableResult
    private func writeBezelFile(
        under baseDirectory: URL,
        fileName: String = BezelImageLoaderTests.expectedFileName,
        contents: Data = Data([0x89, 0x50, 0x4E, 0x47])  // "\x89PNG"
    ) throws -> URL {
        let nestedDirectory = baseDirectory
            .appending(path: "Bezels")
            .appending(path: "Apple-Sketch-Library-Product-Bezels")
        try FileManager.default.createDirectory(
            at: nestedDirectory,
            withIntermediateDirectories: true
        )
        let fileURL = nestedDirectory.appending(path: fileName)
        try contents.write(to: fileURL)
        return fileURL
    }

    // MARK: - Regression: existing behavior still works

    @Test
    func returnsBezelData_forAsciiPath() throws {
        let baseDirectory = tempRootURL.appending(path: "AppleDesignResource")
        let expectedFileURL = try writeBezelFile(under: baseDirectory)
        let expectedData = try Data(contentsOf: expectedFileURL)

        let data = try BezelImageLoader().imageData(
            Self.device,
            resourceBaseURL: baseDirectory
        )

        #expect(data == expectedData)
    }

    @Test
    func throws_whenMatchingFileMissing() throws {
        let baseDirectory = tempRootURL.appending(path: "AppleDesignResource")
        // Place an unrelated file so the directory is non-empty.
        try writeBezelFile(
            under: baseDirectory,
            fileName: "Unrelated - White - Landscape.png"
        )

        #expect(throws: AppScreenshotKitError.self) {
            try BezelImageLoader().imageData(
                Self.device,
                resourceBaseURL: baseDirectory
            )
        }
    }

    @Test
    func walksDeepDirectoryStructure() throws {
        let baseDirectory = tempRootURL.appending(path: "AppleDesignResource")
        let deeplyNested = baseDirectory
            .appending(path: "level1")
            .appending(path: "level2")
            .appending(path: "level3")
        try FileManager.default.createDirectory(
            at: deeplyNested,
            withIntermediateDirectories: true
        )
        let payload = Data("deep".utf8)
        try payload.write(to: deeplyNested.appending(path: Self.expectedFileName))

        let data = try BezelImageLoader().imageData(
            Self.device,
            resourceBaseURL: baseDirectory
        )

        #expect(data == payload)
    }

    // MARK: - Bug fix: paths that get percent-encoded by URL.path()

    /// Before the fix, `subpaths(atPath: url.path())` was passed a percent-encoded
    /// path (e.g. `/tmp/.../with%20space/...`). `FileManager` could not open that
    /// directory and returned `nil`, so the loader threw "No image file found"
    /// even though the file existed. This test fails on the old implementation.
    @Test
    func resolvesBezel_whenBaseDirectoryContainsSpaces() throws {
        let baseDirectory = tempRootURL
            .appending(path: "with space")
            .appending(path: "AppleDesignResource")
        let expectedFileURL = try writeBezelFile(under: baseDirectory)
        let expectedData = try Data(contentsOf: expectedFileURL)

        // Sanity-check that this test is actually exercising the bug it claims to:
        // URL.path() must percent-encode the space, and subpaths(atPath:) must
        // return nil for that encoded path. If either invariant ever stops
        // holding, this test no longer guards the regression.
        let encodedPath = baseDirectory.path()
        try #require(encodedPath.contains("%20"))
        try #require(FileManager.default.subpaths(atPath: encodedPath) == nil)

        let data = try BezelImageLoader().imageData(
            Self.device,
            resourceBaseURL: baseDirectory
        )

        #expect(data == expectedData)
    }

    @Test
    func resolvesBezel_whenBaseDirectoryContainsNonAsciiCharacters() throws {
        let baseDirectory = tempRootURL
            .appending(path: "テスト")
            .appending(path: "AppleDesignResource")
        let expectedFileURL = try writeBezelFile(under: baseDirectory)
        let expectedData = try Data(contentsOf: expectedFileURL)

        let encodedPath = baseDirectory.path()
        try #require(encodedPath.contains("%"))
        try #require(FileManager.default.subpaths(atPath: encodedPath) == nil)

        let data = try BezelImageLoader().imageData(
            Self.device,
            resourceBaseURL: baseDirectory
        )

        #expect(data == expectedData)
    }

    // MARK: - Apple Design Resources file names

    @Test(arguments: [
        (
            AppScreenshotDevice(orientation: .portrait, color: .black, model: .iPhone18ProMax),
            "iPhone 18 Pro Max - Black - Portrait.png",
            "iPhone 18 Pro Max - Black - Landscape.png"
        ),
        (
            AppScreenshotDevice(orientation: .landscape, color: .glacier, model: .iPhone18ProMax),
            "iPhone 18 Pro Max - Glacier - Landscape.png",
            "iPhone 18 Pro Max - Glacier - Portrait.png"
        ),
        (
            AppScreenshotDevice(orientation: .portrait, color: .spaceBlack, model: .iPadPro13M5),
            #"iPad Pro (M5) 13" - Space Black - Portrait.png"#,
            #"iPad Pro (M5) 13" - Space Black - Landscape.png"#
        ),
        (
            AppScreenshotDevice(orientation: .landscape, color: .silver, model: .iPadPro13M5),
            #"iPad Pro (M5) 13" - Silver - Landscape.png"#,
            #"iPad Pro (M5) 13" - Silver - Portrait.png"#
        ),
        (
            AppScreenshotDevice(orientation: .portrait, color: .nightSky, model: .iPhoneDuoOuter),
            "iPhone Duo - Night Sky - Outer Closed Portrait.png",
            "iPhone Duo - Night Sky - Outer Closed Landscape.png"
        ),
        (
            AppScreenshotDevice(orientation: .landscape, color: .starWhite, model: .iPhoneDuoOuter),
            "iPhone Duo - Star White - Outer Closed Landscape.png",
            "iPhone Duo - Star White - Outer Closed Portrait.png"
        ),
        (
            AppScreenshotDevice(orientation: .portrait, color: .nightSky, model: .iPhoneDuoInner),
            "iPhone Duo - Night Sky - Inner Open Portrait.png",
            "iPhone Duo - Night Sky - Inner Open Landscape.png"
        ),
        (
            AppScreenshotDevice(orientation: .landscape, color: .starWhite, model: .iPhoneDuoInner),
            "iPhone Duo - Star White - Inner Open Landscape.png",
            "iPhone Duo - Star White - Inner Open Portrait.png"
        ),
    ])
    func findsBezelNamedAsApple(
        device: AppScreenshotDevice,
        fileName: String,
        otherOrientationFileName: String
    ) throws {
        let baseDirectory = tempRootURL.appending(path: "AppleDesignResource")
        let payload = Data(fileName.utf8)
        try writeBezelFile(under: baseDirectory, fileName: fileName, contents: payload)
        try writeBezelFile(under: baseDirectory, fileName: otherOrientationFileName)

        let data = try BezelImageLoader().imageData(device, resourceBaseURL: baseDirectory)

        #expect(data == payload)
    }
}
