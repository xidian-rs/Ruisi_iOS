//
//  UploadImageItem.swift
//  Ruisi
//
//  Created by yang on 2017/12/17.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

public enum UploadState {
    case uploading(progress: Int)
    case success
    case failed
}

public struct UploadImageItem {

    public var aid: String?
    public var name: String?
    public var imageData: Data
    public var state: UploadState = .uploading(progress: 0)
    public var errmessage: String?

    init(aid: String? = nil, name: String?, imageData: Data, errmessage: String? = nil) {
        self.aid = aid
        self.name = name
        self.imageData = imageData
        self.errmessage = errmessage
    }
}
