//
//  XtreamProfileItem.swift
//  I340_IPTV
//

import Foundation

struct XtreamProfileItem: Identifiable, Equatable {
    let id: String
    var name: String
    let profileID: String
    let serverURL: String
    let password: String
    let avatarName: String
    let updatedText: String
    
    init(
        id: String = UUID().uuidString,
        name: String,
        profileID: String,
        serverURL: String,
        password: String = "",
        avatarName: String,
        updatedText: String
    ) {
        self.id = id
        self.name = name
        self.profileID = profileID
        self.serverURL = serverURL
        self.password = password
        self.avatarName = avatarName
        self.updatedText = updatedText
    }
}
