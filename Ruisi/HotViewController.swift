//
//  HotViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/18.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class HotViewController: UITableViewController {
    // 切换热帖0 和 新帖1
    @IBAction func viewTypeChnage(_ sender: UISegmentedControl) {
        print(sender.selectedSegmentIndex)
        position = sender.selectedSegmentIndex
        currentPage = 1
        loadData(position)
        //tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
    func isLoading(_ pos: Int) -> Bool {
        if pos == 0 {
            return isHotLoading
        }else{
            return isNewLoading
        }
    }
    
    func setLoading(_ pos:Int, value: Bool) {
        if pos == 0 {
            isHotLoading = value
        }else{
            isNewLoading = value
        }
        
        if !value {
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
    
    var position = 0
    var datas  = [ArticleListDataSimple]()
    var isHotLoading = false
    var isNewLoading = false
    var currentPage = 1
    var refreshView: UIRefreshControl!
    
    var url:String {
        if position==0{
            return Urls.hotUrl + "&page=\(currentPage)"
        }else{
            return Urls.newUrl + "&page=\(currentPage)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.estimatedRowHeight = 50
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        // Initialize the refresh control.
        refreshView = UIRefreshControl()
        Widgets.setRefreshControl(refreshView)
        refreshView.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        self.refreshControl = refreshView
        tableView.tableFooterView = LoadMoreView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        
        refreshView.beginRefreshing()
        loadData(position)
    }
    
    func pullRefresh() {
        currentPage = 1
        loadData(position)
    }
    
    func loadData(_ pos: Int) {
        // 所持请求的数据正在加载中/未加载
        if isLoading(pos) {
            return
        }
        
        refreshView.attributedTitle = NSAttributedString(string: "正在加载")
        setLoading(pos, value: true)
        
        print("load data page \(currentPage)")
        HttpUtil.GET(url: url, params: nil) { ok, res in
            var subDatas = [ArticleListDataSimple]()
            if ok && pos == self.position { //返回的数据是我们要的
                if let doc = HTML(html: res, encoding: .utf8) {
                    for li in doc.css(".threadlist ul.hotlist li") {
                        let a = li.css("a").first
                        let urls = a?["href"]
                        var replysStr: String?
                        var authorStr: String?
                        let replys = li.css("span.num").first
                        let author = li.css(".by").first
                        if let r =  replys{
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
                        //int titleColor = GetId.getColor(getActivity(), src.select("a").attr("style"));
                        // todo
                        let d = ArticleListDataSimple(title: title ?? "未获取到标题", tid: 12354, author: authorStr ?? "未知作者",replys: replysStr ?? "0", read: false, haveImage: haveImg, titleColor: nil)
                        subDatas.append(d)
                    }
                    
                    print("finish load data pos:\(pos) count:\(subDatas.count)")
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
                    NSForegroundColorAttributeName:UIColor.gray])
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + 1 * NSEC_PER_SEC)){
                    self.refreshView.attributedTitle = attrStr
                    self.setLoading(pos, value: false)
                }
            }
            
            print("finish http")
        }
    }
    
    // MARK : tabview data source
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
            //titleLabel.textColor = UIColor()
        }
        usernameLabel.text = d.author
        commentsLabel.text = d.replyCount
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // UITableView only moves in one direction, y axis
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        
        // Change 10.0 to adjust the distance from bottom
        if maximumOffset - currentOffset <= 10.0 {
            if !isLoading(position) {
                
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
        }
    }
}
