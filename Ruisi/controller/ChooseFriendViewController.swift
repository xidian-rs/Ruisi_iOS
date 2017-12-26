//
//  ChooseFriendViewController.swift
//  Ruisi
//
//  Created by yang on 2017/12/12.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import CoreData

/**
 <?xml version="1.0" encoding="utf-8"?>
 <root><![CDATA[hualong95,卡斯摩,xhmrj,87144959,蓝鹰魂,抚琴而歌,★追逐√,panxipanxi,wangfuyang,FREEDOM_1,FREEDOM_2,dqahmas,草履虫,Dlive,fengqiu,此去经年,youhe6536,FYXGFS,aidim78,cutoutsy,風翊之殇,rpw,evebear,tubowen150,fleur小乔,HT0158,我与六便士]]></root>
 */
class ChooseFriendViewController: UITableViewController {
    
    var delegate: ((_ names: [String]) -> ())?
    var datas = [AtData]()
    var placeholderText = "加载中..."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadAtList()
    }
    
    
    func loadAtList() {
        //以网络数据为准
        HttpUtil.GET(url: Urls.AtListUrl, params: nil) { (ok, res) in
            if ok, let index1 = res.endIndex(of: "CDATA[") {
                let index2 = res.index(of: "]]")!
                res[index1..<index2].split(separator: ",").forEach({ (name) in
                    self.datas.append(AtData(nickname: String(name)))
                })
            }
            
            if self.datas.count == 0 {
                self.placeholderText = "未能获取到好友列表"
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if datas.count == 0 {//no data avaliable
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.bounds.height))
            label.text = placeholderText
            label.textColor = UIColor.black
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 20)
            label.textColor = UIColor.lightGray
            label.sizeToFit()
            
            tableView.backgroundView = label;
            tableView.separatorStyle = .none;
            return 0
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        datas[indexPath.row].checked = !datas[indexPath.row].checked
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let data = datas[indexPath.row]
        
        cell.textLabel?.text = data.nickname
        if data.checked {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    @IBAction func cancleClick(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
    
    
    @IBAction func doneClick(_ sender: Any) {
        var names = [String]()
        self.datas.forEach { (d) in
            if d.checked {
                names.append(d.nickname)
            }
        }
        delegate?(names)
        presentingViewController?.dismiss(animated: true)
    }
    
    //TODO 下一版本
    @IBAction func addClick(_ sender: Any) {
        let alert = UIAlertController(title: "添加要@的人", message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "输入用户名"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "添加", style: .default, handler: { (ac) in
            if let text = alert.textFields?.first?.text?.trimmingCharacters(in: CharacterSet.whitespaces), text.count > 0 {
                
                //a.custom = true
                
                //if self.insertData(name: ) {
                //    self.datas.insert(a, at: 0)
                //    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                //}
                
                alert.dismiss(animated: true, completion: nil)
            }
        }))
        
    }
}
