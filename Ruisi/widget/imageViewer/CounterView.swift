//
//  ImageCounterView.swift
//  Money
//
//  Created by Kristian Angyal on 07/03/2016.
//  Copyright © 2016 Mail Online. All rights reserved.
//

import UIKit

public class CounterView: UIView {

    var count: Int
    let countLabel = UILabel()
    var currentIndex: Int {
        didSet {
            updateLabel()
        }
    }

    init(frame: CGRect, currentIndex: Int, count: Int) {

        self.currentIndex = currentIndex
        self.count = count

        super.init(frame: frame)

        configureLabel()
        updateLabel()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureLabel() {

        countLabel.textAlignment = .center
        self.addSubview(countLabel)
    }

    func updateLabel() {
        let stringTemplate = "%d / %d"
        let countString = String(format: stringTemplate, arguments: [currentIndex + 1, count])

        countLabel.attributedText = NSAttributedString(string: countString, attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor: UIColor.white])
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        countLabel.frame = self.bounds
    }
}
