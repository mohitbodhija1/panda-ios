//
//  ActivityDestination.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  Routing target for tapping a row in Recent Activity / the Activity tab.
//  Lives outside the views so Home (full-screen cover) and Activity
//  (NavigationLink + .navigationDestination) can share it.
//

import Foundation

enum ActivityDestination: Hashable, Identifiable {
    case group(GroupRowItem)
    case friend(FriendRowItem)

    var id: String {
        switch self {
        case .group(let g):  return "group-\(g.id.uuidString)"
        case .friend(let f): return "friend-\(f.id.uuidString)"
        }
    }
}
