import XCTest
@testable import MaggoCore

final class StorageAndPicturesTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        let uniqueName = "MaggoStorageTest_\(UUID().uuidString)"
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueName)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }

    func testFolderSizeCalculationAndCaching() async throws {
        let service = FolderSizeService.shared

        let subfolder = tempDirectory.appendingPathComponent("Subfolder")
        try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)

        let file1 = subfolder.appendingPathComponent("data1.bin")
        let file2 = subfolder.appendingPathComponent("data2.bin")

        let data1 = Data(repeating: 0xAA, count: 1024) // 1 KB
        let data2 = Data(repeating: 0xBB, count: 2048) // 2 KB

        try data1.write(to: file1)
        try data2.write(to: file2)

        let now = Date()
        let calculated = await service.calculateSize(for: subfolder, currentDateModified: now)
        XCTAssertEqual(calculated, 3072) // 3 KB total

        // Verify it was cached
        let cached = await service.getCachedSize(for: subfolder, currentDateModified: now)
        XCTAssertEqual(cached, 3072)
    }

    func testVolumeCalculations() {
        let volume = VolumeItem(
            url: URL(fileURLWithPath: "/"),
            name: "Macintosh HD",
            isRemovable: false,
            isInternal: true,
            totalCapacity: 500_000_000_000, // 500 GB
            availableCapacity: 100_000_000_000 // 100 GB
        )

        XCTAssertEqual(volume.usedCapacity, 400_000_000_000)
        XCTAssertEqual(volume.usedPercentage, 0.8, accuracy: 0.001)
        XCTAssertTrue(volume.formattedAvailable.contains("available"))
        XCTAssertTrue(volume.formattedUsed.contains("used"))
    }

    func testPictureExtensionDetection() {
        let service = PictureIndexService.shared

        XCTAssertTrue(service.isSupportedImage(url: URL(fileURLWithPath: "/path/to/vacation.jpg")))
        XCTAssertTrue(service.isSupportedImage(url: URL(fileURLWithPath: "/path/to/photo.HEIC")))
        XCTAssertTrue(service.isSupportedImage(url: URL(fileURLWithPath: "/path/to/icon.png")))
        XCTAssertTrue(service.isSupportedImage(url: URL(fileURLWithPath: "/path/to/graphic.webp")))

        XCTAssertFalse(service.isSupportedImage(url: URL(fileURLWithPath: "/path/to/document.pdf")))
        XCTAssertFalse(service.isSupportedImage(url: URL(fileURLWithPath: "/path/to/archive.zip")))
    }

    func testApplicationBundleSizeCalculation() async throws {
        let service = FolderSizeService.shared
        let appBundle = tempDirectory.appendingPathComponent("MockApp.app")
        let macosDir = appBundle.appendingPathComponent("Contents/MacOS")
        let resDir = appBundle.appendingPathComponent("Contents/Resources")
        try FileManager.default.createDirectory(at: macosDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: resDir, withIntermediateDirectories: true)

        let bin = macosDir.appendingPathComponent("MockApp")
        let icon = resDir.appendingPathComponent("AppIcon.icns")
        let data1 = Data(repeating: 0x11, count: 4096)
        let data2 = Data(repeating: 0x22, count: 2048)
        try data1.write(to: bin)
        try data2.write(to: icon)

        let now = Date()
        let size = await service.calculateSize(for: appBundle, currentDateModified: now)
        XCTAssertEqual(size, 6144) // 4096 + 2048 = 6144 bytes
    }
}
