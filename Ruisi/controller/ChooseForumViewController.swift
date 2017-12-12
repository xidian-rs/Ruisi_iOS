//
//  ChooseForumViewController.swift
//  Ruisi
//
//  Created by yang on 2017/12/3.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class ChooseForumViewController: UITableViewController {
    
    //    private let fids = [
    //        72, 549, 108, 551, 550,
    //        110, 217, 142, 552, 560,
    //        554, 548, 216, 91, 555,
    //        145, 144, 152, 147, 215,
    //        125, 140, 563, 566]
    
    //    private let forums = [
    //        "灌水专区", "文章天地", "我是女生", "西电问答", "心灵花园",
    //        "普通交易", "缘聚睿思", "失物招领", "我要毕业啦", "技术博客",
    //        "就业信息发布", "学习交流", "我爱运动", "考研交流", "就业交流",
    //        "软件交流", "嵌入式交流", "竞赛交流", "原创精品", "西电后街", "音乐纵贯线",
    //        "绝对漫域", "邀请专区", "新人指南"]
    
    var forums = [Forums]()
    var currentSelectFid:Int = 72
    var currentSelectIndexPath = IndexPath(row: 0, section: 0)
    var delegate: ForumSelectDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
        let filePath = Bundle.main.path(forResource: "assets/forums", ofType: "json")!
        //let jsonData = jsonString.data(encoding: .utf8)!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath, isDirectory: false))
        let decoder = JSONDecoder()
        forums = try! decoder.decode([Forums].self, from: data).filter({ (f) -> Bool in
            return f.gid != 11
        })
        
        for i in 0..<forums.count {
            for j in 0..<forums[i].forums!.count {
                if currentSelectFid == forums[i].forums![j].fid {
                    currentSelectIndexPath = IndexPath(row: j, section: i)
                    break
                }
            }
        }
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return forums.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forums[section].getSize()
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return forums[section].name
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = forums[indexPath.section].forums![indexPath.row].name
        if currentSelectIndexPath == indexPath {
            cell.accessoryType = .checkmark
        }else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    
        if indexPath != currentSelectIndexPath {
            let before = currentSelectIndexPath
            currentSelectIndexPath = indexPath
            tableView.reloadRows(at: [indexPath,before], with: .automatic)
        }
    }
    
    
    @IBAction func cancleClick(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
    
    
    @IBAction func doneClick(_ sender: Any) {
        delegate.selectFid(fid: forums[currentSelectIndexPath.section].forums![currentSelectIndexPath.row].fid, name: forums[currentSelectIndexPath.section].forums![currentSelectIndexPath.row].name)
        presentingViewController?.dismiss(animated: true)
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
