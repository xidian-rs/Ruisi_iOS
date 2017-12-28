//
//  ChooseForumViewController.swift
//  Ruisi
//
//  Created by yang on 2017/12/3.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

// 发帖 - 选择板块
class ChooseForumViewController: UITableViewController {
    
    private var forums = [Forums]()
    var currentSelectFid: Int = 72
    var callback: ((_ fid: Int, _ name: String) -> ())?
    private var currentSelectIndexPath = IndexPath(row: 0, section: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let before = currentSelectIndexPath
        currentSelectIndexPath = indexPath
        tableView.reloadRows(at: [indexPath, before], with: .automatic)
        callback?(forums[currentSelectIndexPath.section].forums![currentSelectIndexPath.row].fid, forums[currentSelectIndexPath.section].forums![currentSelectIndexPath.row].name)
        presentingViewController?.dismiss(animated: true)
    }
    
    
    @IBAction func cancleClick(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
    
    
    @IBAction func doneClick(_ sender: Any) {
        callback?(forums[currentSelectIndexPath.section].forums![currentSelectIndexPath.row].fid, forums[currentSelectIndexPath.section].forums![currentSelectIndexPath.row].name)
        presentingViewController?.dismiss(animated: true)
    }
}
