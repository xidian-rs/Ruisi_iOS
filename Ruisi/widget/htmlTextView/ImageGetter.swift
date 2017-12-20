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
    private static var queen = Set<String>()
    private var maxWidth: Int

    init(maxWidth: Int) {
        self.maxWidth = maxWidth
    }

    public static func getSmiley(src: String, start: Int, excute closure: @escaping (_ image: UIImage?) -> Void) -> UIImage? {
        if src.starts(with: "static/image/smiley") {
            let s2 = src.replacingOccurrences(of: "static/image/", with: "assets/")
                    .replacingOccurrences(of: ".png", with: "")
                    .replacingOccurrences(of: ".gif", with: "") // assets/smiley/tieba/111
            if let index = s2.range(of: "/", options: .backwards)?.lowerBound { //s2.index(of: "/", options: .backwards) {
                let dir = s2[..<index]
                let name = s2[s2.index(after: index)...]
                //print("name:\(name) dir:\(dir)")

                if src.starts(with: "static/image/smiley/jgz/") || src.starts(with: "static/image/smiley/tieba/") || src.starts(with: "static/image/smiley/acn/") || src.starts(with: "static/image/smiley/default/") {
                    if let path = Bundle.main.path(forResource: String(name), ofType: "png", inDirectory: String(dir)) {
                        //print("path:\(path)")
                        return UIImage(contentsOfFile: path)
                    }
                } else {
                    let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    // create a name for your image
                    let dirURL = documentsDirectoryURL.appendingPathComponent(String(dir))
                    let fileURL = dirURL.appendingPathComponent(String(name))

                    if FileManager.default.fileExists(atPath: fileURL.path) { //文件存在
                        //print("smiley exist laod from file")
                        return UIImage(contentsOfFile: fileURL.path)
                    } else {
                        if queen.contains(src) {
                            return nil
                        }
                        queen.insert(src)
                        let u = URL(fileURLWithPath: src, relativeTo: HtmlTextView.baseURL)
                        URLSession.shared.dataTask(with: u) { data, response, error in
                            guard let d = data, error == nil else {
                                return
                            }
                            print(response?.suggestedFilename ?? u.lastPathComponent)
                            do {
                                try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true, attributes: nil)
                                try d.write(to: fileURL)
                                //UIImagePNGRepresentation(image)?.writeToFile(filePath, atomically: true) //UIImageJPEGRepresentation
                                print("smiley saved successfully!:\(src)")
                            } catch {
                                print(error)
                            }

                            queen.remove(src)
                        }.resume()
                    }
                }
            }
        }

        return nil
    }
}
