import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Content View

struct ContentView: View {
    @State private var sourceFiles: [URL] = []
    @State private var targetDirectory: URL?
    @State private var targetPathText: String = ""
    @State private var statusMessage: String = ""
    @State private var statusIsError: Bool = false
    @State private var isCreating: Bool = false
    @State private var isSourceDropTargeted: Bool = false
    @State private var isTargetDropTargeted: Bool = false
    @State private var targetDirValidationMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            mainBody

            Divider()

            footerView
        }
        .frame(minWidth: 400, minHeight: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }



    // MARK: - Main Body

    private var mainBody: some View {
        ScrollView {
            VStack(spacing: 24) {
                sourceFilesSection
                targetDirectorySection
            }
            .padding(16)
        }
    }

    // MARK: - Source Files Section

    private var sourceFilesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.secondary)
                Text("Source Files")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if !sourceFiles.isEmpty {
                    Text("\(sourceFiles.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor))
                }
            }

            VStack(spacing: 0) {
                if sourceFiles.isEmpty {
                    sourceDropZoneContent
                } else {
                    sourceFileListContent
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSourceDropTargeted
                          ? Color.accentColor.opacity(0.08)
                          : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSourceDropTargeted
                                    ? Color.accentColor : Color.gray.opacity(0.25),
                                style: StrokeStyle(
                                    lineWidth: isSourceDropTargeted ? 2 : 1,
                                    dash: isSourceDropTargeted ? [] : [5, 3]
                                )
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isSourceDropTargeted)
            .onDrop(
                of: [.fileURL],
                isTargeted: $isSourceDropTargeted,
                perform: handleSourceDrop
            )
        }
    }

    private var sourceDropZoneContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))
            Text("Drop files here")
                .font(.body)
                .foregroundColor(.secondary)
            Text("or")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
            Button("Browse Files…") {
                pickSourceFiles()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var sourceFileListContent: some View {
        VStack(spacing: 0) {
            ForEach(Array(sourceFiles.enumerated()), id: \.element) { index, url in
                SourceFileRow(url: url) {
                    sourceFiles.remove(at: index)
                }
            }

            Divider()
                .padding(.horizontal, 8)

            Button {
                pickSourceFiles()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                    Text("Add More Files")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
    }

    // MARK: - Target Directory Section

    private var targetDirectorySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .foregroundColor(.secondary)
                Text("Target Directory")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            HStack(spacing: 8) {
                if targetDirectory != nil, !targetPathText.isEmpty {
                    Image(nsImage: NSWorkspace.shared.icon(forFile: targetPathText))
                        .resizable()
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.4))
                }

                TextField(targetDirectory == nil ? "/path/to/destination" : "",
                          text: $targetPathText)
                    .textFieldStyle(.plain)
                    .font(.body.monospaced())
                    .onSubmit { commitTargetPath() }

                if !targetPathText.isEmpty {
                    Button {
                        clearTargetDirectory()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Clear")
                }

                Button("Browse…") {
                    pickTargetDirectory()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isTargetDropTargeted
                          ? Color.accentColor.opacity(0.08)
                          : Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isTargetDropTargeted
                                    ? Color.accentColor
                                    : (targetDirectory == nil
                                       ? Color.gray.opacity(0.25)
                                       : Color.gray.opacity(0.15)),
                                style: StrokeStyle(
                                    lineWidth: isTargetDropTargeted ? 2 : 1,
                                    dash: (targetDirectory == nil && !isTargetDropTargeted) ? [4, 3] : []
                                )
                            )
                    )
            )
            .onDrop(of: [.fileURL], isTargeted: $isTargetDropTargeted, perform: handleTargetDrop)

            if !targetDirValidationMessage.isEmpty {
                Label(targetDirValidationMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }



    // MARK: - Footer (Action Bar)

    private var footerView: some View {
        VStack(spacing: 10) {
            Button {
                createSymlinks()
            } label: {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "link")
                    }
                    Text(isCreating ? "Creating…" : "Create Symbolic Links")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(sourceFiles.isEmpty || targetDirectory == nil || isCreating)
            .keyboardShortcut(.return, modifiers: .command)

            if !statusMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: statusIsError
                          ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(statusIsError ? .red : .green)
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Spacer()
                    if !statusIsError {
                        Button("Clear") {
                            sourceFiles.removeAll()
                            clearTargetDirectory()
                            statusMessage = ""
                        }
                        .buttonStyle(.plain)
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
    }

    // MARK: - Actions

    private func pickSourceFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.title = "Select files to symlink"
        panel.message = "Choose one or more files or folders to create symbolic links for."

        guard panel.runModal() == .OK else { return }

        let newFiles = panel.urls.filter { !sourceFiles.contains($0) }
        sourceFiles.append(contentsOf: newFiles)
    }

    private func pickTargetDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Select target directory"
        panel.message = "Choose where to create the symbolic links."

        guard panel.runModal() == .OK, let url = panel.url else { return }

        setTargetDirectory(url)
    }

    private func commitTargetPath() {
        let trimmed = targetPathText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let url = URL(fileURLWithPath: (trimmed as NSString).expandingTildeInPath)
        setTargetDirectory(url)
    }

    private func setTargetDirectory(_ url: URL) {
        targetDirectory = url
        targetPathText = url.path

        // Validate
        let fm = FileManager.default
        var isDir: ObjCBool = false
        if !fm.fileExists(atPath: url.path, isDirectory: &isDir) {
            targetDirValidationMessage = "Directory does not exist yet. It will be created."
        } else if !isDir.boolValue {
            targetDirValidationMessage = "Path is not a directory."
        } else {
            targetDirValidationMessage = ""
        }
    }

    private func clearTargetDirectory() {
        targetDirectory = nil
        targetPathText = ""
        targetDirValidationMessage = ""
    }

    // MARK: - Drop Handling

    private func handleSourceDrop(providers: [NSItemProvider]) -> Bool {
        var success = false
        let group = DispatchGroup()

        for provider in providers {
            guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else {
                continue
            }
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
                defer { group.leave() }
                guard error == nil else { return }

                let url: URL? = {
                    if let data = item as? Data {
                        return URL(dataRepresentation: data, relativeTo: nil)
                    }
                    if let url = item as? URL {
                        return url
                    }
                    return nil
                }()

                if let url = url {
                    DispatchQueue.main.async {
                        if !sourceFiles.contains(url) {
                            sourceFiles.append(url)
                        }
                    }
                }
            }
            success = true
        }

        return success
    }

    private func handleTargetDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first,
              provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
            guard error == nil else { return }

            let url: URL? = {
                if let data = item as? Data {
                    return URL(dataRepresentation: data, relativeTo: nil)
                }
                if let url = item as? URL {
                    return url
                }
                return nil
            }()

            if let url = url {
                DispatchQueue.main.async {
                    setTargetDirectory(url)
                }
            }
        }

        return true
    }

    // MARK: - Symlink Creation

    private func createSymlinks() {
        guard let targetDir = targetDirectory, !sourceFiles.isEmpty else { return }

        isCreating = true
        statusMessage = ""
        statusIsError = false

        DispatchQueue.global(qos: .userInitiated).async {
            let result = SymLinkerService.createSymlinks(
                files: sourceFiles,
                targetDir: targetDir
            )

            DispatchQueue.main.async {
                isCreating = false

                let successCount = result.filter(\.isSuccess).count
                let failCount = result.filter { !$0.isSuccess }.count

                if failCount == 0 {
                    statusMessage = "Successfully created \(successCount) symbolic link\(successCount == 1 ? "" : "s")."
                    statusIsError = false
                } else if successCount > 0 {
                    let errors = result
                        .filter { !$0.isSuccess }
                        .compactMap { "\($0.file.lastPathComponent): \($0.error ?? "unknown error")" }
                        .joined(separator: "\n")
                    statusMessage = "Created \(successCount) link\(successCount == 1 ? "" : "s"), \(failCount) failed:\n\(errors)"
                    statusIsError = true
                } else {
                    let errors = result
                        .compactMap { "\($0.file.lastPathComponent): \($0.error ?? "unknown error")" }
                        .joined(separator: "\n")
                    statusMessage = "Failed to create symbolic links:\n\(errors)"
                    statusIsError = true
                }
            }
        }
    }
}

// MARK: - Source File Row

struct SourceFileRow: View {
    let url: URL
    let onRemove: () -> Void

    @State private var isHovering: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(url.lastPathComponent)
                    .font(.body)
                    .lineLimit(1)

                Text(url.deletingLastPathComponent().path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Spacer(minLength: 8)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isHovering ? .secondary : .secondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .help("Remove from list")
            .onHover { hovering in
                isHovering = hovering
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovering ? Color.gray.opacity(0.08) : .clear)
        )
        .contentShape(Rectangle())
        .contextMenu {
            Button("Reveal in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(url.path, forType: .string)
            }
            Divider()
            Button("Remove", role: .destructive) {
                onRemove()
            }
        }
    }
}

// MARK: - Symlink Service

struct SymLinkResult {
    let file: URL
    let isSuccess: Bool
    let error: String?
}

enum SymLinkerService {
    static func createSymlinks(files: [URL], targetDir: URL) -> [SymLinkResult] {
        let fm = FileManager.default

        // Ensure target directory exists
        var isDir: ObjCBool = false
        if !fm.fileExists(atPath: targetDir.path, isDirectory: &isDir) {
            do {
                try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
            } catch {
                // If we can't create the dir, all results fail
                return files.map {
                    SymLinkResult(file: $0, isSuccess: false, error: "Cannot create target directory: \(error.localizedDescription)")
                }
            }
        } else if !isDir.boolValue {
            return files.map {
                SymLinkResult(file: $0, isSuccess: false, error: "Target path is not a directory")
            }
        }

        return files.map { file in
            let linkName = file.lastPathComponent
            let linkPath = targetDir.appendingPathComponent(linkName)

            // Check if target already exists
            if fm.fileExists(atPath: linkPath.path) {
                // Try to remove if it's a broken/valid symlink, or ask user
                // For safety, skip with error
                return SymLinkResult(
                    file: file,
                    isSuccess: false,
                    error: "\(linkName) already exists in target directory"
                )
            }

            // Use POSIX ln -s via Process
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/ln")
            process.arguments = ["-s", file.path, linkPath.path]

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            do {
                try process.run()
                process.waitUntilExit()

                if process.terminationStatus == 0 {
                    return SymLinkResult(file: file, isSuccess: true, error: nil)
                } else {
                    let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let errMsg = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                        ?? "Unknown error (exit code \(process.terminationStatus))"
                    return SymLinkResult(file: file, isSuccess: false, error: errMsg)
                }
            } catch {
                return SymLinkResult(file: file, isSuccess: false, error: error.localizedDescription)
            }
        }
    }
}
