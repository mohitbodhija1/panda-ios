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
}
