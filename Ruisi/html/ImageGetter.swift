//
//  ImageGetter.swift
//  Ruisi
//
//  Created by yang on 2017/12/10.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

class ImageGetter {
    var maxWidth:Int
    
    init(maxWidth:Int) {
        self.maxWidth = maxWidth
    }
    
    public static func getSmiley(src:String,start:Int,excute closure: @escaping (_ image:UIImage?) -> Void)  {
        if src.starts(with: "static/image/smiley"){
            let s2 = src.replacingOccurrences(of: "static/image/", with: "assets/")
                .replacingOccurrences(of: ".png", with: "")
                .replacingOccurrences(of: ".gif", with: "") // assets/smiley/tieba/111
            if let index = s2.index(of: "/", options: .backwards) {
                let dir = s2[..<index]
                let name = s2[s2.index(after: index)...]
                //print("name:\(name) dir:\(dir)")
                
                if src.starts(with: "static/image/smiley/jgz/") || src.starts(with: "static/image/smiley/tieba/") || src.starts(with: "static/image/smiley/acn/") || src.starts(with: "static/image/smiley/default/")  {
                    if let path = Bundle.main.path(forResource: String(name), ofType: "png", inDirectory: String(dir)) {
                        //print("path:\(path)")
                        closure(UIImage(contentsOfFile: path))
                        return
                    }
                }else {
                    let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    // create a name for your image
                    let dirURL = documentsDirectoryURL.appendingPathComponent(String(dir))
                    let fileURL = dirURL.appendingPathComponent(String(name))
                    
                    if FileManager.default.fileExists(atPath: fileURL.path) { //文件存在
                        //print("smiley exist laod from file")
                        closure(UIImage(contentsOfFile: fileURL.path))
                        return
                    }else {
                        print("smiley not exist download started:\(Urls.baseUrl + src)")
                        guard let u = URL(string: Urls.baseUrl + src) else { return }
                        URLSession.shared.dataTask(with: u) { data, response, error in
                            guard let d = data, error == nil else { return }
                            print(response?.suggestedFilename ?? u.lastPathComponent)
                            print("Download Finished:\(Urls.baseUrl + src)")
                            do {
                                try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
                                try d.write(to: fileURL)
                                //UIImagePNGRepresentation(image)?.writeToFile(filePath, atomically: true) //UIImageJPEGRepresentation
                                print("Image Added Successfully:\(fileURL)")
                            } catch {
                                print(error)
                            }
                            }.resume()
                    }
                }
            }
        }
    }
}
