//
//  FriendData.swift
//  Ruisi
//
//  Created by yang on 2017/11/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

class FriendData {

    var uid: Int
    var username: String
    var usernameColor: UIColor?
    var description: String?
    var isOnline: Bool
    var isFriend: Bool

    init(uid: Int, username: String, description: String?, usernameColor: UIColor? = nil, online: Bool = false, isFriend: Bool = true) {
        self.uid = uid
        self.username = username
        self.description = description
        self.usernameColor = usernameColor
        self.isOnline = online
        self.isFriend = isFriend
    }
}
