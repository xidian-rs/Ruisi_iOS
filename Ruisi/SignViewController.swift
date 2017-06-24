//
//  SignViewController.swift
//  Ruisi
//
//  Created by yang on 2017/6/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class SignViewController: UIViewController {
    let items = ["开心", "难过", "郁闷", "无聊", "怒", "擦汗", "奋斗", "慵懒", "衰"]
    let itemsValue = ["kx","ng","ym","wl","nu","ch","fd","yl","shuai"]
    
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    @IBOutlet weak var userImg: UIImageView!
    @IBOutlet weak var labelSmiley: UILabel!
    @IBOutlet weak var btnSmiley: UIButton!
    @IBOutlet weak var inputText: UITextField!
    @IBOutlet weak var btnSign: UIButton!
    
    
    @IBOutlet weak var haveSignImg: UIImageView!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var labelTotal: UILabel!
    @IBOutlet weak var labelTotal2: UILabel!
    
    var isSigned :Bool! {
        didSet{
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
    
    
    func setLoadingState(isLoading :Bool) {
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
        }else{
            let a = isSigned
            isSigned = a
        }
    }
    
    
    @IBAction func chooseClick(_ sender: UIButton) {
        present(chooseAlert, animated: true, completion: nil)
    }
    
    @IBAction func signBtnClick(_ sender: UIButton) {
        
    }
    
    // 处理选择心情
    func handlePick(action: UIAlertAction) {
        let title = action.title
        
        for (i,v) in items.enumerated(){
            if v==title{
                currentSelect = i
                btnSmiley.setTitle(title, for: .normal)
                btnSmiley.setTitle(title, for: .focused)
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        chooseAlert = UIAlertController(title: "选择心情", message: nil, preferredStyle: .actionSheet)
    
        for v in items{
            let ac = UIAlertAction(title: v, style: .default, handler: handlePick)
            chooseAlert.addAction(ac)
        }
        
        chooseAlert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        //btnSmiley.titleLabel?.text = items[currentSelect]
        
        btnSmiley.setTitle(items[currentSelect], for: .normal)
        btnSmiley.setTitle(items[currentSelect], for: .focused)
        
        isSigned = true
        setLoadingState(isLoading: true)
       
        DispatchQueue.global(qos:.userInitiated).asyncAfter(deadline: DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds+NSEC_PER_SEC*2)) {
            [weak self] in
            DispatchQueue.main.async {
                self?.setLoadingState(isLoading: false)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
                
        super.viewWillAppear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
