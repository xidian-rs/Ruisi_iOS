//
//  AgreementViewController.swift
//  Ruisi
//
//  Created by yang on 2018/9/1.
//  Copyright © 2018年 yang. All rights reserved.
//

import UIKit

class AgreementViewController: UITableViewController {
    
    var agreement = """
    <br>
    欢迎您加入『西电睿思』(下文中指代“我们”，“我们的”，“睿思”)，『西电睿思』为西电学生创立的校园内网站点。您一旦注册成为我们的会员，则意味着已完全接受以下条款，并完全服从于西电睿思管理团队的统一管理。<br>
    <br>
    在使用睿思网站及相关功能的过程中，您必须遵守中华人民共和国各项有关法律法规，尊重道德和风俗习惯。不得利用睿思网站及相关功能从事违法违规行为，包括但不限于：<br>
     1）制作、发布、传播和储存危害国家安全统一、破坏社会稳定、违反公共道德、侮辱、诽谤、淫秽、暴力以及任何违反国家法律法规的内容；<br>
     2）恶意虚构事实、隐瞒真相以误导、欺骗他人；<br>
     3）发布、传送、传播广告信息及垃圾信息；<br>
     4）其他法律法规禁止的行为。<br>
     如您有违反以上几条的行为，我们有权利进行修改、删除和关闭话题等操作。涉及到违法犯罪的，我们将上交公安机关处理，您应当独立承担直接或间接导致的民事、行政或刑事法律责任。<br>
    <br>
    作为西安电子科技大学校园网内网站点，您在使用睿思网站及相关功能的过程中必须遵守学校相关规定和规范要求，不得发表明显带有对学校及相关话题非讨论性、恶意攻击性或错误导向性的文章。您不得以任何非法手段修改、破坏、删除西电睿思网站或数据库的内容，不得对我们的服务器、系统或网络进行任何形式的攻击、破坏。否则，我们有权封停或删除您的账号，情节严重者，将上报有关部门处理。在使用睿思网站及相关功能的过程中，您必须遵守睿思总规范及各分区版规。对于不符合规范的，我们有权移动、修改、删除、合并和关闭话题，情节严重者，我们有权采取警告、封停或删除账号等措施。<br>
    <br>
    您同意您所输入的任何信息将被记录至数据库，以协助调查可能涉及的违法犯罪事件。我们尊重并保护您的个人信息，但是不能为任何因为黑客行为导致的数据泄漏承担法律责任。<br>
    <br>
    其他注意事项：<br>
     1. 您在使用睿思网站及相关功能的过程中发表的言论仅代表您的个人观点，不代表我们的观点。<br>
     2. 根据国家相关法律法规和学校管理的要求，我们对部分敏感文字进行了过滤。<br>
     3. 本条款由西电睿思管理团队制定，解释权、修改权归西电睿思管理团队所有。本条款的改动恕不另行通知，具体请关注并参看公告。<br>
     4. 本条款未涉及的问题参见国家有关法律法规，当本条款与国家法律法规冲突时，以国家法律法规为准。<br>
    西电睿思管理团队<br>
    <br>
    """
    
    @IBOutlet weak var agreementLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        agreementLabel.attributedText = AttributeConverter(font: agreementLabel.font, textColor: agreementLabel.textColor).convert(src: agreement)
    }

    @IBAction func backClick(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
}
