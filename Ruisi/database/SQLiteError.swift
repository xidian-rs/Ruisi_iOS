//
//  SQLiteError.swift
//  Ruisi
//
//  Created by yang on 2017/12/16.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public enum SQLiteError: Error {
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
}
