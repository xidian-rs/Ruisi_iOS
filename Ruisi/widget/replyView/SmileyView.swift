//
//  SmileyView.swift
//  SmileyView
//
//  Created by yang on 2017/12/20.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class SmileyView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var smileyToolbar: SmileyToolbar!
    @IBOutlet weak var smileyCollection: UICollectionView!
    @IBOutlet weak var smileyPageControl: UIPageControl!
    
    public let pageSize = 20
    
    // 表情点击回调
    public var smileyClick: ((_ item: SmileyItem?) -> ())?
    
    class func smileyView() -> SmileyView {
        let nib = UINib(nibName: "SmileyView", bundle: nil)
        let v = nib.instantiate(withOwner: self, options: nil).first as! SmileyView
        return v
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        smileyPageControl.currentPageIndicatorTintColor = UIColor(white: 0.90, alpha: 1.0)
        smileyPageControl.pageIndicatorTintColor = UIColor(white: 0.97, alpha: 1.0)
        smileyPageControl.backgroundColor = UIColor(white: 0.99, alpha: 1.0)
        switchTab(section: 0, item: 0)
        
        smileyCollection.backgroundColor = UIColor(white: 0.99, alpha: 1.0)
        smileyCollection.register(SmileyCell.self, forCellWithReuseIdentifier: "cell")
        smileyToolbar.itemSelected = { [weak self] (btn,pos) in
            self?.smileyCollection.scrollToItem(at: IndexPath(item: 0, section: pos) , at: UICollectionViewScrollPosition.left, animated: true)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SmileyManager.shared.smileys[section].pageCount(size: pageSize)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return SmileyManager.shared.smileys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! SmileyCell
        cell.delegate = self
        let smileys = SmileyManager.shared.smileys[indexPath.section].getSmileys(page: indexPath.item, pageSize: cell.pageSize)
        cell.setSmileys(smileys: smileys)
        return cell
    }
    
    // 切换tab
    func switchTab(section: Int, item: Int) {
        smileyPageControl.numberOfPages = SmileyManager.shared.smileys[section].pageCount(size: pageSize)
        smileyPageControl.currentPage = item
        //print("section: \(section), item: \(item)")
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page =  Int((scrollView.contentOffset.x + bounds.width * 0.5) / bounds.width)
        let index = SmileyManager.shared.indexPathFor(page: page, pageSize: pageSize)
        smileyToolbar.selectItem(at: index.section)
    }
    
    var lastPage = 0
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page =  Int((scrollView.contentOffset.x + bounds.width * 0.5) / bounds.width)
        if page == lastPage { return }
        lastPage = page
        let index = SmileyManager.shared.indexPathFor(page: page, pageSize: pageSize)
        switchTab(section: index.section, item: index.item)
    }
}

extension SmileyView: SmileyCellDelegate {
    func smileyCellDidSelectAt(cell:UICollectionViewCell,item: SmileyItem?) {
        smileyClick?(item)
    }
}
