//
//  GroupAvatar.swift
//  PandaSplit - Bill Splitter & Group Expense Tracker
//

import Foundation

enum GroupAvatar {
    static let keys: [String] = (1...3).map { "group_avatar_\($0)" }
    static let fallbackImageName: String = "panda_logo"

    static func imageName(for avatarKey: String?, groupId: UUID?) -> String {
        if let avatarKey, keys.contains(avatarKey) {
            return avatarKey
        }
        guard let groupId else { return fallbackImageName }
        let index = abs(groupId.uuidString.hashValue) % keys.count
        return keys[index]
    }

    static func randomKey() -> String {
        keys.randomElement() ?? keys[0]
    }
}
