//
//  MainTab.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation

enum MainTab: Hashable, CaseIterable {
    case home
    case friends
    case groups
    case activity

    var title: String {
        switch self {
        case .home:     return "Home"
        case .friends:  return "Friends"
        case .groups:   return "Groups"
        case .activity: return "Activity"
        }
    }

    var iconName: String {
        switch self {
        case .home:     return "house.fill"
        case .friends:  return "person.2.fill"
        case .groups:   return "person.3.fill"
        case .activity: return "chart.bar.doc.horizontal.fill"
        }
    }
}
