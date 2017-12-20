//
//  ChatData.swift
//  Ruisi
//
//  Created by yang on 2017/11/30.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

class ChatData {

    var uid: Int
    var uname: String
    var time: String
    var message: String

    init(uid: Int, uname: String, message: String, time: String) {
        self.uid = uid
        self.uname = uname
        self.message = message
        self.time = time
    }
}
