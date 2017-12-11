//
//  SearchViewController.swift
//  Ruisi
//
//  Created by yang on 2017/11/29.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

//1.先提交搜索 获得url
//2.再用url浏览结果
class SearchViewController: UITableViewController,UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var indicateView:UIActivityIndicatorView?
    var placeholderText = "请输入你要搜索的内容"
    var datas  = [KeyValueData<Int, String>]()
    var nextPageUrl :String?
    
    private var loading = false
    open var isLoading: Bool{
        get{
            return loading
        }
        set {
            loading = newValue
            if !loading {
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.endLoading(haveMore: nextPageUrl != nil)
                }
                
                indicateView?.stopAnimating()
            }else {
                if let f = (tableView.tableFooterView as? LoadMoreView) {
                    f.startLoading()
                }
                indicateView?.startAnimating()
            }
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        searchBar.delegate = self
        
        self.tableView.estimatedRowHeight = 60
        self.tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        
        indicateView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicateView?.hidesWhenStopped = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView:indicateView!)
    }
    
    
    func loadData(url:String) {
        // 所持请求的数据正在加载中/未加载
        if isLoading { return }
        isLoading = true
        HttpUtil.GET(url: url, params: nil) { ok, res in
            var subDatas:[KeyValueData<Int, String>] = []
            if ok { //返回的数据是我们要的
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    // load fromHash
                    let exitNode = doc.xpath("/html/body/div[@class=\"footer\"]/div/a[2]").first
                    if let hash =  Utils.getFormHash(from: exitNode?["href"]) {
                        print("formhash: \(hash)")
                        App.formHash = hash
                    }
                    
                    //load subdata
                    subDatas = self.parseData(doc: doc)
                }
            }
            let count = self.datas.count
            self.datas.append(contentsOf: subDatas)
            DispatchQueue.main.async{
                self.tableView.beginUpdates()
                var indexs = [IndexPath]()
                for i in 0 ..< subDatas.count {
                    indexs.append(IndexPath(row: count + i, section: 0))
                }
                self.tableView.insertRows(at: indexs, with: .automatic)
                self.tableView.endUpdates()
            }
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 1 * NSEC_PER_SEC)){
                self.isLoading = false
            }
        }
    }
    
    func parseData(doc: HTMLDocument) -> [KeyValueData<Int, String>] {
        var subDatas = [KeyValueData<Int, String>]()
        let resultsNodes = doc.xpath("/html/body/div[1]/ul/li")
        
        nextPageUrl = nil
        if let node = doc.xpath("/html/body/div[1]/div/a[2]").first {
            if node.text!.contains("下一页") {
                nextPageUrl = doc.xpath("/html/body/div[1]/div/a[2]").first?["href"]
            }
        }
        
        
        for result in resultsNodes {
            let tid = Utils.getNum(from: result.xpath("a").first?["href"] ?? "0")
            if tid == nil || tid! <= 0 { continue }
            let title = result.xpath("a").first?.text ?? "标题"
            //print("tid: \(tid!) title: \(title)")
            subDatas.append(KeyValueData(key: tid!, value: title))
        }
        
        return subDatas
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let text = datas[indexPath.row].value
        
        if  let searchText = searchBar.text?.trimmingCharacters(in: CharacterSet.whitespaces) {
            if let range = text.range(of: searchText) {
                let attrStr =  NSMutableAttributedString(string: text)
                attrStr.addAttributes([NSAttributedStringKey(rawValue: NSAttributedStringKey.foregroundColor.rawValue): UIColor.red],
                                      range: NSMakeRange(range.lowerBound.encodedOffset, range.upperBound.encodedOffset - range.lowerBound.encodedOffset))
                titleLabel.attributedText = attrStr
                return cell
            }
        }
        
        titleLabel.text = text
        return cell
    }
    
    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .insert {
//            // TODO 收藏
//        }
    }
 */
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if datas.count == 0 {//no data avaliable
            let label = UILabel(frame:CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            label.text = placeholderText
            label.textColor = UIColor.black
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 20)
            label.textColor = UIColor.lightGray
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
    
    // load more
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= 10.0 {
            if !isLoading  && nextPageUrl != nil{
                print("load more")
                loadData(url: nextPageUrl!)
            }
        }
    }
    
    
    // MARK: - Search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            datas = []
            tableView.reloadData()
            nextPageUrl = nil
            isLoading = true
            
            if text.count > 0 {
                HttpUtil.POST(url: Urls.searchUrl, params:["searchsubmit":"yes","srchtxt":text]) { (ok, res) in
                    if ok {
                        if let doc = try? HTML(html: res, encoding: .utf8) {
                            //page == 1
                            self.datas = self.parseData(doc: doc)
                            if self.datas.count > 0 {
                                self.placeholderText = "请输入你要搜索的内容"
                            }else {
                                var errText: String?
                                if let summeryNode = doc.xpath("/html/body/div[1]/h2").first {
                                    errText = summeryNode.text
                                } else if let errNode = doc.xpath("/html/body/div[1]/p[1]").first {
                                    errText = errNode.text
                                }
                                self.placeholderText = errText ?? "没有查询到搜索结果"
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
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            
            dest.tid = datas[index.row].key
            dest.title = datas[index.row].value
        }
    }
    
}
