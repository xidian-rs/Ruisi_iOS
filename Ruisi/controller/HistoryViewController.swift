//
//  HistoryViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/28.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import CoreData

// 浏览历史
class HistoryViewController: UITableViewController {
    
    var historys: [History] = []
    private var emptyPlaceholderText = "加载中..."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(delBtnClick))
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.emptyPlaceholderText = "暂无浏览记录"
            if let hs = SQLiteDatabase.instance?.loadReadHistory(count: 100) {
                self.historys = hs
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    @objc func delBtnClick() {
        let alert = UIAlertController(title: "清空浏览历史", message: "你要清空你的浏览记录吗?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "清空", style: .destructive, handler: { (action) in
            print("清空浏览历史")
            self.historys = []
            self.tableView.reloadData()
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try SQLiteDatabase.instance?.clearHistory()
                } catch {
                    print(error)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if historys.count == 0 {//no data avaliable
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            label.text = emptyPlaceholderText
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
            tableView.separatorStyle = .singleLine
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let titleView = cell.viewWithTag(1) as! UILabel
        let authorView = cell.viewWithTag(2) as! UILabel
        let timeView = cell.viewWithTag(3) as! UILabel
        
        titleView.text = historys[indexPath.row].title
        authorView.text = historys[indexPath.row].author
        timeView.text = historys[indexPath.row].created
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    // 计算行高
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let d = historys[indexPath.row]
        if let height = d.rowHeight {
            return height
        }
        
        let titleHeight = d.title.height(for: tableView.frame.width - 30, font: UIFont.systemFont(ofSize: 16, weight: .medium))
        // 上间距(12) + 标题(计算) + 间距(8) + 昵称(14.5) + 下间距(10)
        d.rowHeight =  12 + titleHeight + 8 + 14.5 + 10
        return d.rowHeight!
    }
    
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let tid = historys[indexPath.row].tid
            DispatchQueue.global(qos: .userInitiated).async {
                try? SQLiteDatabase.instance?.deleteHistory(tid: tid)
                self.historys.remove(at: indexPath.row)
                DispatchQueue.main.async {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? PostViewController,
            let cell = sender as? UITableViewCell {
            let index = tableView.indexPath(for: cell)!
            dest.title = historys[index.row].title
            dest.tid = Int(historys[index.row].tid)
        }
    }
}
