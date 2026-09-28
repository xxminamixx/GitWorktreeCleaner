//
//  UserDefaultsClient.swift
//  GitWorktreeCleaner
//

import Dependencies
import DependenciesMacros
import Foundation

/// Thin, generic interface over `UserDefaults` reads/writes. Key management
/// and decoding/encoding stay the caller's responsibility; this only exists
/// to make raw persistence I/O swappable/testable via `@Dependency`.
@DependencyClient
public struct UserDefaultsClient: Sendable {
    public var stringArray: @Sendable (_ key: String) -> [String]? = { _ in nil }
    public var setStringArray: @Sendable (_ key: String, _ value: [String]?) -> Void
    public var string: @Sendable (_ key: String) -> String? = { _ in nil }
    public var setString: @Sendable (_ key: String, _ value: String?) -> Void
    public var data: @Sendable (_ key: String) -> Data? = { _ in nil }
    public var setData: @Sendable (_ key: String, _ value: Data?) -> Void
}

extension UserDefaultsClient: TestDependencyKey {
    public static let testValue = Self()
}

extension DependencyValues {
    public var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
