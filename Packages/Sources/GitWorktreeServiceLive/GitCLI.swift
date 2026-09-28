//
//  GitCLI.swift
//  GitWorktreeCleaner
//

import Foundation
import Localization

struct CommandResult: Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String

    var succeeded: Bool { exitCode == 0 }
}

enum GitCLIError: LocalizedError {
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let message):
            return String(localized: Constant.ErrorAlert.gitLaunchFailed(reason: message))
        }
    }
}

/// Runs `git` through a login shell so it resolves the user's PATH
/// (Homebrew, version managers, etc.) the same way a Terminal session would.
struct GitCLI: Sendable {
    func run(_ arguments: [String], in directory: String) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", "git " + arguments.map(Self.shellEscape).joined(separator: " ")]
        process.currentDirectoryURL = URL(fileURLWithPath: directory)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw GitCLIError.launchFailed(error.localizedDescription)
        }

        var stdoutData = Data()
        var stderrData = Data()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        group.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }

        process.waitUntilExit()
        group.wait()

        return CommandResult(
            exitCode: process.terminationStatus,
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? ""
        )
    }

    private static func shellEscape(_ argument: String) -> String {
        "'" + argument.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
