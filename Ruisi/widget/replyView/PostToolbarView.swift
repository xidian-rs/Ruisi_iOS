//
//  PostToolbarView.swift
//  Ruisi
//
//  Created by yang on 2017/12/21.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

// 发帖页面的键盘上的view
class PostToolbarView: UIView {

    class func toolbarView() -> PostToolbarView {
        let nib = UINib(nibName: "PostToolbarView", bundle: nil)
        let v = nib.instantiate(withOwner: self, options: nil).first as! PostToolbarView
        return v
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var atBtn: UIButton!
    @IBOutlet weak var hideKeyBoardBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    
    public var title: String? {
        didSet{
            if let t = title {
                titleLabel.isHidden = false
                titleLabel.text = t
            } else {
                titleLabel.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("ToolbarView")
        backgroundColor = UIColor(white: 0.96, alpha: 1.0)
        titleLabel.isHidden = true
    }
    
    private var didClickCancel: ((_ btn: UIButton) -> Void)?
    
    public func onCancelClick(execute closure: @escaping (_ btn: UIButton) -> Void) {
        didClickCancel = closure
    }
    
    @IBAction private func clickCancel(_ sender: UIButton) {
        didClickCancel?(sender)
    }
    
    private var didClickAt: ((_ btn: UIButton) -> Void)?
    
    public func onAtClick(execute closure: @escaping (_ btn: UIButton) -> Void) {
        didClickAt = closure
    }
    
    @IBAction private func atClick(_ sender: UIButton) {
        didClickAt?(sender)
    }
    
    private var didClickHideKeyboard: ((_ btn: UIButton) -> Void)?
    
    public func onHideKeyboardClick(execute closure: @escaping (_ btn: UIButton) -> Void) {
        didClickHideKeyboard = closure
    }
    
    @IBAction private func keyboardClick(_ sender: UIButton) {
        didClickHideKeyboard?(sender)
    }
}
