//
//  SpotlightManager.swift
//  Ruisi
//
//  Created by yang on 2018/9/1.
//  Copyright © 2018年 yang. All rights reserved.
//

import Foundation


import UIKit
import CoreSpotlight
import MobileCoreServices

class SpotlightManager {
    
    // Singleton
    class var sharedInstance: SpotlightManager {
        struct Static {
            static let instance: SpotlightManager = SpotlightManager()
        }
        return Static.instance
    }
    
    func initSpotlight(his: [History]?) {
        if let hs = his, hs.count > 0 {
            // delete old
            var ids = [String]()
            for h in hs {
                ids.append("?group=\(SpotlightItemGroupType.post.rawValue)&tid=\(h.tid)")
            }
            
            deleteItemById(ids)
        }
    }
    
    func addPostSpotlight(tid: Int, title: String, author: String, created: String? = nil) {
        let item = getSearchableItem(["tid": tid], group: .post, title: title, description: "\(author)\(created==nil ? "" : "-\(created!)")", keywords: [title,author])
        setSearchableItems([item])
    }
    
    // Create and return CSSearchableItem from given parameters.
    func getSearchableItem(_ parameters : [String: Any] = [:], group: SpotlightItemGroupType, title: String, description: String, keywords : [String], phoneNumbers:[String]? = nil, location: String? = nil) -> CSSearchableItem {
        
        let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        
        searchableItemAttributeSet.title = title
        searchableItemAttributeSet.contentDescription = description
        searchableItemAttributeSet.keywords = keywords
        
        // Set thumbnail image.
        // searchableItemAttributeSet.thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.1)
        
        if let phoneNumbers = phoneNumbers {
            searchableItemAttributeSet.supportsPhoneCall = 1
            searchableItemAttributeSet.phoneNumbers = phoneNumbers
        }
        
        if let location = location {
            searchableItemAttributeSet.supportsNavigation = 1
            searchableItemAttributeSet.namedLocation = location
        }
        
        var queryString = "?group=\(group.rawValue)"
        
        // set parameters as querystring parameters
        parameters.forEach { (key,value) in
            queryString += "&\(key)=\(value)"
        }
        
        let searchableItem = CSSearchableItem(uniqueIdentifier: queryString, domainIdentifier: group.rawValue, attributeSet: searchableItemAttributeSet)
        
        return searchableItem
    }
    
    // Add or update specified list of CSSearchableItem.
    func setSearchableItems(_ searchableItems: [CSSearchableItem]){
        print("add apotloght \(searchableItems)")
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { (error) -> Void in
            if let error =  error {
                print(error.localizedDescription)
            }
        }
    }
    
    // Delete all searchable spotlight items.
    func deleteAllItems(_ completed: ((_ success: Bool)->())? = nil){
        CSSearchableIndex.default().deleteAllSearchableItems { (error) in
            let success = error == nil
            if let completed = completed {
                completed(success)
            }
        }
    }
    
    // Delete spotlight items by related group identifiers.
    func deleteItemsByGroup(_ groupNames: [String], completed: ((_ success: Bool)->())? = nil){
        
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: groupNames, completionHandler: { (error) in
            let success = error == nil
            if let completed = completed {
                completed(success)
            }
        })
    }
    
    // Delete spotlight list of spotlight items by related identifiers.
    func deleteItemById(_ identifiers: [String], completed: ((_ success: Bool)->())? = nil){
        print("delete spotlight ids:\(identifiers)")
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: identifiers, completionHandler: { (error) in
            let success = error == nil
            if let completed = completed {
                completed(success)
            }
        })
    }
}

enum SpotlightItemGroupType : String {
    case undefined = "Undefined",
    post = "Post", //帖子
    user = "User" //用户
}
