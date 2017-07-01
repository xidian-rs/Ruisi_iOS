//
//  HtmlParser.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

class HtmlParser {
    private let MAX_TAG_LEN = 16
    private let MAX_ATTR_LEN = 256
    private var src: String
    private var buf: [Character]
    private var stack: [HtmlNode]
    private var readItem: Character?
    private var lastRead: Character?
    private var currentPos: String.Index
    private var delegate: HtmlParserDelegate
    private var preLevel: Int = 0

    init(src: String, delegate: HtmlParserDelegate) {
        self.src = src
        self.stack = [HtmlNode]()
        currentPos = src.startIndex
        self.delegate = delegate
        self.buf = [Character]()
        self.readItem = nil
        self.lastRead = nil
    }

    // 解析入口函数
    func parse() {
        delegate.start()
        read()
        while let r = readItem {
            switch r {
            case "<": //tags
                read()
                if let rr = readItem {
                    switch rr {
                    case "/": //end tag
                        parseEndTag()
                    case "!":
                        read()
                        if readItem == "-" { // <!--
                            read()
                            if readItem == "-" {
                                parseComment()
                            } else if readItem != ">" {
                                skip()
                            }
                        } else {
                            skip()
                        }
                    case "?":
                        skip()
                    default:
                        parseStartTag()
                    }
                } else {
                    return
                }
            case ">":
                //end tag
                read()
                parseText()
            default:
                if lastRead == nil || lastRead == ">" {
                    parseText()
                } else {
                    read()
                }
            }
        }
    }

    //解析开始标签<a> <img /> <x a="b" c="d" e>
    //单标签只有开始
    func parseStartTag() {
        if let r = readItem, (r < "a" || r > "z") && (r < "A" || r > "Z") {
            //不合法的开始标签
            skip()
            return
        }

        buf.removeAll()
        //read name
        repeat {
            if readItem! >= "A" && readItem! <= "Z" {
                // 大写转小写
                readItem! = String(readItem!).lowercased().characters.first!
            }
            buf.append(readItem!)
            read()
        } while readItem != nil && buf.count < MAX_TAG_LEN &&
                ((readItem! >= "a" && readItem! <= "z") || (readItem! >= "A" && readItem! <= "Z")
                        || (readItem! >= "0" && readItem! <= "9"))

        let name = String(buf)
        let type = getTagTpye()
        buf.removeAll()

        // <img />
        if readItem == "/" {
            //单标签
            read()
        }

        //<a href = "" >
        if readItem != ">" {
            if readItem == " " || readItem == "\n" {
                readNoSpcBr()
            }

            if readItem == "/" {
                read()
            }

            if readItem != ">" {
                parseAttr()
            }
        }

        //说明attr长度大于等于5为有效attr
        var attr: HtmlAttr? = nil
        if buf.count >= 5 {
            attr = HtmlAttr.parserAttr(type: type, src: String(buf))
        }

        let node = HtmlNode(type: type, name: name, attr: attr)
        pushNode(node)
        delegate.startNode(node: node)
    }

    //解析结束标签</xxx  > </xxx> </xxx\n  >
    func parseEndTag() {
        buf.removeAll()
        readNoSpcBr()
        while readItem != nil && readItem != ">" {
            if (buf.count >= MAX_TAG_LEN) {
                //不可能出现太长的tag
                skip()
                break
            }
                
            if readItem == " " || readItem == "\n" {
                skip()
                break
            } else {
                buf.append(readItem!)
            }
            read()
        }
        
        let name = String(buf)
        let type = getTagTpye()
        buf.removeAll()
        if type == .PRE && preLevel > 0 {
            preLevel -= 1
        }
        popNode(type: type, name: name)
        delegate.endNode(type: type, name: name)
    }

    //解析属性值
    func parseAttr() {
        buf.removeAll()
        repeat {
            buf.append(readItem!)
            read()
        } while readItem != nil && readItem != ">" && buf.count < MAX_ATTR_LEN

        if !buf.isEmpty && buf.last! == "/" {
            _ = buf.popLast()
        }

        if readItem != ">" {
            skip()
        }
    }

    //解析文字
    //处理转义
    //&amp; "&"
    //&apos;  "'"
    //&gt; ">"
    //&lt; "<"
    //&quot; "\"
    //&nbsp; ' '
    func parseText() {
        buf.removeAll()
        
        while readItem != nil && readItem != "<" && readItem != ">" {
            if preLevel > 0 && buf.count > 0 {//pre 标签 原封不动push
                buf.append(readItem!)
            } else {
                //转义
                if (readItem == "&") {//&nbsp;
                    read()
                    if readItem == "n" {
                        read()
                        if readItem == "b" {
                            read()
                            if readItem == "s" {
                                read()
                                if readItem == "p" {
                                    read()
                                    if readItem == ";" {
                                        buf.append(" ");
                                        //&nbsp;
                                        read()
                                        continue;
                                        //强制空格
                                    } else {
                                        buf.append("&")
                                        buf.append("n")
                                        buf.append("b")
                                        buf.append("s")
                                        buf.append("p")
                                    }
                                } else {
                                    buf.append("&")
                                    buf.append("n")
                                    buf.append("b")
                                    buf.append("s")
                                }
                            } else {
                                buf.append("&")
                                buf.append("n")
                                buf.append("b")
                            }
                        } else {
                            buf.append("&")
                            buf.append("n")
                        }
                    } else if readItem == "a" { //&amp; &apos;
                        read()
                        if readItem == "m" {//&amp;
                            read()
                            if readItem == "p" {//&amp;
                                read()
                                if readItem == ";" {//&amp;
                                    buf.append("&")
                                    //&nbsp;
                                    read()
                                    continue
                                } else {
                                    buf.append("&")
                                    buf.append("a")
                                    buf.append("m")
                                    buf.append("p")
                                }
                            } else {
                                buf.append("&")
                                buf.append("a")
                                buf.append("m")
                            }
                        } else if readItem == "p" {//&apos;
                            read()
                            if readItem == "o" {//&apos;
                                read()
                                if readItem == "s" {//&apos;
                                    read()
                                    if readItem == ";" {
                                        buf.append("\'")
                                        //&apos;
                                        read()
                                        continue
                                    } else {
                                        buf.append("&")
                                        buf.append("a")
                                        buf.append("p")
                                        buf.append("o")
                                        buf.append("s")
                                    }
                                } else {
                                    buf.append("&")
                                    buf.append("a")
                                    buf.append("p")
                                    buf.append("o")
                                }
                            } else {
                                buf.append("&")
                                buf.append("a")
                                buf.append("p")
                            }
                        } else {
                            buf.append("&")
                            buf.append("a")
                        }
                    } else if readItem == "g" {//&gt;
                        read()
                        if readItem == "t" {
                            read()
                            if readItem == ";" {
                                buf.append(">")
                                //&gt;
                                read()
                                continue
                            } else {
                                buf.append("&")
                                buf.append("g")
                                buf.append("t")
                            }
                        } else {
                            buf.append("&")
                            buf.append("g")
                        }
                    } else if readItem == "l" {//&lt;
                        read()
                        if readItem == "t" {
                            read()
                            if readItem == ";" {
                                buf.append("<")
                                //&lt;
                                read()
                                continue
                            } else {
                                buf.append("&")
                                buf.append("l")
                                buf.append("t")
                            }
                        } else {
                            buf.append("&")
                            buf.append("l")
                        }
                    } else if readItem == "q" {//&quot;
                        read();
                        if readItem == "u" {
                            read();
                            if readItem == "o" {
                                read();
                                if readItem == "t" {
                                    read();
                                    if readItem == ";" {
                                        buf.append("\\")
                                        //&nbsp;
                                        read()
                                        continue
                                    } else {
                                        buf.append("&")
                                        buf.append("q")
                                        buf.append("u")
                                        buf.append("o")
                                        buf.append("t")
                                    }
                                } else {
                                    buf.append("&")
                                    buf.append("q")
                                    buf.append("u")
                                    buf.append("o")
                                }
                            } else {
                                buf.append("&")
                                buf.append("q")
                                buf.append("u")
                            }
                        } else {
                            buf.append("&")
                            buf.append("q")
                        }
                    } else {
                        buf.append("&")
                    }
                }

                if readItem == " " || readItem == "\n" {
                    if !buf.isEmpty && buf.last != " " {
                        readItem = " "
                        buf.append(" ")
                    }
                } else if let r = readItem {
                    buf.append(r)
                }
            }
            read()
        }

        //不是空
        if !buf.isEmpty {
            delegate.characters(text: String(buf))
        }
    }

    //解析注释
    func parseComment() {
        while readItem != nil {
            read()
            read()
            if let r = readItem, let p = lastRead, r == "-" && p == "-" {
                read()
                if readItem == nil || readItem == ">" {
                    break
                }
            }
        }
    }

    //处理解析完成
    private func end() {
        while stack.count > 0 {
            let node = stack.popLast()
            delegate.endNode(type: node!.type, name: node!.name)
        }

        readItem = nil
        delegate.end()
    }

    //读取一个字符
    func read() {
        lastRead = readItem
        if currentPos < src.endIndex {
            readItem = src[currentPos]
            currentPos = src.index(after: currentPos)
        } else {
            readItem = nil
            return end()
        }
        
        //we want \r\n
        if readItem == "\r" {
            read()
        }
    }

    //忽略读入的空格和回车
    func readNoSpcBr() {
        read()
        while readItem == " " || readItem == "\n" {
            read()
        }
    }

    //skip to next > or EOF
    func skip() {
        if let r =  src.range(of: ">", range: currentPos ..< src.endIndex) {
            currentPos = r.upperBound
        } else {
            readItem = nil
        }
    }

    //压栈node到stack 更新节点属性
    func pushNode(_ node: HtmlNode) {
        //单标签不压栈,且属性也不继承
        if node.type == .IMG || node.type == .BR || node.type == .HR {
            return
        }

        let parentAttr = stack.last?.attr
        if let p = parentAttr {
            if node.attr == nil {
                node.attr = p
            } else {
                //字体颜色继承
                if node.attr?.color == nil {
                    node.attr?.color = p.color
                }
            }
        }

        //压栈
        stack.append(node)
        if node.type == .PRE {
            preLevel += 1
        }
    }

    //出栈 如果站定相等直接out else 一直出
    func popNode(type: HtmlTag, name: String) {
        //这些节点不在栈
        if type == .IMG
                   || type == .BR
                   || type == .HR {
            return
        }

        let node: HtmlNode? = stack.last
        if !stack.isEmpty, let n = node {
            //栈顶元素相同出栈
            if n.type == type && n.name == name {
                _ = stack.popLast()
            } else {//不相同 是出还是不出???
                var pos = stack.count
                for i in stride(from: stack.count - 1, to: -1, by: -1) {
                    if (stack[i].type == type && stack[i].name == name) {
                        pos = i
                        break
                    }
                }
                //栈里有 一直出栈
                if pos < stack.count {
                    stack.removeLast(stack.count - pos)
                }
            }
        }
    }

    //获得htmlTag类型
    func getTagTpye() -> HtmlTag {
        switch buf.count {
        case 1:
            switch buf[0] {
            case "a":
                return .A
            case "b":
                return .B
            case "i":
                return .I
            case "p":
                return .P
            case "q":
                return .Q
            case "s":
                return .S
            case "u":
                return .U
            default:
                return .UNKNOWN
            }
        case 2:
            switch buf[0] {
            case "b":
                if buf[1] == "r" {
                    return .BR
                }
            case "e":
                if buf[1] == "r" {
                    return .EM
                }
            case "h":
                switch buf[1] {
                case "1":
                    return .H1
                case "2":
                    return .H2
                case "3":
                    return .H3
                case "4":
                    return .H4
                case "5":
                    return .H5
                case "6":
                    return .H6
                case "r":
                    return .HR
                default:
                    return .UNKNOWN
                }
            case "l":
                if buf[1] == "i" {
                    return .LI
                }
                break
            case "o":
                if buf[1] == "l" {
                    return .OL
                }
            case "t":
                if buf[1] == "d" {
                    return .TD
                } else if buf[1] == "h" {
                    return .TH
                } else if buf[1] == "r" {
                    return .TR
                } else if buf[1] == "t" {
                    return .TT
                }
            case "u":
                if buf[1] == "l" {
                    return .UL
                }
            default:
                return .UNKNOWN
            }
        case 3:
            switch buf[0] {
            case "b":
                if buf[1] == "i" && buf[2] == "g" {
                    return .BIG
                }
            case "d":
                if buf[1] == "e" && buf[2] == "l" {
                    return .DEL
                } else if buf[1] == "f" && buf[2] == "n" {
                    return .DFN
                } else if buf[1] == "i" && buf[2] == "v" {
                    return .DIV
                }
            case "i":
                if buf[1] == "m" && buf[2] == "g" {
                    return .IMG
                } else if buf[1] == "n" && buf[2] == "s" {
                    return .INS
                }
            case "k":
                if buf[1] == "b" && buf[2] == "d" {
                    return .KBD
                }
            case "p":
                if buf[1] == "r" {
                    if buf[2] == "e" {
                        return .PRE
                    }
                }
            case "s":
                if buf[1] == "u" {
                    if buf[2] == "b" {
                        return .SUB
                    } else if buf[2] == "p" {
                        return .SUP
                    }
                }
            default:
                return .UNKNOWN
            }
        case 4:
            switch buf[0] {
            case "c":
                if buf[1] == "i" && buf[2] == "t" && buf[3] == "e" {
                    return .CITE
                } else if buf[1] == "o" && buf[2] == "d" && buf[3] == "e" {
                    return .CODE
                }
            case "f":
                if buf[1] == "o" && buf[2] == "n" && buf[3] == "t" {
                    return .FONT
                }
            case "s":
                if buf[1] == "p" && buf[2] == "a" && buf[3] == "n" {
                    return .SPAN
                }
            case "m":
                if buf[1] == "a" && buf[2] == "r" && buf[3] == "k" {
                    return .MARK
                }
            default:
                return .UNKNOWN
            }
        case 5:
            switch buf[0] {
            case "s":
                if equalTag(1, "mall") {
                    return .SMALL
                }
                break;
            case "t":
                if equalTag(1, "able") {
                    return .TABLE
                } else if equalTag(1, "body") {
                    return .TBODY
                } else if equalTag(1, "head") {
                    return .THEAD
                } else if equalTag(1, "foot") {
                    return .TFOOT
                }
            case "a":
                if equalTag(1, "udio") {
                    return .AUDIO
                }
            case "v":
                if equalTag(1, "edio") {
                    return .VEDIO
                }
            default:
                return .UNKNOWN
            }
        case 6:
            if equalTag(0, "str") {
                if buf[3] == "o" && buf[4] == "n" && buf[5] == "g" {
                    return .STRONG
                } else if buf[3] == "i" && buf[4] == "k" && buf[5] == "e" {
                    return .STRIKE
                }
            } else if buf[4] == "e" && buf[5] == "f" {
                if buf[0] == "h" && buf[1] == "e" && buf[2] == "a" && buf[3] == "d" {
                    return .HEADER
                } else if (buf[0] == "f" && buf[1] == "o" && buf[2] == "o" && buf[3] == "t") {
                    return .FOOTER
                }
            }
        case 7:
            if equalTag(0, "caption") {
                return .CAPTION
            }
        case 10:
            if equalTag(0, "blockquote") {
                return .BLOCKQUOTE
            }
        default:
            return .UNKNOWN
        }


        return .UNKNOWN
    }

    //判断tag是否相等
    func equalTag(_ start: Int, _ des: String) -> Bool {
        if buf.count - start < des.characters.count {
            return false
        }

        var i = start
        for c in des.characters {
            if buf[i] != c {
                return false
            }
            i += 1
        }

        return true
    }
}
