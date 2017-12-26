//
//  SignViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 签到页面
class SignViewController: UIViewController {
    
    let items = ["开心", "难过", "郁闷", "无聊", "怒", "擦汗", "奋斗", "慵懒", "衰"]
    let itemsValue = ["kx", "ng", "ym", "wl", "nu", "ch", "fd", "yl", "shuai"]
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var labelSmiley: UILabel!
    @IBOutlet weak var btnSmiley: UIButton!
    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var btnSign: UIButton!
    @IBOutlet weak var haveSignImg: UIImageView!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var labelTotal: UILabel!
    @IBOutlet weak var labelTotal2: UILabel!
    
    var isSigned: Bool = false {
        didSet {
            haveSignImg.isHidden = !isSigned
            labelStatus.isHidden = !isSigned
            labelTotal.isHidden = !isSigned
            labelTotal2.isHidden = !isSigned
            
            labelSmiley.isHidden = isSigned
            btnSmiley.isHidden = isSigned
            inputText.isHidden = isSigned
            btnSign.isHidden = isSigned
        }
    }
    var chooseAlert: UIAlertController!
    var currentSelect = 0
    
    @IBAction func confirmClick(_ sender: UITextField) {
        inputText.resignFirstResponder()
    }
    
    func setLoadingState(isLoading: Bool) {
        loadingView.isHidden = !isLoading
        if isLoading {
            haveSignImg.isHidden = true
            labelStatus.isHidden = true
            labelTotal.isHidden = true
            labelTotal2.isHidden = true
            
            labelSmiley.isHidden = true
            btnSmiley.isHidden = true
            inputText.isHidden = true
            btnSign.isHidden = true
        }
    }
    
    
    @IBAction func chooseClick(_ sender: UIButton) {
        self.inputText.resignFirstResponder()
        present(chooseAlert, animated: true, completion: nil)
    }
    
    @IBAction func signBtnClick(_ sender: UIButton) {
        self.inputText.resignFirstResponder()
        showLoadingView()
        
        let xinqin = itemsValue[currentSelect]
        let say = inputText.text
        
        let qmode: String
        if say == nil {
            qmode = "1"
        } else {
            qmode = "3"
        }
        
        HttpUtil.POST(url: Urls.signPostUrl, params: ["qdxq": xinqin, "qdmode": qmode, "todaysay": say ?? "来自手机睿思IOS", "fastreplay": 0]) { ok, res in
            let message: String
            if ok, let s = res.range(of: "恭喜你签到成功") {
                let end = res.range(of: "</div>", options: .literal, range: s.upperBound..<res.endIndex)
                message = String(res[s.lowerBound..<end!.lowerBound])
            } else {
                message = "签到失败 " + res
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.dismiss(animated: true, completion: {
                    let vc = UIAlertController(title: "签到结果", message: message, preferredStyle: .alert)
                    vc.addAction(UIAlertAction(title: "好", style: .default, handler: { action in
                        self?.dismiss(animated: true)
                    }))
                    self?.present(vc, animated: true)
                })
                
                self?.checkSignStatus()
            }
        }
    }
    
    // 处理选择心情
    func handlePick(action: UIAlertAction) {
        let title = action.title
        for (i, v) in items.enumerated() {
            if v == title {
                currentSelect = i
                btnSmiley.setTitle(title, for: .normal)
                btnSmiley.setTitle(title, for: .focused)
                break
            }
        }
    }
    
    // 检查是否签到
    func checkSignStatus() {
        setLoadingState(isLoading: true)
        HttpUtil.GET(url: Urls.signUrl, params: nil) { ok, res in
            DispatchQueue.main.async { [weak self] in
                self?.setLoadingState(isLoading: false)
                if ok, let doc = try? HTML(html: res, encoding: .utf8) {
                    if res.contains("您今天已经签到过了或者签到时间还未开始") {
                        var daytxt = "0"
                        var monthtxt = "0"
                        for ele in doc.css(".mn p") {
                            if ele.text!.contains("您累计已签到") {
                                let r = ele.text!.range(of: "您累计已签到")
                                daytxt = String(ele.text![r!.lowerBound...])
                            } else if ele.text!.contains("您本月已累计签到") {
                                monthtxt = ele.text!
                            }
                        }
                        self?.labelStatus.text = "今日已签到"
                        self?.labelTotal.text = daytxt
                        self?.labelTotal2.text = monthtxt
                        self?.isSigned = true
                    } else {
                        self?.isSigned = false
                    }
                } else {
                    self?.labelStatus.isHidden = false
                    self?.labelStatus.text = "非校园网无法签到"
                }
            }
        }
    }
    
    
    var loadingAlert: UIAlertController?
    
    func showLoadingView() {
        if loadingAlert == nil {
            loadingAlert = UIAlertController(title: "签到中", message: "请稍后...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = .gray
            loadingIndicator.startAnimating()
            loadingAlert!.view.addSubview(loadingIndicator)
        }
        present(loadingAlert!, animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        chooseAlert = UIAlertController(title: "选择心情", message: nil, preferredStyle: .actionSheet)
        for v in items {
            let ac = UIAlertAction(title: v, style: .default, handler: handlePick)
            chooseAlert.addAction(ac)
        }
        
        chooseAlert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        //btnSmiley.titleLabel?.text = items[currentSelect]
        
        btnSmiley.setTitle(items[currentSelect], for: .normal)
        btnSmiley.setTitle(items[currentSelect], for: .focused)
        
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        if !(7 <= hour && hour < 23) {
            labelStatus.isHidden = false
            labelStatus.text = "不在签到时间 无法签到"
        } else {
            checkSignStatus()
        }
    }
}
