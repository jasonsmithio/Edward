//
//  IceBarLocation.swift
//  Edward
//

import SwiftUI

/// Locations where the Edward Bar can appear.
enum IceBarLocation: Int, CaseIterable, Identifiable {
    /// The Edward Bar will appear in different locations based on context.
    case dynamic = 0

    /// The Edward Bar will appear centered below the mouse pointer.
    case mousePointer = 1

    /// The Edward Bar will appear centered below the Edward icon.
    case iceIcon = 2

    var id: Int { rawValue }

    /// Localized string key representation.
    var localized: LocalizedStringKey {
        switch self {
        case .dynamic: "Dynamic"
        case .mousePointer: "Mouse pointer"
        case .iceIcon: "Edward icon"
        }
    }
}
