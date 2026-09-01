import XCTest
@testable import MaggoCore

final class FileOperationEngineTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        let uniqueName = "MaggoTest_\(UUID().uuidString)"
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueName)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }

    func testCreateFolderAndUndo() throws {
        let engine = FileOperationEngine.shared
        let folder = try engine.createFolder(at: tempDirectory, name: "TestFolder")

        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.path))
        XCTAssertEqual(folder.lastPathComponent, "TestFolder")

        // Test Undo
        try engine.undo()
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.path))
    }

    func testDuplicateFileAndUndo() throws {
        let engine = FileOperationEngine.shared
        let fileURL = tempDirectory.appendingPathComponent("sample.txt")
        try "Hello Maggo".write(to: fileURL, atomically: true, encoding: .utf8)

        let duplicateURL = try engine.duplicateItem(at: fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: duplicateURL.path))
        XCTAssertEqual(duplicateURL.lastPathComponent, "sample copy.txt")

        // Test Undo
        try engine.undo()
        XCTAssertFalse(FileManager.default.fileExists(atPath: duplicateURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testRenameFileAndUndo() throws {
        let engine = FileOperationEngine.shared
        let fileURL = tempDirectory.appendingPathComponent("original.txt")
        try "Rename test".write(to: fileURL, atomically: true, encoding: .utf8)

        let renamedURL = try engine.renameItem(at: fileURL, newName: "renamed.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamedURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))

        // Test Undo
        try engine.undo()
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: renamedURL.path))
    }

    func testMoveFilesAndUndo() throws {
        let engine = FileOperationEngine.shared
        let subfolder = tempDirectory.appendingPathComponent("Sub")
        try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)

        let fileURL = tempDirectory.appendingPathComponent("moving.txt")
        try "Move me".write(to: fileURL, atomically: true, encoding: .utf8)

        let moved = try engine.moveItems(urls: [fileURL], to: subfolder)
        XCTAssertEqual(moved.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: subfolder.appendingPathComponent("moving.txt").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))

        // Test Undo
        try engine.undo()
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: subfolder.appendingPathComponent("moving.txt").path))
    }

    func testPasteboardCopyAndCut() {
        let pb = PasteboardService.shared
        let file1 = tempDirectory.appendingPathComponent("doc1.pdf")
        let file2 = tempDirectory.appendingPathComponent("doc2.pdf")

        // Test Copy
        pb.copy(urls: [file1, file2], isCut: false)
        XCTAssertTrue(pb.hasFileURLs())
        let (copyURLs, isCutFalse) = pb.getFileURLs()
        XCTAssertEqual(copyURLs.count, 2)
        XCTAssertFalse(isCutFalse)

        // Test Cut
        pb.copy(urls: [file1], isCut: true)
        let (cutURLs, isCutTrue) = pb.getFileURLs()
        XCTAssertEqual(cutURLs.count, 1)
        XCTAssertTrue(isCutTrue)
    }
}
