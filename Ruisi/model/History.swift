//
//  History.swift
//  Ruisi
//
//  Created by yang on 2017/11/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import CoreData

@objc(History)
class History : NSManagedObject{
    @nonobjc public class func fetchRequest() -> NSFetchRequest<History> {
        return NSFetchRequest<History>(entityName: "History")
    }
    @NSManaged public var tid: String
    @NSManaged public var title: String
    @NSManaged public var author: String?
    @NSManaged public var created: String?
    @NSManaged public var time: Int64
}
