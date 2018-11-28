//
//  NewPostSettingViewController.swift
//  Ruisi
//
//  Created by yang on 2018/9/18.
//  Copyright © 2018年 yang. All rights reserved.
//

import UIKit
import Kanna


// 新发贴设置页面 如散金币设置
class NewPostSettingViewController: UITableViewController {
    
    public var callback: ((_ config: MoneyConfig) -> ())?
    public var config: MoneyConfig?
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var infoLabel2: UILabel!
    
    @IBOutlet weak var totalCountTextField: UITextField!
    @IBOutlet weak var perMoneyTextField: UITextField!
    @IBOutlet weak var perTimesBtn: UIButton!
    @IBOutlet weak var chanceBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .none
        self.clearsSelectionOnViewWillAppear = true
        
        if config == nil {
            config = MoneyConfig(myMoney: nil, totalCount: 0, perMoney: 10, perTimes: 1, chance: 100)
        }
        
        totalCountTextField.text = String(config!.totalCount)
        perMoneyTextField.text = String(config!.perMoney)
        perTimesBtn.setTitle("\(config!.perTimes)次", for: .normal)
        chanceBtn.setTitle("\(config!.chance)%", for: .normal)
        
        setMoneyState()
        if config?.myMoney == nil {
            loadMyMoney()
        }
    }
    
    @IBAction func totalTimesChange(_ sender: UITextField) {
        //print("money changed \(sender.text)")
        setMoneyState()
    }
    
    @IBAction func perTimeMoneyChange(_ sender: UITextField) {
        //print("money changed \(sender.text)")
        setMoneyState()
    }
    
    private func setMoneyState() {
        let count = Int(totalCountTextField.text ?? "0") ?? 0
        let perMoney = Int(perMoneyTextField.text ?? "10") ?? 0
        let needMoney = Int(ceil(Double(count) *  Double(perMoney) * 1.15))
        infoLabel.text = "当前金币总数: \(config!.myMoney != nil ? String(config!.myMoney!) : "加载中...")"
        infoLabel2.text = "需要花费金币: \(needMoney)(税率:15%)"
        if let t = self.config?.myMoney, needMoney > t {
            infoLabel2.textColor = UIColor.red
        } else {
            infoLabel2.textColor = UIColor.darkGray
        }
    }
    
    @IBAction func cancelClick(_ sender: Any) {
        totalCountTextField.resignFirstResponder()
        perMoneyTextField.resignFirstResponder()
        
        self.dismiss(animated: true)
    }
    
    @IBAction func doneClick(_ sender: Any) {
        totalCountTextField.resignFirstResponder()
        perMoneyTextField.resignFirstResponder()
        
        setMoneyState()
        guard infoLabel2.textColor == .darkGray else {
            return
        }
        self.config?.totalCount = Int(totalCountTextField.text ?? "0") ?? 0
        self.config?.perMoney = Int(perMoneyTextField.text ?? "10") ?? 0
        
        switch perTimesBtn.title(for: .normal) {
        case "1次":
            self.config?.perTimes = 1
        case "2次":
            self.config?.perTimes = 2
        case "3次":
            self.config?.perTimes = 3
        default:
            break
        }
        
        switch chanceBtn.title(for: .normal) {
        case "100%":
            self.config?.chance = 100
        case "80%":
            self.config?.chance = 80
        case "50%":
            self.config?.chance = 50
        default:
            break
        }
        
        self.dismiss(animated: true) {
            self.callback?(self.config!)
        }
    }
    

    @IBAction func timeEveryPeople(_ sender: UIButton) {
        let sheet = UIAlertController(title: "每人最多可获得", message: nil, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.sourceView = sender
        sheet.popoverPresentationController?.sourceRect = sender.bounds
        
        let handler: ((UIAlertAction) -> Void)? = { action in
            sender.setTitle(action.title, for: .normal)
        }
        sheet.addAction(UIAlertAction(title: "1次", style: .default, handler: handler))
        sheet.addAction(UIAlertAction(title: "2次", style: .default, handler: handler))
        sheet.addAction(UIAlertAction(title: "3次", style: .default, handler: handler))
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func possibleClick(_ sender: UIButton) {
        let sheet = UIAlertController(title: "中奖率", message: nil, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.sourceView = sender
        sheet.popoverPresentationController?.sourceRect = sender.bounds

        let handler: ((UIAlertAction) -> Void)? = { action in
            sender.setTitle(action.title, for: .normal)
        }
        sheet.addAction(UIAlertAction(title: "100%", style: .default, handler: handler))
        sheet.addAction(UIAlertAction(title: "80%", style: .default, handler: handler))
        sheet.addAction(UIAlertAction(title: "50%", style: .default, handler: handler))
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(sheet, animated: true, completion: nil)
    }
    
    // 加载我的金币
    private var isLaodMoney = false
    private var myMoney: Int?
    
    private func loadMyMoney() {
        print("load my money")
        guard !isLaodMoney else {
            return
        }
        
        HttpUtil.GET(url: Urls.myMoneyUrl, params: nil) { (ok, res) in
            print(res)
            guard ok else {return}
            let start = res.range(of: "<root><![CDATA[")
            let end = res.range(of: "]]></root>", options: .backwards)
            guard let s = start?.upperBound, let e = end?.lowerBound else { return }
            
            if let doc = try? HTML(html: String(res[s..<e]), encoding: .utf8) {
                DispatchQueue.main.async { [weak self] in
                    self?.isLaodMoney = true
                    let lis = doc.css("li")
                    var money: Int = 0
                    for li in lis {
                        print(li.text ?? "--")
                        if li.text?.contains("金币") ?? false {
                            money = Int(li.css("span").first?.text ?? "0") ?? 0
                        }
                    }
                    
                    self?.config?.myMoney = money
                    self?.setMoneyState()
                }
            }
            
        }
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
