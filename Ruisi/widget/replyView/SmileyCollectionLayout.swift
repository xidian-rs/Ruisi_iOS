//
//  SmileyCollectionLayout.swift
//  SmileyView
//
//  Created by yang on 2017/12/21.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class SmileyCollectionLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        scrollDirection = .horizontal
        guard let view = collectionView else { return }
        
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        itemSize = view.frame.size
    }

}
