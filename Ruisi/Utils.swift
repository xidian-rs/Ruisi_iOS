//
//  Utils.swift
//  Ruisi
//
//  Created by yang on 2017/6/27.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

// 工具类
public class Utils {
    public static func getNum(from str: String) -> Int? {
        var digital = [Character]()

        for i in str {
            if digital.count > 0 {
                if i >= "0" && i <= "9" {
                    digital.append(i)
                } else {
                    return Int(String(digital))
                }
            } else {
                if i >= "0" && i <= "9" {
                    digital.append(i)
                }
            }
        }

        return Int(String(digital))
    }

    public static func getNum(prefix: String, from str: String) -> Int? {
        var digital = [Character]()
        if let start = str.range(of: prefix)?.upperBound {
            for i in str[start...] {
                if digital.count > 0 {
                    if i >= "0" && i <= "9" {
                        digital.append(i)
                    } else {
                        return Int(String(digital))
                    }
                } else {
                    if i >= "0" && i <= "9" {
                        digital.append(i)
                    }
                }
            }

            return Int(String(digital))
        } else {
            return nil
        }
    }

    public static func getFormHash(from: String?) -> String? {
        if let s = from {
            let results = matchingStrings(regex: "formhash=(.{6,8})&?", from: s)
            if results.count > 0 {
                return results[0][1]
            }
        }

        return nil
    }

    public static func matchingStrings(regex: String, from: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else {
            return []
        }
        let nsString = from as NSString
        let results = regex.matches(in: from, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                        ? nsString.substring(with: result.range(at: $0))
                        : ""
            }
        }
    }

    // style="color: #EE1B2E;" 在这之中提取颜色
    // color="#8b0000"
    public static func getHtmlColor(from str: String?) -> UIColor? {
        if let ss = str {
            if let s = ss.range(of: "#")?.upperBound {
                if let e = ss.index(s, offsetBy: 6, limitedBy: ss.endIndex) {
                    if let i = Int(ss[s..<e], radix: 16) {
                        return parseColor(int: i)
                    }
                }
            }
        }
        return nil
    }
    
    // rgb(255, 255, 255)
    public static func getRgbColor(from str: String?) -> UIColor? {
        if let text = str {
            do {
                let regex = try NSRegularExpression(pattern: "[0-9]+")
                let results = regex.matches(in: text,
                                            range: NSRange(text.startIndex..., in: text))
                let nums = results.map {
                    Int(text[Range($0.range, in: text)!])
                }
                if nums.count == 3 {
                    if nums[0] == 255 && nums[1] == 255 && nums[2] == 255 {
                        return UIColor.white
                    } else if nums[0] == 0 && nums[1] == 0 && nums[2] == 0 {
                        return UIColor.black
                    }
                    return UIColor(red: CGFloat(nums[0]!) / 255, green: CGFloat(nums[1]!) / 255, blue: CGFloat(nums[2]!) / 255, alpha: 1)
                }
                return nil
            } catch let error {
                print("invalid regex: \(error.localizedDescription)")
                return nil
            }
        }
        return nil
    }

    // 16精致颜色转UIColor
    public static func parseColor(int: Int?) -> UIColor? {
        if let i = int {
            return UIColor(red: CGFloat((i >> 16) & 0xFF) / 255.0,
                    green: CGFloat((i >> 8) & 0xFF) / 255.0,
                    blue: CGFloat(i & 0xFF) / 255.0, alpha: 1)
        }

        return nil
    }

    // 根据用户当前积分计算出用户等级
    public static func getLevel(point: Int) -> String {
        if point >= 0 && point < 100 {
            return "西电托儿所"
        } else if point < 200 {
            return " 西电幼儿园"
        } else if point < 500 {
            return " 西电附小"
        } else if point < 1000 {
            return " 西电附中"
        } else if point < 2000 {
            return " 西电大一"
        } else if point < 2500 {
            return " 西电大二"
        } else if point < 3000 {
            return " 西电大三"
        } else if point < 3500 {
            return " 西电大四"
        } else if point < 6000 {
            return " 西电研一"
        } else if point < 10000 {
            return " 西电研二"
        } else if point < 14000 {
            return " 西电研三"
        } else if point < 20000 {
            return " 西电博一"
        } else if point < 25000 {
            return " 西电博二"
        } else if point < 30000 {
            return " 西电博三"
        } else if point < 35000 {
            return " 西电博四"
        } else if point < 40000 {
            return " 西电博五"
        } else if (point >= 40000 && point < 100000) {
            return " 西电博士后"
        } else {
            return "新手上路"
        }
    }

    //获得到下一等级的积分
    public static func getNextLevel(point: Int) -> Int {
        if point >= 0 && point < 100 {
            return 100
        } else if point < 200 {
            return 200
        } else if point < 500 {
            return 500
        } else if point < 1000 {
            return 1000
        } else if point < 2000 {
            return 2000
        } else if point < 2500 {
            return 2500
        } else if point < 3000 {
            return 3000
        } else if point < 3500 {
            return 3500
        } else if point < 6000 {
            return 6000
        } else if point < 10000 {
            return 10000
        } else if point < 14000 {
            return 14000
        } else if point < 20000 {
            return 20000
        } else if point < 25000 {
            return 25000
        } else if point < 30000 {
            return 30000
        } else if point < 35000 {
            return 35000
        } else if point < 40000 {
            return 40000
        } else if point >= 40000 {
            return 60000
        } else {
            return 100
        }
    }

    // 获得等级进度
    public static func getLevelProgress(_ point1: Int) -> Float {
        let point = Float(point1)
        if point >= 0 && point < 100 {
            return point / 100
        } else if point < 200 {
            return (point - 100) / 100.0
        } else if point < 500 {
            return (point - 200) / 300.0
        } else if point < 1000 {
            return (point - 500) / 500.0
        } else if point < 2000 {
            return (point - 1000) / 1000.0
        } else if point < 2500 {
            return (point - 2000) / 500.0
        } else if point < 3000 {
            return (point - 2500) / 500.0
        } else if point < 3500 {
            return (point - 3000) / 500.0
        } else if point < 6000 {
            return (point - 3500) / 2500.0
        } else if point < 10000 {
            return (point - 6000) / 4000.0
        } else if point < 14000 {
            return (point - 10000) / 4000.0
        } else if point < 20000 {
            return (point - 14000) / 6000.0
        } else if point < 25000 {
            return (point - 20000) / 15000.0
        } else if point < 30000 {
            return (point - 25000) / 5000.0
        } else if point < 35000 {
            return (point - 30000) / 5000.0
        } else if point < 40000 {
            return (point - 35000) / 5000.0
        } else if point >= 40000 {
            var b = (point - 40000) / 60000.0
            if b > 1 {
                b = 1
            }
            return b
        } else {
            return 0
        }
    }

    // 统一处理睿思请求失败获取失败内容
    /* eg:
     * <div class="jump_c">
     * <p>本版块禁止发帖</p>
     * <p><a class="grey" href="javascript:history.back();">[ 点击这里返回上一页 ]</a></p>
     * </div>
     * 提取：本版块禁止发帖
     */
    public class func getRuisiReqError(res: String?) -> String? {
        if let r = res, let jumpIndex = r.range(of: "class=\"jump_c\"")?.upperBound,
           let start = r.range(of: "<p>", range: jumpIndex..<r.endIndex)?.upperBound,
           let end = r.range(of: "</p>", range: jumpIndex..<r.endIndex)?.lowerBound {
            return String(r[start..<end])
        }

        return nil
    }
    
    //<dt id="messagetext">
    //<p>密码太弱，密码中必须包含数字<script type="text/javascript" reload="1">if(typeof errorhandle_=='function') {errorhandle_('密码太弱，密码中必须包含数字', {});}</script></p>
    public class func getRuisiReqAjaxError(res: String?) -> String? {
        if let r = res, let jumpIndex = r.range(of: "id=\"messagetext\"")?.upperBound,
            let start = r.range(of: "<p>", range: jumpIndex..<r.endIndex)?.upperBound,
            let end = r.range(of: "<script", range: jumpIndex..<r.endIndex)?.lowerBound {
            return String(r[start..<end])
        }
        
        return nil
    }

}
