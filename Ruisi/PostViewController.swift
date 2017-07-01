//
//  PostViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/20.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class PostViewController: UITableViewController,UITextViewDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .action , target: self, action: #selector(PostViewController.showMoreView)),
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(PostViewController.refreshData))
        ]
        
    }
    
    
    //刷新数据
    func refreshData() {
        print("refresh click")
    }
    
    //显示跟多按钮
    func showMoreView(){
        let sheet = UIAlertController(title: "操作", message: nil, preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "浏览器中打开", style: .default, handler: { (UIAlertAction) in
            
            UIApplication.shared.open(URL(string: "http://www.baidu.com")! ,
                                      options: [:],
                                      completionHandler: nil)
            
        }))
        
        sheet.addAction(UIAlertAction(title: "收藏文章", style: .default, handler: { (UIAlertAction) in
            print("star click")
        }))
        
        sheet.addAction(UIAlertAction(title: "分享文章", style: .default, handler: { (UIAlertAction) in
            print("share click")
            let shareVc =  UIActivityViewController(activityItems: [UIActivityType.copyToPasteboard], applicationActivities: nil)
            shareVc.setValue("fusjhfbsd", forKey: "subject")
            
            self.present(shareVc, animated: true, completion: nil)
        }))
        
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (UIAlertAction) in
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(sheet, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else {
            return 10
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCell(withIdentifier: "content", for: indexPath)
        }else {
            cell = tableView.dequeueReusableCell(withIdentifier: "comment", for: indexPath)
        }
        //textView.delegate = self
        //textView.isEditable = false
        //textView.isScrollEnabled  = false
        //textView.attributedText = AtrributeConveter().convert(src: str!)
        return cell
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    
    // textview 链接点击事件
    // textView.delegate = self
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        print(URL.absoluteString)
        
        return false
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
