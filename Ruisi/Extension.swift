//
//  Extension.swift
//  Ruisi
//
//  Created by yang on 2017/11/29.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func index(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }

    func endIndex(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
}

extension UIViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "好", style: .cancel)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
}
