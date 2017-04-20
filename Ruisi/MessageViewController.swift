//
//  MesageViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class MessageViewController: UITableViewController {
    
    let testMessages = ["您发布的资源[软件][exe][Oracle][JDK][jdk-8u112-windows][英文][商业软件][win][x86&64]在过去的24个小时里共有1人下载，收到3金币的奖励！睿思代表广大用户向伟大的发种人致敬",
                        "rpw 回复了您的帖子 [12月12日更新]手机睿思客户端[Android][2.3.0][code:23]",
                        "一泓清泉 回复了您的帖子 看楼下女生穿裙子有感"]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 120
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }

  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let imageView = cell.viewWithTag(1) as! UIImageView
        let typeLabel = cell.viewWithTag(2) as! UILabel
        let timeLabel  = cell.viewWithTag(3) as! UILabel
        let messageContent = cell.viewWithTag(4) as! UILabel
        
        imageView.layer.cornerRadius = imageView.frame.width/2
        typeLabel.text = "系统消息"
        timeLabel.text = "6 天前"
        messageContent.text = testMessages[indexPath.row % 2]
        return cell
    }

    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
  

}
