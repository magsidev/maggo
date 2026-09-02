import Foundation
import Dispatch

public final class DirectoryWatcher: @unchecked Sendable {
    private let url: URL
    private let queue: DispatchQueue
    private var source: (any DispatchSourceFileSystemObject)?
    private var fileDescriptor: Int32 = -1
    private var debounceWorkItem: DispatchWorkItem?
    private let onChange: @MainActor () -> Void

    public init(url: URL, onChange: @escaping @MainActor () -> Void) {
        self.url = url
        self.onChange = onChange
        self.queue = DispatchQueue(label: "com.maggo.directorywatcher.\(UUID().uuidString)", qos: .utility)
        start()
    }

    deinit {
        stop()
    }

    public func start() {
        stop()

        let path = url.path
        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else { return }
        self.fileDescriptor = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend, .attrib],
            queue: queue
        )

        src.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.scheduleDebouncedChange()
        }

        src.setCancelHandler {
            close(fd)
        }

        self.source = src
        src.resume()
    }

    public func stop() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil

        if let src = source {
            src.cancel()
            self.source = nil
        }
        self.fileDescriptor = -1
    }

    private func scheduleDebouncedChange() {
        debounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.onChange()
            }
        }

        self.debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + 0.15, execute: workItem)
    }
}
