//
//  InputValidController.swift
//  Ruisi
//
//  Created by yang on 2018/1/26.
//  Copyright © 2018年 yang. All rights reserved.
//

import UIKit

// 验证码输入控件
class InputValidController {
    public var delegate: ((Bool,String,String) -> Void)?
    public var alertVc: UIAlertController?
    
    private var validImageView: UIImageView!
    private var validInputTextField: UITextField!
    private var validValue: String? {
        return validInputTextField.text
    }
    private var validhash: String!
    private var update: String?
    
    init(hash: String, update: String?) {
        alertVc = UIAlertController(title: "验证码\n\n", message: nil, preferredStyle: .alert)
        self.validhash = hash
        self.update = update
        setUpUi()
    }
    
    func show(vc: UIViewController) {
        loadValidImage(hash: validhash, update: self.update)
        vc.present(alertVc!, animated: true, completion: nil)
    }
    
    func setUpUi() {
        let margin: CGFloat = 10.0
        let width = alertVc!.view.frame.size.width
        let rect = CGRect(x: width / 2 - 100 , y: margin + 35, width: 100, height: 50)
        validImageView = UIImageView(frame: rect)
        validImageView.isUserInteractionEnabled = true
        validImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changeValid)))
        alertVc!.view.addSubview(validImageView)
        
        alertVc!.addTextField { (textField) in
            textField.placeholder = "验证码"
            textField.autocapitalizationType = .allCharacters
            self.validInputTextField = textField
        }
        
        validInputTextField.addTarget(self, action: #selector(inputChange(textField:)), for: .editingChanged)
        
        alertVc!.addAction(UIAlertAction(title: "取消", style: .cancel))
        alertVc!.addAction(UIAlertAction(title: "确定", style: .default, handler: { (alert) in
            if let text = self.validInputTextField.text, text.count > 2 {
                self.delegate?(true,self.validhash,text)
            }
        }))
    }
    
    // 输入框改变
    @objc func inputChange(textField: UITextField) {
        self.validInputTextField.textColor = UIColor.darkText
        if let text = textField.text, text.count == 4 {
            checkValid(hash: self.validhash, value: text)
        }
    }
    
    func setValid(hash: String,update: String?) {
        self.validhash = hash
        self.update = update
    }
    
    func loadUpdate() {
        HttpUtil.GET(url: Urls.getValidUpdateUrl(hash: validhash), params: nil) { (ok, res) in
            if ok {
                let start = res.range(of: "update=")?.upperBound
                let end = res.range(of: "&idhash")?.lowerBound
                if let s = start, let e = end {
                    self.update = String(res[s..<e])
                    self.loadValidImage(hash: self.validhash, update: self.update!)
                }
            } else {
                self.update = nil
            }
        }
    }
    
    // 换一个验证码图片
    @objc func changeValid()  {
        let hash = "S\(100 +  (arc4random() % 101))"
        self.validhash = hash
        self.validInputTextField.text = nil
        loadValidImage(hash: validhash, update: update)
    }
    
    // 加载验证码图片
    func loadValidImage(hash: String, update: String?) {
        if update == nil {
            loadUpdate()
            return
        }
        
        HttpUtil.GET_VALID_IMAGE(url: Urls.updateValidUrl(update: update!, hash: hash)) { (ok, data) in
            if ok, let d = data {
                DispatchQueue.main.async {
                    self.validImageView.image =   UIImage.gif(data: d)
                }
            }
        }
    }
    
    // 验证
    func checkValid(hash: String, value: String) {
        HttpUtil.GET(url: Urls.checkValidUrl(hash: validhash, value: value), params: nil) { (ok, res) in
            // err
            //<?xml version="1.0" encoding="utf-8"?>
            //<root><![CDATA[invalid]]></root>
            
            // yes
            //<?xml version="1.0" encoding="utf-8"?>
            //<root><![CDATA[succeed]]></root>
            
            let success: Bool
            if res.contains("succeed") {
                print("验证码输入正确")
                success = true
            } else {
                print("验证码输入错误")
                success = false
            }
            
            DispatchQueue.main.async {
                self.validInputTextField.textColor = success ? .green : .orange
            }
        }
    }
    
}
