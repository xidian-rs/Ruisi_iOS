//
//  HtmlTag.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

enum HtmlTag: Int {
    case UNKNOWN = -1
    /**
     * 内联标签
     */
    case FONT//不赞同字体color face size
    case TT//等宽的文本效果
    case I//斜体
    case CITE//引用斜体
    case DFN//定义斜体
    case U//下划线
    case BIG
    case SMALL
    case EM//强调的内容斜体
    case STRONG//语气更强的强调
    case B//加粗
    case KBD//定义键盘文本
    case MARK//突出显示部分文本
    case A //href
    //img 标签比较特殊 当为
    case IMG //src
    case BR
    case SUB
    case SUP
    case INS//下划线
    case DEL//删除线
    case S//不赞同删除线
    case STRIKE//不赞同删除线DEL替代
    case SPAN
    case Q//引用
    case CODE//代码
    case TD // ?? 应该不算 他是inline-block
    
    /**
     * 块标签
     */
    case HEADER = 50
    case FOOTER
    case DIV
    
    case P
    case UL
    case OL
    case LI
    
    case H1
    case H2
    case H3
    case H4
    case H5
    case H6
    
    case PRE
    case BLOCKQUOTE
    case HR
    
    case TABLE
    case CAPTION
    case THEAD
    case TFOOT
    case TBODY
    case TR
    case TH
    
    case VEDIO //src
    case AUDIO //src
    
    func isBlock() -> Bool {
        return self.rawValue >= 50
    }
    
}
