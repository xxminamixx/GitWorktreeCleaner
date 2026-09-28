//
//  UserDefaultsClient+Live.swift
//  GitWorktreeCleaner
//

import Dependencies
import Foundation
import UserDefaultsClient

extension UserDefaultsClient: DependencyKey {
    public static let liveValue = Self(
        stringArray: { UserDefaults.standard.stringArray(forKey: $0) },
        setStringArray: { key, value in UserDefaults.standard.set(value, forKey: key) },
        string: { UserDefaults.standard.string(forKey: $0) },
        setString: { key, value in UserDefaults.standard.set(value, forKey: key) },
        data: { UserDefaults.standard.data(forKey: $0) },
        setData: { key, value in UserDefaults.standard.set(value, forKey: key) }
    )
}
