//
//  GalleryPagingDataSource.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 15/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit

final class GalleryPagingDataSource: NSObject, UIPageViewControllerDataSource {
    
    weak var itemControllerDelegate: ItemControllerDelegate?
    fileprivate weak var itemsDataSource:          GalleryItemsDataSource?
    fileprivate weak var displacedViewsDataSource: GalleryDisplacedViewsDataSource?
    
    fileprivate let configuration: GalleryConfiguration
    fileprivate var pagingMode = GalleryPagingMode.standard
    fileprivate var itemCount: Int { return itemsDataSource?.itemCount() ?? 0 }
    
    init(itemsDataSource: GalleryItemsDataSource, displacedViewsDataSource: GalleryDisplacedViewsDataSource?, configuration: GalleryConfiguration) {
        
        self.itemsDataSource = itemsDataSource
        self.displacedViewsDataSource = displacedViewsDataSource
        self.configuration = configuration
        
        if itemsDataSource.itemCount() > 1 { // Potential carousel mode present in configuration only makes sense for more than 1 item
            
            for item in configuration {
                
                switch item {
                    
                case .pagingMode(let mode): pagingMode = mode
                default: break
                }
            }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let currentController = viewController as? ItemController else { return nil }
        let previousIndex = (currentController.index == 0) ? itemCount - 1 : currentController.index - 1
        
        switch pagingMode {
            
        case .standard:
            return (currentController.index > 0) ? self.createItemController(previousIndex) : nil
            
        case .carousel:
            return self.createItemController(previousIndex)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let currentController = viewController as? ItemController  else { return nil }
        let nextIndex = (currentController.index == itemCount - 1) ? 0 : currentController.index + 1
        
        switch pagingMode {
            
        case .standard:
            return (currentController.index < itemCount - 1) ? self.createItemController(nextIndex) : nil
            
        case .carousel:
            return self.createItemController(nextIndex)
        }
    }
    
    func createItemController(_ itemIndex: Int, isInitial: Bool = false) -> UIViewController {
        
        guard let itemsDataSource = itemsDataSource else { return UIViewController() }
        
        let imageController = ImageViewController(index: itemIndex, itemCount: itemsDataSource.itemCount(), fetchImageBlock: itemsDataSource.provideGalleryItem(itemIndex), configuration: configuration, isInitialController: isInitial)
        imageController.delegate = itemControllerDelegate
        imageController.displacedViewsDataSource = displacedViewsDataSource
        
        return imageController
        
        
    }
}
