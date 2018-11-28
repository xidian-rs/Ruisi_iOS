//
//  VoteData.swift
//  Ruisi
//
//  Created by yang on 2018/11/28.
//  Copyright © 2018 yang. All rights reserved.
//

import Foundation

public class VoteData {
    var action: String
    var options: [KeyValueData<String, String>]
    var maxSelect: Int
    
    init(action: String, options: [KeyValueData<String, String>], maxSelect: Int) {
        self.action = action
        self.options = options
        self.maxSelect = maxSelect
    }
    
}
