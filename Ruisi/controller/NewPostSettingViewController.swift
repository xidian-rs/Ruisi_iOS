//
//  NewPostSettingViewController.swift
//  Ruisi
//
//  Created by yang on 2018/9/18.
//  Copyright © 2018年 yang. All rights reserved.
//

import UIKit


// 新发贴设置页面 如散金币设置
class NewPostSettingViewController: UITableViewController {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var pointSize: UITextField!
    @IBOutlet weak var pointCount: UITextField!
    
    private var timeEveryPersonValue = 1
    private var posibilityValue = 100
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .none
        self.clearsSelectionOnViewWillAppear = true
    }
    
    
    private var isLaodMoney = false
    func loadMoney() {
        guard isLaodMoney else {
            return
        }
        
        
    }
    
    @IBAction func moneyChange(_ sender: UITextField) {
        print("money changed \(sender.text)")
        
    }
    @IBAction func timesChange(_ sender: UITextField) {
        print("money changed \(sender.text)")
    }
    
    @IBAction func cancelClick(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    @IBAction func doneClick(_ sender: Any) {
        self.dismiss(animated: true)
    }
    

    @IBAction func timeEveryPeople(_ sender: UIButton) {
        let sheet = UIAlertController(title: "每人最多可获得", message: nil, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.sourceView = sender
        sheet.popoverPresentationController?.sourceRect = sender.bounds

        sheet.addAction(UIAlertAction(title: "1次", style: .default) { action in
            self.timeEveryPersonValue = 1
            sender.setTitle(action.title, for: .normal)
        })
        sheet.addAction(UIAlertAction(title: "2次", style: .default) { action in
            self.timeEveryPersonValue = 2
            sender.setTitle(action.title, for: .normal)
        })
        sheet.addAction(UIAlertAction(title: "3次", style: .default) { action in
            self.timeEveryPersonValue = 3
            sender.setTitle(action.title, for: .normal)
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func possibleClick(_ sender: UIButton) {
        let sheet = UIAlertController(title: "中奖率", message: nil, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.sourceView = sender
        sheet.popoverPresentationController?.sourceRect = sender.bounds

        sheet.addAction(UIAlertAction(title: "100%", style: .default) { action in
            self.posibilityValue = 100
            sender.setTitle(action.title, for: .normal)
        })
        sheet.addAction(UIAlertAction(title: "80%", style: .default) { action in
            self.posibilityValue = 80
            sender.setTitle(action.title, for: .normal)
        })
        sheet.addAction(UIAlertAction(title: "50%", style: .default) { action in
            self.posibilityValue = 50
            sender.setTitle(action.title, for: .normal)
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(sheet, animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
