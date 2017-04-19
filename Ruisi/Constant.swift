//
//  Constant.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

var isSchoolNet = false

let BASE_URL = "http://rs.xidian.edu.cn/"
let BASE_URL_ME = "http://bbs.rs.xidian.me/"

var baseUrl:String {
    get{
        return isSchoolNet ? BASE_URL : BASE_URL_ME
    }
}


let HOT_URL = baseUrl + "forum.php?mod=guide&view=hot&mobile=2"

let NEW_URL = baseUrl + "forum.php?mod=guide&view=new&mobile=2"//&page=1
