//
//  HtmlAttr.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

class HtmlAttr {
    static let colors: [String: Int] = [
        "aqua": 0x00FFFF,
        "black": 0x000000,
        "blue": 0x0000FF,
        "darkgrey": 0xA9A9A9,
        "fuchsia": 0xFF00FF,
        "gray": 0x808080,
        "grey": 0x808080,
        "green": 0x008000,
        "lightblue": 0xADD8E6,
        "lightgrey": 0xD3D3D3,
        "lime": 0x00FF00,
        "maroon": 0x800000,
        "navy": 0x000080,
        "olive": 0x808000,
        "orange": 0xA500,
        "purple": 0x800080,
        "red": 0xFF0000,
        "silver": 0xC0C0C0,
        "teal": 0x008080,
        "white": 0xFFFFFF,
        "yellow": 0xFFFF00,
        "sienna": 0xA0522D,
        "darkolivegreen": 0x556B2F,
        "darkgreen": 0x006400,
        "darkslateblue": 0x483D8B,
        "indigo": 0x4B0082,
        "darkslategray": 0x2F4F4F,
        "darkred": 0x8B0000,
        "darkorange": 0xFF8C00,
        "slategray": 0x708090,
        "dimgray": 0x696969,
        "sandybrown": 0xF4A460,
        "yellowgreen": 0xADFF2F,
        "seagreen": 0x2E8B57,
        "mediumturquoise": 0x48D1CC,
        "royalblue": 0x4169E1,
        "magenta": 0xFF00FF,
        "cyan": 0x00FFFF,
        "deepskyblue": 0x00BFFF,
        "darkorchid": 0x9932CC,
        "pink": 0xFFC0CB,
        "wheat": 0xF5DEB3,
        "lemonchiffon": 0xFFFACD,
        "palegreen": 0x98FB98,
        "paleturquoise": 0xAFEEEE,
        "plum": 0xDDA0DD]

    var src: String? //img
    var href: String? //a
    var color: UIColor? //font
    var bgColor: UIColor? //font
    var size: Int?
    var textAlign: NSTextAlignment?


    static func parserAttr(type: HtmlTag, src: String) -> HtmlAttr? {
        let attr: HtmlAttr = HtmlAttr()
        switch (type) {
        case .A:
            let start = src.range(of: "href")
            attr.href = getAttr(from: src, start: start?.upperBound)?
                    .replacingOccurrences(of: "&amp;", with: "&", options: .literal)
        case .IMG:
            let start = src.range(of: "src")
            attr.src = getAttr(from: src, start: start?.upperBound)?
                    .replacingOccurrences(of: "&amp;", with: "&", options: .literal)
        case .FONT:
            attr.color = getTextColor(from: src)
            attr.bgColor = getBgColor(from: src)
            attr.size = getTextSize(from: src)
        case .DIV: // div align="left"
            attr.textAlign = getAlign(from: src)
        default:
            break
        }

        return attr
    }

    //a="b" src="" href=""
    static func getAttr(from: String, start: String.Index?) -> String? {
        if let start = start {
            if let s = from.range(of: "\"", range: start..<from.endIndex) {
                if s.upperBound < from.endIndex, let e = from.range(of: "\"", range: s.upperBound..<from.endIndex) {
                    return String(from[s.upperBound..<e.lowerBound])
                }
            }
        }
        return nil
    }

    //color="red" " color:red "
    //attr css
    //color="#ff0000"
    static func getTextColor(from: String) -> UIColor? {
        if let s = from.range(of: "color") {
            if s.lowerBound > from.startIndex && (from[from.index(before: s.lowerBound)] == "-" ||
                    from[from.index(before: s.lowerBound)] == "g") {
                //排除background-color bgcolor
                return nil
            }

            if let color = getAttr(from: from, start: s.upperBound) {
                if color.first == "#" {
                    return Utils.getHtmlColor(from: color)
                } else {
                    return Utils.parseColor(int: colors[color.lowercased()])
                }
            }
        }
        return nil
    }


    //size="5"
    static func getTextSize(from: String) -> Int? {
        if let s = from.range(of: "size") {
            if let size = getAttr(from: from, start: s.upperBound) {
                return Int(size)
            }
        }
        return nil
    }

    //style="background-color:DarkRed"
    static func getBgColor(from: String) -> UIColor? {
        if let s = from.range(of: "background-color:") {
            if let end = from.range(of: "\"", range: s.upperBound..<from.endIndex) {
                let color = from[s.upperBound..<end.lowerBound]
                print("bgcolor \(color)")
                if color.first == "#" {
                    return Utils.getHtmlColor(from: String(color))
                } else {
                    return Utils.parseColor(int: colors[color.lowercased()])
                }
            }

        }
        return nil
    }

    //只有块状标签才有意义
    //left right center
    //或者文字布局 align="center"
    static func getAlign(from: String) -> NSTextAlignment? {
        if let s = from.range(of: "align") {
            if let f = getAttr(from: from, start: s.upperBound) {
                switch f {
                case "right":
                    return .right
                case "center":
                    return .center
                case "left":
                    return .left
                default:
                    return nil
                }
            }
        }
        return nil
    }
}

