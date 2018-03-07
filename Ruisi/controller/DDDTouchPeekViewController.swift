//
//  DDDTouchPeekViewController.swift
//  Ruisi
//
//  Created by yang on 2018/3/7.
//  Copyright © 2018年 yang. All rights reserved.
//

import UIKit
import Kingfisher

class DDDTouchPeekViewController: UIViewController {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var potoView:UIImageView?
    var uid:Int?
    var uname:String?
    
    init(uid:Int, uname:String){
        super.init(nibName: nil, bundle: nil)
        self.uid = uid
        self.uname = uname
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initSubView()
        
        self.potoView?.kf.setImage(with: Urls.getAvaterUrl(uid: self.uid!, size: 2))
    }
    
    func initSubView(){
        self.potoView = UIImageView(frame: CGRect(x: 0, y: 64, width: self.preferredContentSize.width,
                                                  height: self.preferredContentSize.height - 64))
        self.potoView?.contentMode = UIViewContentMode.scaleAspectFill
        self.view.addSubview(self.potoView!)
        
        let titleView = UILabel(frame: CGRect(x: 0, y: 0, width: self.preferredContentSize.width, height: 64))
        titleView.backgroundColor = ThemeManager.currentPrimaryColor.withAlphaComponent(0.8)
        titleView.textAlignment = NSTextAlignment.center
        titleView.textColor = UIColor.white
        titleView.font = UIFont.systemFont(ofSize: 20)
        titleView.text = self.uname ?? "匿名"
        self.view.addSubview(titleView)
    }
}
