//
//  BranchList.swift
//  GitWorktreeCleaner
//

import Foundation

/// Converts between the comma-separated text field used to enter merge
/// target branches and the `[String]` form stored/used elsewhere.
public enum BranchList {
    public static func parse(_ input: String) -> [String] {
        input
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    public static func format(_ branches: [String]) -> String {
        branches.joined(separator: ", ")
    }
}
