//
//  ImageGetter.swift
//  Ruisi
//
//  Created by yang on 2017/12/10.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

// TODO 支持下载图片，现在支持表情的下载
class ImageGetter {
    
    private static var queen = Set<String>()
    private var maxWidth: Int
    
    init(maxWidth: Int) {
        self.maxWidth = maxWidth
    }
    
    public static func getSmiley(src: String, start: Int, excute closure: @escaping (_ image: UIImage?) -> Void) -> UIImage? {
        // static/image/smiley/tieba/tb025.png
        guard let lastIndex = src.range(of: "/", options: .backwards)?.lowerBound else { return nil }
        let dir = String(src[..<lastIndex])
            .replacingOccurrences(of: "static/image", with: "assets")
        var name = String(src[src.index(after: lastIndex)...])
        if src.contains("smiley/jgz/") || src.contains("smiley/tieba/") || src.contains("smiley/acn/")
            || src.contains("smiley/default/") || src.contains("smiley/common/") {
            name = name.replacingOccurrences(of: ".png", with: "").replacingOccurrences(of: ".gif", with: "") // assets/smiley/tieba/111
            if let path = Bundle.main.path(forResource: String(name), ofType: "png", inDirectory: String(dir)) {
                return UIImage(contentsOfFile: path)
            } else {
                print("ATTENTION: default smiley not exist \(src)")
            }
        } else {
            //  assets/smiley/tieba/tb025.png
            let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let smileyFileDir = documentsDirectoryURL.appendingPathComponent(dir)
            let smileyFilePath = smileyFileDir.appendingPathComponent(name)
            
            if FileManager.default.fileExists(atPath: smileyFilePath.path) {
                return UIImage(contentsOfFile: smileyFilePath.path)
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
                    do {
                        try FileManager.default.createDirectory(at: smileyFileDir, withIntermediateDirectories: true, attributes: nil)
                        try d.write(to: smileyFilePath)
                        //UIImagePNGRepresentation(image)?.writeToFile(filePath, atomically: true) //UIImageJPEGRepresentation
                        print("smiley saved successfully! \(src)")
                    } catch {
                        print("save error:\(error)")
                    }
                    
                    queen.remove(src)
                }.resume()
            }
        }
        
        return nil
    }
    
    public static func getStatic(src: String, start: Int) -> UIImage? {
        // static/image/bt/torrent.gif
        guard let lastIndex = src.range(of: "/", options: .backwards)?.lowerBound else { return nil }
        guard let lastPointIndex = src.range(of: ".", options: .backwards)?.lowerBound else { return nil }
        let ext = String(src[src.index(after: lastPointIndex)...])
        
        let dir = String(src[..<lastIndex]).replacingOccurrences(of: "static/image", with: "assets")
        let name = String(src[lastIndex..<lastPointIndex])

        if let path = Bundle.main.path(forResource: String(name), ofType: ext, inDirectory: String(dir)) {
            return UIImage(contentsOfFile: path)
        }
        
        return nil
    }
}
