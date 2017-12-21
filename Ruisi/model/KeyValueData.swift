//
//  KeyValueData.swift
//  Ruisi
//
//  Created by yang on 2017/11/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

class KeyValueData<K, V> {

    var key: K
    var value: V

    init(key: K, value: V) {
        self.key = key
        self.value = value
    }
}
