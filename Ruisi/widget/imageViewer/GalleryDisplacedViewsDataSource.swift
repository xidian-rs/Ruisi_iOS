//
//  GalleryDisplacedViewsDataSource.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 01/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit

public protocol DisplaceableView {
    var image: UIImage? { get }
    var bounds: CGRect { get }
    var center: CGPoint { get }
    var boundsCenter: CGPoint { get }
    var contentMode: UIView.ContentMode { get }
    var isHidden: Bool { get set }

    func convert(_ point: CGPoint, to view: UIView?) -> CGPoint
}

extension DisplaceableView {
    func imageView() -> UIImageView {
        let imageView = UIImageView(image: self.image)
        imageView.bounds = self.bounds
        imageView.center = self.center
        imageView.contentMode = self.contentMode
        return imageView
    }

    func frameInCoordinatesOfScreen() -> CGRect {
        return UIView().convert(self.bounds, to: UIScreen.main.coordinateSpace)
    }
}

// 提供动画开始的view
public protocol GalleryDisplacedViewsDataSource: AnyObject {
    // 展示评议动画的view
    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView?
}
