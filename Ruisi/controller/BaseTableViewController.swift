//
//  AbstractTableViewController.swift
//  Ruisi
//
//  Created by yang on 2017/11/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit
import Kanna

// 带下拉刷新 带占位符 带上拉加载更多的基类
class BaseTableViewController<T>: UITableViewController {
    
    func getUrl(page: Int) -> String {
        fatalError("要实现")
    }
    
    func parseData(pos: Int, doc: HTMLDocument) -> [T] {
        fatalError("要实现")
    }
    
    func prepareParseData(pos: Int, res: String) -> [T] {
        if let doc = try? HTML(html: res, encoding: .utf8) {
            // load fromHash
            let exitNode = doc.xpath("/html/body/div[@class=\"footer\"]/div/a[2]").first
            if let hash = Utils.getFormHash(from: exitNode?["href"]) {
                print("formhash: \(hash)")
                Settings.formhash = hash
            }
            return parseData(pos: pos, doc: doc)
        }
        
        return []
    }
    
    public var autoRowHeight = true
    public var tableViewWidth: CGFloat = 0
    
    private var showFooterPrivate = true
    var showFooter: Bool {
        get {
            return showFooterPrivate
        }
        set {
            if showFooterPrivate != newValue {
                showFooterPrivate = newValue
                if showFooterPrivate { //显示footer
                    if (tableView.tableFooterView as? LoadMoreView) != nil {
                        tableView.tableFooterView?.isHidden = false
                    } else {
                        tableView.tableFooterView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44))
                    }
                } else { //隐藏footer
                    tableView.tableFooterView?.isHidden = true
                }
            }
        }
    }
    var datas = [T]()
    var currentPage = 1
    var totalPage = Int.max
    var position = 0 //为了hotnew而准备的
    var rsRefreshControl: RSRefreshControl?
    
    public var showRefreshControl = false {
        didSet {
            if showRefreshControl && rsRefreshControl == nil {
                print("add refresh control")
                rsRefreshControl = RSRefreshControl()
                rsRefreshControl?.addTarget(self, action: #selector(reloadData), for: .valueChanged)
                self.tableView.addSubview(rsRefreshControl!)
            } else if !showRefreshControl && rsRefreshControl != nil{
                rsRefreshControl?.removeFromSuperview()
                rsRefreshControl = nil
            }
        }
    }
    
    //到达最后一页是否接着加载
    var shouldLoadMoreOnLastPage = false
    
    private var loading = false
    open var isLoading: Bool {
        get {
            return loading
        }
        set {
            loading = newValue
            if !loading {
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.endLoading(haveMore: currentPage < totalPage)
                }
            } else {
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.startLoading()
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewWidth = self.tableView.frame.width
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        if autoRowHeight {
            // FIXME 自动行高会导致加载更多动画异常，暂时关闭自动行高
            self.tableView.estimatedRowHeight = 80
            self.tableView.rowHeight = UITableViewAutomaticDimension
        }
        
        if showFooter {
            showFooterPrivate = false
            showFooter = true
        }
        
        if showRefreshControl {
            rsRefreshControl?.beginRefreshing()
        }
        loadData()
    }
    
    @objc func reloadData() {
        print("下拉刷新'")
        currentPage = 1
        totalPage = Int.max
        
        loadData(position)
    }
    
    func loadData(_ pos: Int = 0) {
        isLoading = true
        HttpUtil.GET(url: getUrl(page: currentPage), params: nil) { [weak self] ok, res in
            guard let this = self else { return }
            guard pos == this.position else { return }
            var subDatas: [T] = []
            if ok {
                subDatas = this.prepareParseData(pos: pos, res: res)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
                this.rsRefreshControl?.endRefreshing(message: ok ? "刷新成功...":"刷新失败...")
                this.isLoading = false
                
                if !ok && this.datas.count == 0 {
                    //第一页加载失败
                    let alert = UIAlertController(title: "加载失败", message: res, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                    alert.addAction(UIAlertAction(title: "重新加载", style: .default, handler: { (ac) in
                        this.rsRefreshControl?.beginRefreshing()
                        this.loadData(pos)
                    }))
                    this.present(alert, animated: true, completion: nil)
                } else if subDatas.count > 0 {
                    if this.currentPage == 1 {
                        this.datas = subDatas
                        this.tableView.reloadData()
                    } else {
                        var indexs = [IndexPath]()
                        for i in 0..<subDatas.count {
                            indexs.append(IndexPath(row: this.datas.count + i, section: 0))
                        }
                        this.datas.append(contentsOf: subDatas)
                        print("here :\(subDatas.count)")
                        this.tableView.beginUpdates()
                        this.tableView.insertRows(at: indexs, with: .automatic)
                        this.tableView.endUpdates()
                    }
                } else {
                    //第一次没有加载到数据
                    if this.currentPage == 1 {
                        this.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if datas.count == 0 {
            tableView.tableFooterView?.isHidden = true
            return 0
        } else {
            if showFooter {
                tableView.tableFooterView?.isHidden = false
            }
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = datas.count - 1
        if !isLoading && indexPath.row == lastElement {
            if currentPage >= totalPage && !shouldLoadMoreOnLastPage {
                return
            } // TODO 最后一页是否还要继续刷新
            if currentPage < totalPage {
                currentPage += 1
            }
            print("load more next page is:\(currentPage) sum is:\(totalPage)")
            loadData(position)
        }
    }
    
}
