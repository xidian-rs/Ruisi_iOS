//
//  PostsViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class PostsViewController: UITableViewController {
    
    var fid: Int? // 由前一个页面传过来的值
    private var loading = false
    var currentPage = 1
    var position = 0 //为了hotnew而准备的
    var refreshView: UIRefreshControl!
    var datas  = [ArticleListData]()
    
    open var isLoading: Bool{
        get{
            return loading
        }
        set {
            loading = newValue
            if !loading {
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
    
    open var url: String {
        return Urls.getPostsUrl(fid: fid!) + "&page=\(currentPage)"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 55
        self.tableView.rowHeight = UITableViewAutomaticDimension
       
        // Initialize the refresh control.
        refreshView = UIRefreshControl()
        Widgets.setRefreshControl(refreshView)
        refreshView.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        self.refreshControl = refreshView
        tableView.tableFooterView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        
        refreshView.beginRefreshing()
        loadData()
    }
    
    @objc func pullRefresh(){
        print("下拉刷新'")
        currentPage = 1
        loadData(position)
    }
    
    func loadData(_ pos: Int = 0) {
        // 所持请求的数据正在加载中/未加载
        if isLoading {
            return
        }
        refreshView.attributedTitle = NSAttributedString(string: "正在加载")
        isLoading = true
        
        print("load data page \(currentPage)")
        HttpUtil.GET(url: url, params: nil) { ok, res in
            var subDatas:[ArticleListData] = []
            if ok && pos == self.position { //返回的数据是我们要的
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    subDatas = self.parseData(pos: pos, doc: doc)
                }
            }
        
            
            //load data ok
            if pos == self.position {
                // 第一次换页清空
                if self.currentPage == 1 {
                    self.datas = subDatas
                    DispatchQueue.main.async{
                        self.tableView.reloadData()
                    }
                } else {
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
                }
                self.currentPage += 1
                
                var str: String
                if subDatas.count > 0 {
                    let df =  DateFormatter()
                    df.setLocalizedDateFormatFromTemplate("MMM d, h:mm a")
                    str = "Last update: "+df.string(from: Date())
                }else{
                    str = "加载失败"
                }
                
                let attrStr = NSAttributedString(string: str, attributes: [
                    NSAttributedStringKey.foregroundColor:UIColor.gray])
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 1 * NSEC_PER_SEC)){
                    self.refreshView.attributedTitle = attrStr
                    self.isLoading = false
                }
            }
            
            print("finish http")
        }
    }
    
    func parseData(pos:Int, doc: HTMLDocument) -> [ArticleListData]{
        var subDatas:[ArticleListData] = []
        for li in doc.css(".threadlist ul li") {
            let a = li.css("a").first
            
            var tid: Int?
            if let u = a?["href"] {
                tid = Utils.getNum(from: u)
            } else {
                //没有tid和咸鱼有什么区别
                continue
            }
            
            var replysStr: String?
            var authorStr: String?
            let replys = li.css("span.num").first
            let author = li.css(".by").first
            if let r =  replys {
                replysStr = r.text
                a?.removeChild(r)
            }
            if let au =  author {
                authorStr = au.text
                a?.removeChild(au)
            }
            let img = (li.css("img").first)?["src"]
            var haveImg = false
            if let i =  img {
                haveImg = i.contains("icon_tu.png")
            }
            
            let title = a?.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n "))
            let color =  Utils.getHtmlColor(from: a?["style"])
            let d = ArticleListData(title: title ?? "未获取到标题", tid: tid!, author: authorStr ?? "未知作者",replys: replysStr ?? "0", read: false, haveImage: haveImg, titleColor: color)
            subDatas.append(d)
        }
        
        print("finish load data pos:\(pos) count:\(subDatas.count)")
        
        return subDatas
    }
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if datas.count == 0 {//no data avaliable
            let label = UILabel(frame:CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            label.text = "加载中..."
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

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let usernameLabel = cell.viewWithTag(2) as! UILabel
        let commentsLabel = cell.viewWithTag(3) as! UILabel
        let d = datas[indexPath.row]
        
        titleLabel.text = d.title
        if let color = d.titleColor {
            titleLabel.textColor = color
        }
        usernameLabel.text = d.author
        commentsLabel.text = d.replyCount
        
        return cell
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
            if !isLoading {
                print("load more")
                loadData(position)
            }
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            dest.title = datas[index.row].title
            dest.tid = datas[index.row].tid
        }
    }

}
