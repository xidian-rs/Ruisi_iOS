//
//  SearchViewController.swift
//  Ruisi
//
//  Created by yang on 2017/11/29.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 搜索页面
//1.先提交搜索 获得url
//2.再用url浏览结果
class SearchViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {
    
    var indicateView: UIActivityIndicatorView?
    var placeholderText = "请输入你要搜索的内容"
    var datas = [SearchData]()
    var nextPageUrl: String?
    
    private var tableViewWidth: CGFloat = 0
    private var currentSearchText: String?
    
    var searchController: UISearchController!
    var searchBar: UISearchBar!
    
    private var loading = false
    open var isLoading: Bool {
        get {
            return loading
        }
        set {
            loading = newValue
            if !loading {
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.endLoading(haveMore: nextPageUrl != nil)
                }
                
                indicateView?.stopAnimating()
            } else {
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.startLoading()
                }
                indicateView?.startAnimating()
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewWidth = self.tableView.frame.width
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        tableView.tableFooterView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        
        indicateView = UIActivityIndicatorView(style: .gray)
        indicateView?.hidesWhenStopped = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: indicateView!)
        
        initSearchController()
        
        loadForumhash()
    }
    
    func initSearchController() {
        searchController = UISearchController()
        searchController.searchResultsUpdater = self
        //是否添加半透明覆盖层
        searchController.dimsBackgroundDuringPresentation = false
        //是否隐藏导航栏
        //searchController.hidesNavigationBarDuringPresentation = false

        searchBar = searchController.searchBar
        searchBar.delegate = self
        searchBar.placeholder = "输入搜索的关键词"
        
        if #available(iOS 11.0, *) {
            self.navigationItem.searchController = searchController
            self.navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            self.tableView.tableHeaderView = searchBar
        }
        // 防止搜索内容跑到statusbar
        definesPresentationContext = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if #available(iOS 11.0, *) {
            self.navigationItem.hidesSearchBarWhenScrolling = true
        }
    }
    
    func loadForumhash() {
        HttpUtil.GET(url: Urls.searchUrl, params: nil) { (ok, res) in
            if let hash = Utils.getFormHash(from: res) {
                print("set new hash:\(hash)")
                Settings.formhash = hash
            }
        }
    }
    
    func loadData(url: String) {
        isLoading = true
        HttpUtil.GET(url: url, params: nil) { ok, res in
            var subDatas: [SearchData] = []
            if ok { //返回的数据是我们要的
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    // load fromHash
                    let exitNode = doc.xpath("/html/body/div[@class=\"footer\"]/div/a[2]").first
                    if let hash = Utils.getFormHash(from: exitNode?["href"]) {
                        print("formhash: \(hash)")
                        Settings.formhash = hash
                    }
                    //load subdata
                    subDatas = self.parseData(doc: doc)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                if subDatas.count > 0 {
                    let count = self.datas.count
                    self.datas.append(contentsOf: subDatas)
                    self.tableView.beginUpdates()
                    var indexs = [IndexPath]()
                    for i in 0..<subDatas.count {
                        indexs.append(IndexPath(row: count + i, section: 0))
                    }
                    self.tableView.insertRows(at: indexs, with: .automatic)
                    self.tableView.endUpdates()
                }
                
                self.isLoading = false
            })
        }
    }
    
    func parseData(doc: HTMLDocument) -> [SearchData] {
        var subDatas = [SearchData]()
        let resultsNodes = doc.xpath("/html/body/div[1]/ul/li")
        
        nextPageUrl = nil
        if let n = doc.css("a.nxt").first {
            nextPageUrl = n["href"]
        }
        
        for result in resultsNodes {
            let tid = Utils.getNum(from: result.xpath("a").first?["href"] ?? "0")
            if tid == nil || tid! <= 0 {
                continue
            }
            let title = result.xpath("a").first?.text ?? "标题"
            //print("tid: \(tid!) title: \(title)")
            let attrTitle: NSAttributedString
            if let searchText = currentSearchText?.trimmingCharacters(in: CharacterSet.whitespaces), let range = title.range(of: searchText) {
                let attrStr = NSMutableAttributedString(string: title)
                attrStr.addAttributes([NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): UIColor.systemRed],
                                      range: NSRange(range, in: title))
                attrTitle = attrStr
            }else {
                attrTitle = NSAttributedString(string: title)
            }
            
            let d = SearchData(tid: tid!, title: attrTitle)
            d.rowHeight = caculateRowHeight(width: self.tableViewWidth, text: d.title.string)
            subDatas.append(d)
        }
        
        return subDatas
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let titleLabel = cell.viewWithTag(1) as! UILabel
        titleLabel.attributedText = datas[indexPath.row].title
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let d = datas[indexPath.row]
        return d.rowHeight
    }
    
    func caculateRowHeight(width: CGFloat, text: String) -> CGFloat {
        let titleHeight = text.height(for: self.tableViewWidth - 32, font: UIFont.systemFont(ofSize: 16, weight: .medium))
        // 上间距(12) + 正文(计算) + 下间距(12)
        return 12 + titleHeight + 12
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if datas.count == 0 {//no data avaliable
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            label.text = placeholderText
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 20)
            if #available(iOS 13.0, *) {
                label.textColor = UIColor.placeholderText
            } else {
                label.textColor = UIColor.lightGray
            }
            label.sizeToFit()
            
            tableView.backgroundView = label;
            tableView.separatorStyle = .none;
            tableView.tableFooterView?.isHidden = true
            return 0
        } else {
            tableView.backgroundView = nil
            tableView.tableFooterView?.isHidden = false
            tableView.separatorStyle = .singleLine
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
            if nextPageUrl == nil {
                return
            }
            loadData(url: nextPageUrl!)
        }
    }
    
    // MARK: - Search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            currentSearchText = text
            self.searchBar.resignFirstResponder()
            datas = []
            tableView.reloadData()
            nextPageUrl = nil
            isLoading = true
            
            if text.count > 0 {
                HttpUtil.POST(url: Urls.searchUrl, params: ["searchsubmit": "yes", "srchtxt": text]) { (ok, res) in
                    if ok {
                        if let doc = try? HTML(html: res, encoding: .utf8) {
                            self.datas = self.parseData(doc: doc)
                            if self.datas.count > 0 {
                                self.placeholderText = "请输入你要搜索的内容"
                            } else {
                                var errText: String?
                                if let summeryNode = doc.xpath("/html/body/div[1]/h2").first {
                                    errText = summeryNode.text
                                } else if let errNode = doc.xpath("/html/body/div[1]/p[1]").first {
                                    errText = errNode.text
                                } else if res.contains("您当前的访问请求当中含有非法字符") {
                                    errText = "非法请求参数,被系统拒绝"
                                }
                                self.placeholderText = errText ?? "没有查询到\(text)的搜索结果"
                            }
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                self.isLoading = false
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            
            dest.tid = datas[index.row].tid
            dest.title = datas[index.row].title.string
        }
    }
    
}
