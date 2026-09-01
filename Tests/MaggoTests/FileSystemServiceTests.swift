import XCTest
@testable import MaggoCore

final class FileSystemServiceTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() async throws {
        try await super.setUp()
        let uniqueName = "MaggoFSTest_\(UUID().uuidString)"
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(uniqueName)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try await super.tearDown()
    }

    func testFetchDirectoryContents() async throws {
        let service = FileSystemService.shared

        // Create sample files and folders
        let file1 = tempDirectory.appendingPathComponent("document.pdf")
        let file2 = tempDirectory.appendingPathComponent("notes.txt")
        let hidden = tempDirectory.appendingPathComponent(".hidden_file")
        let subfolder = tempDirectory.appendingPathComponent("Subfolder")

        try "PDF content".write(to: file1, atomically: true, encoding: .utf8)
        try "Notes content".write(to: file2, atomically: true, encoding: .utf8)
        try "Hidden content".write(to: hidden, atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: subfolder, withIntermediateDirectories: true)

        // Fetch without hidden files
        let visibleItems = try await service.fetchDirectoryContents(at: tempDirectory, showHidden: false)
        XCTAssertEqual(visibleItems.count, 3)
        XCTAssertFalse(visibleItems.contains { $0.name == ".hidden_file" })

        // Fetch with hidden files
        let allItems = try await service.fetchDirectoryContents(at: tempDirectory, showHidden: true)
        XCTAssertEqual(allItems.count, 4)
        XCTAssertTrue(allItems.contains { $0.name == ".hidden_file" })

        // Verify folder detection
        let folderItem = visibleItems.first { $0.name == "Subfolder" }
        XCTAssertNotNil(folderItem)
        XCTAssertTrue(folderItem?.isDirectory == true)
    }

    func testFileSortOption() {
        let now = Date()
        let itemA = FileItem(url: URL(fileURLWithPath: "/tmp/b_folder"), name: "b_folder", isDirectory: true, dateModified: now)
        let itemB = FileItem(url: URL(fileURLWithPath: "/tmp/a_folder"), name: "a_folder", isDirectory: true, dateModified: now)
        let fileC = FileItem(url: URL(fileURLWithPath: "/tmp/z_file.txt"), name: "z_file.txt", isDirectory: false, dateModified: now)
        let fileD = FileItem(url: URL(fileURLWithPath: "/tmp/a_file.txt"), name: "a_file.txt", isDirectory: false, dateModified: now)

        let sorter = FileSortOption(field: .name, ascending: true)
        let sorted = sorter.sort([fileC, itemA, fileD, itemB])

        // Folders must always precede files, then alphabetical
        XCTAssertEqual(sorted.map(\.name), ["a_folder", "b_folder", "a_file.txt", "z_file.txt"])
    }
}
