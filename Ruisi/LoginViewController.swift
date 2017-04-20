//
//  LoginViewController.swift
//  Ruisi
//
//  Created by yang on 2017/4/19.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController,UINavigationControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.delegate = self
        
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // 判断要显示的控制器是否是自己
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func login(_ sender: UIButton) {
        print("click")
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func usernameInputEnd(_ sender: UITextField) {
        print("end",sender.text ?? "")
    }
    
    @IBAction func usernameInputChange(_ sender: UITextField) {
        print("change",sender.text ?? "")
    }
    
    @IBAction func cancelClick(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
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
