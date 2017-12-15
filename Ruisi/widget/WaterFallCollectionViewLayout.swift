//
//  WaterFallCollectionViewLayout.swift
//  Ruisi
//
//  Created by yang on 2017/12/15.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class WaterFallCollectionViewLayout: UICollectionViewLayout {
    
    //列数目
    public var columnCount = 2
    //列边距
    public var columnSpacing:CGFloat = 10
    //行间距
    public var rowSpacing:CGFloat = 10
    public var inset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    public var delegate:WaterFallLayoutDelegate?
    
    private var maxHeightDic = [Int:CGFloat]()
    private var attributesArray = [UICollectionViewLayoutAttributes]()
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func prepare() {
        super.prepare()
        for i in 0..<columnCount {
            maxHeightDic[i] = self.inset.top
        }
        
        let count =  self.collectionView?.numberOfItems(inSection: 0)
        self.attributesArray.removeAll()
        for i in 0..<count! {
            let itemAttributes = layoutAttributesForItem(at: IndexPath(row: i, section: 0))
            attributesArray.append(itemAttributes!)
        }
    }
    
    //计算collectionView的contentSize
    override var collectionViewContentSize: CGSize {
        var maxHeight:CGFloat = 0
        for i in 0..<self.columnCount {
            if self.maxHeightDic[i]! > maxHeight {
                maxHeight = self.maxHeightDic[i]!
            }
        }
        
        return CGSize(width: self.collectionView!.frame.width,
                      height: maxHeight + self.inset.bottom)
    }
    

    
    //根据indexPath获取item的attributes
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attribute  = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        //获取collectionView的宽度
        let width:CGFloat = self.collectionView!.frame.width
        //item的宽度 = (collectionView的宽度 - 内边距与列间距) / 列数
        let itemWidth:CGFloat = (width - self.inset.left - self.inset.right - CGFloat(CGFloat(self.columnCount - 1) * self.columnSpacing)) / CGFloat(self.columnCount)
        //获取item的高度，由外界计算得到
        let itemHeight:CGFloat
        if let delegate = self.delegate {
            itemHeight = delegate.itemHeightFor(indexPath: indexPath, itemWidth: itemWidth)
        }else {
            itemHeight = itemWidth
        }
        
        //找出最短的那一列
        var minIndex = 0
        for i in 0..<self.columnCount {
            if self.maxHeightDic[i]! < self.maxHeightDic[minIndex]! {
                minIndex = i
            }
        }
        
        //根据最短列的列数计算item的x值
        let itemX = self.inset.left + (CGFloat(self.columnSpacing) + itemWidth) * CGFloat(minIndex)
        
        //item的y值 = 最短列的最大y值 + 行间距
        let itemY = CGFloat(self.maxHeightDic[minIndex]!) + self.rowSpacing
        //设置attributes的frame
        attribute.frame = CGRect(x: itemX, y: itemY, width: itemWidth, height: itemHeight)
        //更新字典中的最大y值
        self.maxHeightDic[minIndex] = self.maxHeightDic[minIndex]! + itemHeight + rowSpacing
        return attribute
    }
    
    //返回rect范围内item的attributes
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.attributesArray
    }
}

protocol WaterFallLayoutDelegate {
    func itemHeightFor(indexPath:IndexPath,itemWidth:CGFloat) -> CGFloat
}
