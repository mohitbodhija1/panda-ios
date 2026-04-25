//
//  FriendsRoute.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//
//  In-stack navigation values pushed onto the Friends NavigationStack.
//

import Foundation

enum FriendsRoute: Hashable {
    case addFriend
    case addExpense(FriendRowItem)
    /// Per-friend transaction history (expenses + settlements) reachable by
    /// tapping a friend tile in the main list.
    case history(FriendRowItem)
}
