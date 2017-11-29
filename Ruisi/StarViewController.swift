//
//  StarViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 我的收藏页面
class StarViewController: AbstractTableViewController<StarData> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func getUrl(page: Int) -> String {
        return Urls.getStarUrl(uid: App.uid) + "&page=\(page)"
    }
    
    
    override func parseData(pos:Int, doc: HTMLDocument) -> [StarData]{
        var subDatas:[StarData] = []
        for li in doc.xpath("/html/body/div[1]/ul/li") {
            let a = li.css("a").first
            var tid: Int?
            if let u = a?["href"] {
                tid = Utils.getNum(from: u)
            } else {
                //没有tid和咸鱼有什么区别
                continue
            }
            
            let title = a?.text?.trimmingCharacters(in: CharacterSet(charactersIn: "\r\n "))
            let color =  Utils.getHtmlColor(from: a?["style"])
            let d = StarData(title: title ?? "未获取到标题", tid: tid!,titleColor: color)
            subDatas.append(d)
        }
        
        print("finish load data pos:\(pos) count:\(subDatas.count)")
        return subDatas
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let titleLabel = cell.viewWithTag(1) as! UILabel
        let d = datas[indexPath.row]
        
        titleLabel.text = d.title
        if let color = d.titleColor {
            titleLabel.textColor = color
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            showDeleteStarAlert(indexPath: indexPath)
        }
    }
    
    func showDeleteStarAlert(indexPath: IndexPath) {
        let title = datas[indexPath.row].title
        let _ =  datas[indexPath.row].tid
        let alert = UIAlertController(title: "删除收藏", message: "取消收藏【\(title)】?吗?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消收藏(暂不支持)", style: .destructive, handler: { (action) in
            // TODO
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
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
