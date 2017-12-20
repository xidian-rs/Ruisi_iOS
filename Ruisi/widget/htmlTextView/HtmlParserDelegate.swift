//
//  HtmlParserDelegate.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

protocol HtmlParserDelegate {

    func start()

    func startNode(node: HtmlNode)

    func characters(text: String)

    func endNode(type: HtmlTag, name: String)

    func end()
}
