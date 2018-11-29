//
//  MyPostsViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 我的帖子
class MyPostsViewController: BaseTableViewController<ArticleListData> {
    
    override func viewDidLoad() {
        self.autoRowHeight = false
        self.showRefreshControl = true
        
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        initSegment()
    }
    
    private func initSegment() {
        let segment = UISegmentedControl(items: ["我的帖子","我的回复"])
        segment.selectedSegmentIndex = 0
        segment.addTarget(self, action: #selector(segmentChange), for: .valueChanged)
        self.navigationItem.titleView = segment
    }
    
    @objc private func segmentChange(_ sender: UISegmentedControl) {
        position = sender.selectedSegmentIndex
        self.isLoading = false
        self.datas = []
        self.tableView.reloadData()
        self.rsRefreshControl?.beginRefreshing()
        reloadData()
    }
    
    override func getUrl(page: Int) -> String {
        if position == 0 {
            return Urls.getMyPostsUrl(uid: Settings.uid) + "&page=\(page)"
        } else {
            return Urls.myReplysUrl + "&page=\(page)"
        }
    }
    
    override func prepareParseData(pos: Int, res: String) -> [ArticleListData] {
        if pos == 0 {
            return super.prepareParseData(pos: pos, res: res)
        } else {
            let start = res.range(of: "<root><![CDATA[")
            let end = res.range(of: "]]></root>", options: .backwards)
            if let s = start?.upperBound,let e = end?.lowerBound {
                return super.prepareParseData(pos: pos, res: String(res[s..<e]))
            }
        }
        
        return super.prepareParseData(pos: pos, res: res)
    }
    
    override func parseData(pos: Int, doc: HTMLDocument) -> [ArticleListData] {
        var subDatas: [ArticleListData] = []
        let ls = doc.xpath("/html/body/div[1]/ul/li")
        loop1:
            for li in ls {
                let a = li.css("a").first
                var tid: Int?
                if let u = a?["href"] {
                    tid = Utils.getNum(from: u)
                } else {
                    //没有tid和咸鱼有什么区别
                    continue
                }
                
                for d in self.datas {
                    if d.tid == tid {
                        break loop1
                    }
                }
                
                let author: String
                if pos == 1, let by = li.css(".by").first {
                    author = by.text!
                    li.removeChild(by)
                } else {
                    author = ""
                }
                
                let img = (li.css("img").first)?["src"]
                var haveImg = false
                if let i = img {
                    haveImg = i.contains("icon_tu.png")
                }
                
                var replyStr: String
                let replys = li.css("span.num").first
                
                if let r = replys {
                    replyStr = r.text!
                    if pos == 1 {
                        li.removeChild(r)
                    }
                } else {
                    replyStr = "-"
                }
                
                let title = a?.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n "))
                let color = Utils.getHtmlColor(from: a?["style"])
                
                let d = ArticleListData(title: title ?? "未获取到标题", tid: tid!, author: author, replys: replyStr, haveImage: haveImg, titleColor: color)
                d.rowHeight = caculateRowheight(width: self.tableViewWidth, title: d.title)
                subDatas.append(d)
        }
        
        if subDatas.count < 20 {
            self.totalPage = self.currentPage
        }
        return subDatas
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let commentsLabel = cell.viewWithTag(3) as! UILabel
        
        let authorIcon = cell.viewWithTag(4)
        let authorLabel = cell.viewWithTag(5) as! UILabel
        
        let d = datas[indexPath.row]
        
        titleLabel.text = d.title
        if let color = d.titleColor {
            titleLabel.textColor = color
        } else {
            titleLabel.textColor = UIColor.darkText
        }
        
        if d.author.count > 0 {
            authorIcon?.isHidden = false
            authorLabel.isHidden = false
            authorLabel.text = d.author
        } else {
            authorIcon?.isHidden = true
            authorLabel.isHidden = true
            authorLabel.text = nil
        }
        
        commentsLabel.text = d.replyCount
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let d = datas[indexPath.row]
        return d.rowHeight
    }
    
    // 计算行高
    private func caculateRowheight(width: CGFloat, title: String) -> CGFloat {
        let titleHeight = title.height(for: width - 32, font: UIFont.systemFont(ofSize: 16, weight: .medium))
        // 上间距(12) + 正文(计算) + 间距(5) + 昵称(14.5) + 下间距(10)
        return 12 + titleHeight + 5 + 14.5 + 10
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        _ = super.numberOfSections(in: tableView)
        if datas.count == 0 && !isLoading {//no data avaliable
            let title = "暂无帖子"
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            label.text = title
            label.textColor = UIColor.darkGray
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 20)
            label.textColor = UIColor.lightGray
            label.sizeToFit()
            
            tableView.backgroundView = label
            tableView.separatorStyle = .none
            
            return 0
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            return 1
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
