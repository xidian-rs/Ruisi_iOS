//
//  HotViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class HotViewController: PostsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // 切换热帖0 和 新帖1
    @IBAction func viewTypeChnage(_ sender: UISegmentedControl) {
        print(sender.selectedSegmentIndex)
        position = sender.selectedSegmentIndex
        currentPage = 1
        loadData(position)
        //tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    override var isLoading: Bool {
        get {
            if position == 0 {
                return isHotLoading
            }else{
                return isNewLoading
            }
        }
        
        set {
            if position == 0 {
                isHotLoading = newValue
            }else{
                isNewLoading = newValue
            }
            
            if !newValue {
                refreshView.endRefreshing()
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.endLoading()
                }
            }else {
                //refreshView.beginRefreshing()
                if currentPage > 1 { //上拉刷新
                    if let f = (tableView.tableFooterView as? LoadMoreView) {
                        f.startLoading()
                    }
                }
            }
        }
    }

    
    var isHotLoading = false
    var isNewLoading = false
    
    override func getUrl(page: Int) -> String {
        if position == 0 {
            return Urls.hotUrl + "&page=\(currentPage)"
        }else{
            return Urls.newUrl + "&page=\(currentPage)"
        }
    }
}
