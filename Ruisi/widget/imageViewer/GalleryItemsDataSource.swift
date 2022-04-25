//
//  GalleryItemsDataSource.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 18/03/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit

public typealias FetchImageBlock = (@escaping (UIImage?) -> Void) -> Void

// 提供数据源的协议
public protocol GalleryItemsDataSource: AnyObject {
    func itemCount() -> Int
    func provideGalleryItem(_ index: Int) -> FetchImageBlock
}
