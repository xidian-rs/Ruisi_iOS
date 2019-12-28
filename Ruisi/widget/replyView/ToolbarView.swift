//
//  ToolbarView.swift
//  Ruisi
//
//  Created by yang on 2017/12/21.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class ToolbarView: UIView {

    class func toolbarView() -> ToolbarView {
        let nib = UINib(nibName: "ToolbarView", bundle: nil)
        let v = nib.instantiate(withOwner: self, options: nil).first as! ToolbarView
        return v
    }

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var atBtn: UIButton!
    @IBOutlet weak var smileyBtn: UIButton!
    @IBOutlet weak var hideKeyBoardBtn: UIButton!
    
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
        titleLabel.isHidden = true
    }
    
    private var didClickToggleSmiley: ((_ btn: UIButton) -> Void)?
    
    public func onToggleSmiley(execute closure: @escaping (_ btn: UIButton) -> Void) {
        didClickToggleSmiley = closure
    }
    
    @IBAction private func toggleSmiley(_ sender: UIButton) {
        didClickToggleSmiley?(sender)
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
