//
//  NewPostViewController.swift
//  Ruisi
//
//  Created by yang on 2017/12/3.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import Kanna

// 发帖 AND 编辑帖子 TODO 图文混编的发表控件
// 图片附件有2中方式上传
// 1. attachnew[931707] attachnew[931707]可多个可以没值//提交在表单
// 2. [attachimg]931707[/attachimg]在内容
class NewPostViewController: UIViewController,
    UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,
UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var forumStackView: UIStackView!
    @IBOutlet weak var imageCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var selectedBtn: UIButton!
    @IBOutlet weak var subSeletedBtn: UIButton!
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var contentInput: RitchTextView!
    @IBOutlet weak var imagesCollection: UICollectionView! {
        didSet {
            imagesCollection.dataSource = self
            imagesCollection.delegate = self
        }
    }
    
    var fid: Int?
    var typeId: String?
    var name: String?
    
    var isEditMode = false
    var tid: Int? //编辑模式需要
    var pid: Int? //编辑模式需要
    
    private var editFormDatas = [String: String]()
    private var typeIds = [KeyValueData<String, String>]()
    private var progress: UIAlertController!
    private var uploadImages = [UploadImageItem]()

    private var uploadHash: String? {
        didSet {
            DispatchQueue.main.async {
                self.imageCollectionHeight.constant = (self.uploadHash == nil) ? 0 : 80
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = isEditMode ? "编辑帖子" : "发帖"
        if isEditMode {
            forumStackView.isHidden = true
            selectedBtn.isHidden = true
        }
        
        let color = UIColor(white: 0.97, alpha: 1.0)
        contentInput.layer.borderColor = color.cgColor
        contentInput.layer.borderWidth = 1.0
        contentInput.layer.cornerRadius = 2.0
        contentInput.showToolbar = true
        contentInput.context = self
        contentInput.placeholder = "帖子内容"
        
        subSeletedBtn.isHidden = true
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(postClick))]
        
        progress = UIAlertController(title: isEditMode ? "提交中" : "发帖中", message: "请稍后...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 13, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = .gray
        loadingIndicator.startAnimating();
        progress.view.addSubview(loadingIndicator)
        progress.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        uploadHash = nil
        
        if isEditMode {
            loadEditContent()
        } else if let f = fid {
            selectedBtn.setTitle(name, for: .normal)
            fidChange(fid: f)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        titleInput.resignFirstResponder()
        contentInput.resignFirstResponder()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return uploadImages.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: (indexPath.row == uploadImages.count) ? "addCell" : "imageCell", for: indexPath)
        
        if indexPath.row < uploadImages.count {
            let imageBg = cell.viewWithTag(1) as! UIImageView
            let delBtn = cell.viewWithTag(2) as! UIButton
            let loadingIndicate = cell.viewWithTag(3) as! UIActivityIndicatorView
            let failedBtn = cell.viewWithTag(4) as! UIButton
            let d = uploadImages[indexPath.row]
            imageBg.image = d.image
            switch d.state {
            case .uploading(_):
                loadingIndicate.startAnimating()
                delBtn.isHidden = true
                failedBtn.isHidden = true
            case .success:
                delBtn.isHidden = false
                loadingIndicate.stopAnimating()
                failedBtn.isHidden = true
            case .failed:
                loadingIndicate.stopAnimating()
                delBtn.isHidden = false
                failedBtn.isHidden = false
            }
            
            failedBtn.addTarget(self, action: #selector(uploadFailedBtnClick), for: .touchUpInside)
            delBtn.addTarget(self, action: #selector(deleteUploadBtnClick), for: .touchUpInside)
        } else {
            let addBtn = cell.viewWithTag(1) as! UIButton
            addBtn.addTarget(self, action: #selector(addUploadClick), for: .touchUpInside)
        }
        
        cell.contentView.layer.cornerRadius = 2.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor(white: 0.97, alpha: 1.0).cgColor
        cell.contentView.layer.masksToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if indexPath.row == uploadImages.count {
            addUploadClick()
        }
    }
    
    @objc func uploadFailedBtnClick(sender: UIButton) {
        if let item = sender.superview?.superview as? UICollectionViewCell, let index = imagesCollection.indexPath(for: item) {
            let alert = UIAlertController(title: "此图片上传失败", message: "请选择要执行的操作", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { (action) in
                self.uploadImages.remove(at: index.item)
                self.imagesCollection.deleteItems(at: [index])
            }))
            alert.addAction(UIAlertAction(title: "重新上传", style: .default, handler: { (action) in
                self.uploadImage(position: index.item, image: self.uploadImages[index.row].image)
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func deleteUploadBtnClick(sender: UIButton) {
        if let item = sender.superview?.superview as? UICollectionViewCell, let index = imagesCollection.indexPath(for: item) {
            let alert = UIAlertController(title: "删除图片附件?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "删除", style: .destructive, handler: { (action) in
                print("do delete")
                HttpUtil.GET(url: Urls.deleteUploadedUrl(aid: self.uploadImages[index.item].aid!), params: nil, callback: { (ok, res) in
                    print("delete result :\(res)")
                })
                
                self.uploadImages.remove(at: index.item)
                self.imagesCollection.deleteItems(at: [index])
            }))
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func addUploadClick() {
        let handler: ((UIAlertAction) -> Void) = { alert in
            let picker = UIImagePickerController()
            picker.delegate = self
            if alert.title == "相册" {
                picker.sourceType = .photoLibrary
            } else {
                picker.sourceType = .camera
            }
            self.present(picker, animated: true, completion: nil)
        }
        
        let alert = UIAlertController(title: "请选择图片来源", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "相册", style: .default, handler: handler))
        alert.addAction(UIAlertAction(title: "拍照", style: .default, handler: handler))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        //print(info)
        if let imageData = image {
            uploadImages.append(UploadImageItem(name: "1.png", image: imageData))
            let indexPath = IndexPath(item: uploadImages.count - 1, section: 0)
            self.imagesCollection.insertItems(at: [indexPath])
            uploadImage(position: indexPath.row, image: imageData)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func checkInput() -> Bool {
        var reason: String?
        if !isEditMode {
            if fid == nil {
                reason = "你还没有选择分区"
            }
        }
        
        if titleInput.text == nil || titleInput.text?.count == 0 {
            reason = "标题不能为空"
        } else if contentInput.text == nil || contentInput.text.count == 0 {
            reason = "内容不能为空"
        }
        
        if reason != nil {
            let alert = UIAlertController(title: "提示", message: reason, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        return reason == nil
    }
    
    func uploadImage(position: Int, image: UIImage) {
        uploadImages[position].state = .uploading(progress: 0)
        imagesCollection.reloadItems(at: [IndexPath(item: position, section: 0)])
        let formData: [String: NSObject] = [
            "uid": String(App.uid!) as NSObject,
            "hash": self.uploadHash! as NSObject
        ]
        
        let quality: CGFloat
        if image.size.width < 512 && image.size.height < 512 {
            quality = 1
        } else if image.size.width < 1024 && image.size.height < 1024 {
            quality = 0.92
        } else {
            quality = 0.84
        }
        
        //UIImagePNGRepresentation(image)
        if let imageData = UIImageJPEGRepresentation(image, quality) {
            print("image data length:\((imageData as NSData).length)")
            HttpUtil.UPLOAD_IMAGE(url: Urls.uploadImageUrl, params: formData, imageName: "upload_\(position).jpg", imageData: imageData) { [weak self] (ok, res) in
                print("upload result:\(res) \(ok)")
                if self?.uploadImages.count ?? 0 - 1 < position || self?.uploadImages[position].image != image {
                    return
                }
                DispatchQueue.main.async {
                    if ok {
                        self?.uploadImages[position].aid = res
                        self?.uploadImages[position].state = .success
                        self?.uploadImages[position].errmessage = nil
                    } else {
                        self?.uploadImages[position].state = .failed
                        self?.uploadImages[position].errmessage = res
                        
                        let alert = UIAlertController(title: "上传图片附件出错", message: res, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
                        self?.present(alert, animated: true, completion: nil)
                    }
                    self?.imagesCollection.reloadItems(at: [IndexPath(item: position, section: 0)])
                }
            }
        } else {
            let alert = UIAlertController(title: "图片格式错误", message: "请选择适合的图片", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好", style: .cancel, handler: nil))
            uploadImages[position].state = .failed
            uploadImages[position].errmessage = "无法解析的图片"
            self.present(alert, animated: true) {
                self.imagesCollection.reloadItems(at: [IndexPath(item: position, section: 0)])
            }
        }
    }
    
    func fidChange(fid: Int) {
        typeIds = []
        typeId = nil
        subSeletedBtn.isHidden = true
        
        HttpUtil.GET(url: Urls.newPostUrl(fid: fid), params: nil) { [weak self] (ok, res) in
            if ok {
                if let index = res.endIndex(of: "uploadformdata:") {
                    //uploadformdata:{uid:"252553", hash:"fe626ed21ff334263dfe552cd9a4c209"},
                    if let r = res.range(of: "}", options: String.CompareOptions.literal, range: index..<res.endIndex) {
                        if let hashStartIndex = res.range(of: "hash:\"", options: .literal, range: index..<r.upperBound)?.upperBound {
                            let hashEndIndex = res.index(r.upperBound, offsetBy: -2)
                            self?.uploadHash = String(res[hashStartIndex..<hashEndIndex])
                            print("upload hash:\(self?.uploadHash ?? "")")
                        }
                    }
                }
            }
            if ok && self?.fid == fid {
                if let doc = try? HTML(html: res, encoding: .utf8) {
                    let nodes = doc.css("#typeid option")
                    for node in nodes {
                        if !node.text!.contains("选择主题分类") {
                            self?.typeIds.append(KeyValueData(key: node["value"]!, value: node.text!))
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    if self?.typeIds.count ?? 0 > 0 {
                        self?.typeId = self?.typeIds[0].key
                        self?.subSeletedBtn.isHidden = false
                        self?.subSeletedBtn.setTitle(self?.typeIds[0].value, for: .normal)
                    }
                }
            }
        }
    }
    
    // 加编辑帖子的内容
    func loadEditContent() {
        HttpUtil.GET(url: Urls.editPostUrl(tid: tid!, pid: pid!), params: nil) { [weak self] (ok, res) in
            var success = false
            if ok, let node = try? HTML(html: res, encoding: .utf8) {
                let inputs = node.xpath("//input[@name]")
                for input in inputs {
                    if let v = input["value"] {
                        self?.editFormDatas[input["name"]!] = v
                    }
                }
                
                if let content = node.xpath("//*[@id=\"needmessage\"]").first {
                    self?.editFormDatas["message"] = content.text ?? ""
                }
                
                if self?.editFormDatas["subject"] != nil && self?.editFormDatas["message"] != nil {
                    success = true
                    if let index = res.endIndex(of: "uploadformdata:") {
                        //uploadformdata:{uid:"252553", hash:"fe626ed21ff334263dfe552cd9a4c209"},
                        if let r = res.range(of: "}", options: String.CompareOptions.literal, range: index..<res.endIndex) {
                            if let hashStartIndex = res.range(of: "hash:\"", options: .literal, range: index..<r.upperBound)?.upperBound {
                                let hashEndIndex = res.index(r.upperBound, offsetBy: -2)
                                self?.uploadHash = String(res[hashStartIndex..<hashEndIndex])
                                print("upload hash:\(self?.uploadHash ?? "")")
                            }
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                if success {
                    if let title = self?.editFormDatas["subject"] {
                        if title == "" {
                            self?.titleInput.isHidden = true
                        } else {
                            self?.titleInput.text = self?.editFormDatas["subject"]
                        }
                    }
                    self?.contentInput.text = self?.editFormDatas["message"]
                } else {
                    let alert = UIAlertController(title: "错误", message: "本贴不支持编辑！", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "好", style: .default) { alert in
                        self?.navigationController?.popViewController(animated: true)
                    })
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func chooseSubForumClick(_ sender: UIButton) {
        let sheet = UIAlertController(title: "请选择主题分类", message: nil, preferredStyle: .actionSheet)
        for a in typeIds {
            sheet.addAction(UIAlertAction(title: a.value, style: .default) { ac in
                self.typeId = a.key
                self.subSeletedBtn.setTitle(a.value, for: .normal)
            })
        }
        self.present(sheet, animated: true, completion: nil)
    }
    
    @objc func postClick() {
        if !checkInput() {
            return
        }
        self.titleInput.resignFirstResponder()
        self.contentInput.resignFirstResponder()
        
        var reason: String?
        for item in uploadImages {
            switch item.state {
            case .uploading(_):
                reason = "你有正在上传的图片你确定要发帖吗?未成功上传的图片不会发送"
            case .failed:
                reason = "你有上传失败的图片你确定要发帖吗?未成功上传的图片不会发送"
            default: break
            }
        }
        
        if reason != nil {
            let alert = UIAlertController(title: "提示", message: reason, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "继续发帖", style: .default) { action in
                self.doPost()
            })
            alert.addAction(UIAlertAction(title: "等等再发", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            doPost()
        }
    }
    
    // 开始post没有任何检查 所有的检查之前已经合法
    func doPost() {
        self.present(progress, animated: true, completion: nil)
        
        var params: [String: Any]
        if !isEditMode { //发帖
            params = ["topicsubmit": "yes", "subject": titleInput.text!, "message": contentInput.text!]
            if let type = typeId {
                params["typeid"] = type
            }
        } else { // 编辑帖子
            params = editFormDatas
            params["subject"] = titleInput.text!
            params["message"] = contentInput.text!
        }
        
        // 添加附件列表
        uploadImages.forEach { (item) in
            if let aid = item.aid {
                params["attachnew[\(aid)]"] = ""
            }
        }
        
        HttpUtil.POST(url: isEditMode ? Urls.editSubmitUrl : Urls.newPostUrl(fid: self.fid!), params: params) { [weak self] (ok, res) in
            //print(res)
            var success = false
            var message: String
            let str = (self?.isEditMode ?? false) ? "编辑帖子" : "发帖"
            if ok {
                if res.contains("已经被系统拒绝") {
                    success = false
                    message = "由于未知原因\(str)失败"
                } else {
                    success = true
                    message = "\(str)成功!你要返回关闭此页面吗？"
                }
            } else {
                success = false
                message = "网络不太通畅,请稍后重试"
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.progress.dismiss(animated: true) {
                    let alert = UIAlertController(title: success ? "\(str)成功!" : "错误", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: success ? "取消" : "好", style: .cancel, handler: nil))
                    if success {
                        alert.addAction(UIAlertAction(title: "返回", style: .default) { action in
                            self?.navigationController?.popViewController(animated: true)
                        })
                    }
                    
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? UINavigationController, let target = dest.topViewController as? ChooseForumViewController {
            target.callback = { fid, name in
                if self.fid != fid {
                    self.name = name
                    self.fid = fid
                    self.selectedBtn.setTitle(name, for: .normal)
                    self.fidChange(fid: fid)
                }
            }
            target.currentSelectFid = self.fid!
        }
    }
}
