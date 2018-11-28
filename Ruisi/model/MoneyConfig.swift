//
//  MoneyConfig.swift
//  Ruisi
//
//  散金币设置
//  Created by yang on 2018/11/27.
//  Copyright © 2018 yang. All rights reserved.
//

import Foundation

public class MoneyConfig {
    var myMoney: Int?
    var totalCount: Int = 0
    var perMoney: Int
    var perTimes: Int // 1 2 3
    var chance: Int // 50% 80% 100%
    
    init(myMoney: Int?, totalCount: Int, perMoney: Int, perTimes: Int, chance: Int) {
        self.myMoney = myMoney
        self.totalCount = totalCount
        self.perMoney = perMoney
        self.perTimes = perTimes
        self.chance = chance
    }
}
