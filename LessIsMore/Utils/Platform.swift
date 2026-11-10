//
//  Platform.swift
//  LessIsMore
//
//  The social platform shown in the web view. The user switches between them
//  from the control panel; each platform has its own set of filters.
//

import Foundation

enum Platform: String, CaseIterable, Identifiable {
    case instagram
    case youtube

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .youtube: return "YouTube"
        }
    }

    var homeURL: URL {
        switch self {
        case .instagram: return URL(string: "https://www.instagram.com/")!
        case .youtube: return URL(string: "https://m.youtube.com/")!
        }
    }

    /// Whether a page URL belongs to this platform.
    func owns(host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        switch self {
        case .instagram: return host == "instagram.com" || host.hasSuffix(".instagram.com")
        case .youtube: return host == "youtube.com" || host.hasSuffix(".youtube.com")
        }
    }

    private static let storageKey = "selected_platform"

    static var current: Platform {
        get { Platform(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .instagram }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: storageKey) }
    }
}
