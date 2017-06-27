//
//  Utils.swift
//  Ruisi
//
//  Created by yang on 2017/6/27.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public class Utils {
   public static func getNum(from str: String) -> Int? {
        var digitals = [Character]()
        
        for i in str.characters {
            if digitals.count > 0 {
                if i >= "0" && i <= "9" {
                    digitals.append(i)
                }else {
                    return Int(String(digitals))
                }
            } else {
                if i >= "0" && i <= "9" {
                    digitals.append(i)
                }
            }
        }
        
        return Int(String(digitals))
    }

}
