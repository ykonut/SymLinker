import Foundation

// MARK: - Result Model

struct SymLinkResult {
    /// The source item that a link was created for.
    let file: URL
    /// The path of the created symbolic link inside the target directory.
    let linkURL: URL
    let isSuccess: Bool
    /// `true` when an existing symbolic link with the same name was replaced.
    let replacedExistingLink: Bool
    /// The original destination of a replaced symlink (used to undo the overwrite).
    let previousLinkDestination: String?
    let error: String?
}

/// The outcome of undoing the last link-creation operation.
struct SymLinkUndoSummary {
    /// Number of newly-created links that were removed.
    let removedNewLinks: Int
    /// Number of previously existing links that were restored.
    let restoredLinks: Int
    /// Entries that could not be undone safely (e.g. replaced by a real file).
    let skipped: Int
    let errors: [String]

    var didSomething: Bool { removedNewLinks > 0 || restoredLinks > 0 }
}

// MARK: - Symlink Service

/// Creates symbolic links in a target directory.
///
/// If the target directory already contains an entry with the same name:
/// * when it is a symbolic link (valid **or** broken), it is removed and
///   replaced with the new link — this is the "overwrite" behaviour;
/// * when it is a real file or folder, creation fails with an error so that
///   user data is never destroyed silently.
enum SymLinkerService {

    static func createSymlinks(files: [URL], targetDir: URL) -> [SymLinkResult] {
        let fm = FileManager.default

        // Ensure the target directory exists.
        var isDir: ObjCBool = false
        if !fm.fileExists(atPath: targetDir.path, isDirectory: &isDir) {
            do {
                try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
            } catch {
                return files.map {
                    SymLinkResult(
                        file: $0,
                        linkURL: targetDir.appendingPathComponent($0.lastPathComponent),
                        isSuccess: false,
                        replacedExistingLink: false,
                        previousLinkDestination: nil,
                        error: "Cannot create target directory: \(error.localizedDescription)"
                    )
                }
            }
        } else if !isDir.boolValue {
            return files.map {
                SymLinkResult(
                    file: $0,
                    linkURL: targetDir.appendingPathComponent($0.lastPathComponent),
                    isSuccess: false,
                    replacedExistingLink: false,
                    previousLinkDestination: nil,
                    error: "Target path is not a directory"
                )
            }
        }

        return files.map { createLink(for: $0, in: targetDir, fm: fm) }
    }

    // MARK: - Single Link

    private static func createLink(for file: URL, in targetDir: URL, fm: FileManager) -> SymLinkResult {
        let linkName = file.lastPathComponent
        let linkPath = targetDir.appendingPathComponent(linkName)
        var replacedExistingLink = false
        var previousDestination: String?

        if entryExists(atPath: linkPath.path, fm: fm) {
            if isSymbolicLink(atPath: linkPath.path, fm: fm) {
                // Remember the old target so an undo can restore it, then
                // remove the link itself (never its destination).
                previousDestination = try? fm.destinationOfSymbolicLink(atPath: linkPath.path)
                do {
                    try fm.removeItem(at: linkPath)
                } catch {
                    return SymLinkResult(
                        file: file,
                        linkURL: linkPath,
                        isSuccess: false,
                        replacedExistingLink: false,
                        previousLinkDestination: nil,
                        error: "Could not overwrite existing symlink: \(error.localizedDescription)"
                    )
                }
                replacedExistingLink = true
            } else {
                // Never clobber a real file or folder.
                return SymLinkResult(
                    file: file,
                    linkURL: linkPath,
                    isSuccess: false,
                    replacedExistingLink: false,
                    previousLinkDestination: nil,
                    error: "\(linkName) already exists in the target directory and is not a symlink"
                )
            }
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ln")
        process.arguments = ["-s", file.path, linkPath.path]

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                return SymLinkResult(
                    file: file,
                    linkURL: linkPath,
                    isSuccess: true,
                    replacedExistingLink: replacedExistingLink,
                    previousLinkDestination: replacedExistingLink ? previousDestination : nil,
                    error: nil
                )
            } else {
                // If we removed an old link and then failed, try to put it back.
                if replacedExistingLink, let previousDestination {
                    try? fm.createSymbolicLink(atPath: linkPath.path, withDestinationPath: previousDestination)
                }
                let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let errMsg = String(data: errData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? "Unknown error (exit code \(process.terminationStatus))"
                return SymLinkResult(
                    file: file,
                    linkURL: linkPath,
                    isSuccess: false,
                    replacedExistingLink: false,
                    previousLinkDestination: nil,
                    error: errMsg
                )
            }
        } catch {
            if replacedExistingLink, let previousDestination {
                try? fm.createSymbolicLink(atPath: linkPath.path, withDestinationPath: previousDestination)
            }
            return SymLinkResult(
                file: file,
                linkURL: linkPath,
                isSuccess: false,
                replacedExistingLink: false,
                previousLinkDestination: nil,
                error: error.localizedDescription
            )
        }
    }

    // MARK: - Undo

    /// Reverts the successful results of a previous `createSymlinks` call:
    /// newly created links are removed, and overwritten links are restored to
    /// their original destinations.
    ///
    /// The operation is conservative: a link is only touched when it still
    /// points at the source we created it for, and real files/folders are
    /// never deleted.
    static func undo(results: [SymLinkResult]) -> SymLinkUndoSummary {
        let fm = FileManager.default
        var removedNewLinks = 0
        var restoredLinks = 0
        var skipped = 0
        var errors: [String] = []

        for result in results where result.isSuccess {
            let link = result.linkURL

            guard entryExists(atPath: link.path, fm: fm) else {
                // Already gone; nothing else to do.
                skipped += 1
                continue
            }

            guard isSymbolicLink(atPath: link.path, fm: fm) else {
                errors.append("\(link.lastPathComponent): no longer a symbolic link, left in place")
                skipped += 1
                continue
            }

            let currentDestination = try? fm.destinationOfSymbolicLink(atPath: link.path)
            guard currentDestination == result.file.path else {
                errors.append("\(link.lastPathComponent): link target changed, left in place")
                skipped += 1
                continue
            }

            do {
                try fm.removeItem(at: link)
                if let previous = result.previousLinkDestination {
                    try fm.createSymbolicLink(atPath: link.path, withDestinationPath: previous)
                    restoredLinks += 1
                } else {
                    removedNewLinks += 1
                }
            } catch {
                errors.append("\(link.lastPathComponent): \(error.localizedDescription)")
            }
        }

        return SymLinkUndoSummary(
            removedNewLinks: removedNewLinks,
            restoredLinks: restoredLinks,
            skipped: skipped,
            errors: errors
        )
    }

    // MARK: - Lookup Helpers

    /// Returns true if *any* filesystem entry exists at `path`, including a
    /// broken symlink. `FileManager.fileExists(atPath:)` follows links and
    /// reports `false` for a symlink whose destination is missing, so it alone
    /// is not enough to detect an existing link.
    static func entryExists(atPath path: String, fm: FileManager = .default) -> Bool {
        if fm.fileExists(atPath: path) { return true }
        return isSymbolicLink(atPath: path, fm: fm)
    }

    /// Returns true if the entry at `path` is a symbolic link (valid or broken).
    static func isSymbolicLink(atPath path: String, fm: FileManager = .default) -> Bool {
        (try? fm.destinationOfSymbolicLink(atPath: path)) != nil
    }
}
