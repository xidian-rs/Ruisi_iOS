//
//  ThemeViewController.swift
//  Ruisi
//
//  Created by yang on 2017/12/14.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class ThemeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    private let themes = ThemeManager.themes

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        self.automaticallyAdjustsScrollViewInsets = false //修复collectionView头部空白
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneClick))
    }

    var zero = 0

    @objc
    func doneClick() {
        let alert = UIAlertController(title: "提示", message: "主题设置重启App后生效", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default, handler: { (ac) in
            //alert.dismiss(animated: true, completion: nil)
            print(1 / self.zero)
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func ThemeChange() {
        let theme = ThemeManager.currentTheme

        //状态栏颜色
        UIApplication.shared.statusBarStyle = .lightContent
        self.setNeedsStatusBarAppearanceUpdate()

        let titleAttr = [NSAttributedStringKey.foregroundColor: theme.titleColor]
        //标题颜色
        self.navigationController?.navigationBar.titleTextAttributes = titleAttr
        //按钮颜色
        self.navigationController?.navigationBar.tintColor = theme.titleColor
        //背景色
        self.navigationController?.navigationBar.barTintColor = theme.primaryColor

    }

    // MARK: UICollectionViewDelegateFlowLayout
    //单元格大小
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = (collectionView.frame.width - 72) / 6.0
        return CGSize(width: cellSize, height: cellSize + 25)
    }

    // collectionView的上下左右间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 16, bottom: 5, right: 16)
    }


    // 单元的行间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }


    // 每个小单元的列间距
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if ThemeManager.currentThemeId != indexPath.row {
            let indexPathBefore = IndexPath(row: ThemeManager.currentThemeId, section: 0)
            ThemeManager.currentThemeId = indexPath.row
            collectionView.reloadItems(at: [indexPathBefore, indexPath])
            ThemeChange()
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return themes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let view = cell.viewWithTag(1) as! ColorItemView
        view.layer.cornerRadius = view.frame.width / 2
        view.backgroundColor = themes[indexPath.row].primaryColor
        if ThemeManager.currentTheme.id == indexPath.row {
            view.selected = true
        } else {
            view.selected = false
        }
        let label = cell.viewWithTag(2) as! UILabel
        label.text = themes[indexPath.row].name
        return cell
    }


    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}
