//
//  RSRefreshStata.swift
//  Ruisi
//
//  Created by yang on 2017/12/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

enum RSRefreshState {
    // 没有拉到临界点 放手就什么都不做
    case normal
    // 正在刷新
    case refreshing
    // 已经超过临界点  放手就刷新
    case dragging
    // 刷新结果一段时间后恢复normal
    case endding(title: String?)
}
