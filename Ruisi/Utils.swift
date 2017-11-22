//
//  Utils.swift
//  Ruisi
//
//  Created by yang on 2017/6/27.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

public class Utils {
    public static func getNum(from str: String) -> Int? {
        var digitals = [Character]()
        
        for i in str {
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
    
    // style="color: #EE1B2E;" 在这之中提取颜色
    // color="#8b0000"
    public static func getHtmlColor (from str: String?) -> UIColor? {
        if let ss = str {
            if let s = ss.range(of: "#")?.upperBound {
                if let e = ss.index(s, offsetBy: 6, limitedBy: ss.endIndex) {
                    if let i = Int(ss[s ..< e], radix: 16) {
                        return parseColor(int: i)
                    }
                }
            }
        }
        return nil
    }
    
    public static func parseColor(int: Int?) -> UIColor? {
        if let i = int {
            return UIColor(red: CGFloat((i >> 16) & 0xFF)/255.0,
                           green: CGFloat((i >> 8) & 0xFF)/255.0,
                           blue: CGFloat(i & 0xFF)/255.0, alpha: 1)
        }
        
        return nil
    }
}
