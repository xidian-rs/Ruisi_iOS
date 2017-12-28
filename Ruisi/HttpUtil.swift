//
//  HttpUtil.swift
//  Ruisi
//
//  Created by yang on 2017/6/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import UIKit

// 自定义http工具类
public class HttpUtil {
    
    //当前正在执行的网络请求数目用于控制小菊花
    private static var  workingSize = 0 {
        didSet {
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = workingSize > 0
            }
        }
    }
    

    public static func encodeUrl(url: Any) -> String? {
        return encodeURIComponent(string: String(describing: url))
        //let escapedString = .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        //return escapedString!
    }

    public static func decodeUrl(url: String) -> String {
        return url.replacingOccurrences(of: "&amp;", with: "&")
    }

    public static func GET(url: String, params: [String: String]?, callback: @escaping (Bool, String) -> Void) {
        var url = getUrl(url: url)
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"

        if let p = encodeParameters(params) {
            if url.contains("?") {
                url = url + "&" + p
            } else {
                url = url + "?" + p
            }
        }

        print("start http get url:\(url)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            HttpUtil.workingSize -= 1
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                callback(false, error?.localizedDescription ?? "似乎已断开与互联网的连接")
                return
            }

            // check for http errors
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                callback(false, "Http Status: \(httpStatus.statusCode)")
                return
            } else {
                if let res = String(data: data, encoding: .utf8) {
                    callback(true, res)
                    return
                }

                callback(true, "服务端无返回")
                return
            }
        }
        
        HttpUtil.workingSize += 1
        task.resume()
    }

    public static func POST(url: String, params: [String: Any]?, callback: @escaping (Bool, String) -> Void) {
        let url = getUrl(url: url)

        var ps = params
        if let hash = App.formHash {
            if ps != nil {
                ps!["formhash"] = hash
            } else {
                ps = ["formhash": hash]
            }
        }

        let components = URLComponents(string: url)
        guard let u = components?.url else {
            callback(false, "请求链接不合法");
            return
        }

        var request = URLRequest(url: u)
        request.httpMethod = "POST"

        if let p = encodeParameters(ps) {
            request.httpBody = p.data(using: .utf8)
        }

        print("start http post url:\(url)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            HttpUtil.workingSize -= 1
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                callback(false, error?.localizedDescription ?? "似乎已断开与互联网的连接")
                return
            }

            // check for http errors
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                callback(false, "Http Status: \(httpStatus.statusCode)")
                return
            } else {
                if let res = String(data: data, encoding: .utf8) {
                    callback(true, res)
                    return
                }
                callback(true, "服务端无返回")
                return
            }
        }

        HttpUtil.workingSize += 1
        task.resume()
    }

    private static let uploadImageErrors = [
        "-1": "内部服务器错误",
        "0": "上传成功",
        "1": "不支持此类扩展名",
        "2": "服务器限制无法上传那么大的附件",
        "3": "用户组限制无法上传那么大的附件",
        "4": "不支持此类扩展名",
        "5": "文件类型限制无法上传那么大的附件",
        "6": "今日您已无法上传更多的附件",
        "7": "请选择图片文件",
        "8": "附件文件无法保存",
        "9": "没有合法的文件被上传",
        "10": "非法操作",
        "11": "今日您已无法上传那么大的附件"
    ]

    // discuz 上传图片接口
    public static func UPLOAD_IMAGE(url: String, params: [String: NSObject]?, imageName: String, imageData: Data, callback: @escaping (Bool, String) -> Void) {
        let components = URLComponents(string: url)
        guard let u = components?.url else {
            callback(false, "请求链接不合法");
            return
        }

        var request = URLRequest(url: u)
        request.httpMethod = "POST"
        let boundary = "------multipartformboundary\(Int(Date().timeIntervalSince1970 * 1000))"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "content-type")

        request.httpBody = createRequestBodyWith(parameters: params, imageName: imageName, imageData: imageData, boundary: boundary) as Data
        print("start http post url:\(url)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            HttpUtil.workingSize -= 1
            print("===========")
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                callback(false, error?.localizedDescription ?? "似乎已断开与互联网的连接")
                return
            }

            // check for http errors
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                callback(false, "Http Status: \(httpStatus.statusCode)")
                return
            } else {
                if let res = String(data: data, encoding: .utf8) {
                    var success: Bool = false
                    var errmsg: String = ""
                    if res == "" || !res.contains("|") {
                        errmsg = "上传失败，请稍后再试"
                    } else {
                        //DISCUZUPLOAD|1|0|931707|1|201712/17/190135adz38c3vodhw6zct.png|tb001.png|0
                        let ress = res.split(separator: "|")
                        if ress[0] == "DISCUZUPLOAD" && ress[2] == "0" {
                            success = true
                            errmsg = String(ress[3])
                        } else {
                            if ress[7] == "ban" {
                                errmsg = "(附件类型被禁止)"
                            } else if ress[7] == "perday" {
                                errmsg = "(不能超过 \(Int(String(ress[8])) ?? 0 / 1024) K)"
                            } else {
                                errmsg = "(不能超过 \(Int(String(ress[7])) ?? 0 / 1024) K)"
                            }

                            if let e = uploadImageErrors[String(ress[2])] {
                                errmsg = e + errmsg
                            } else {
                                errmsg = "我也不知道是什么原因上传失败了"
                            }
                        }
                    }

                    callback(success, errmsg)
                    return
                }
                callback(true, "服务端无返回")
                return
            }
        }

        HttpUtil.workingSize += 1
        task.resume()
    }

    private static func createRequestBodyWith(parameters: [String: NSObject]?, imageName: String, imageData: Data, boundary: String) -> NSData {
        let body = NSMutableData()
        // 表单数据
        if let ps = parameters {
            for (key, value) in ps {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }

        // 图片数据
        let mimetype: String  //application/octet-stream
        if imageName.hasSuffix(".png") {
            mimetype = "image/png"
        } else {
            mimetype = "image/jpg"
        }

        //let imageData = /*UIImageJPEGRepresentation(imageData, 1)!*/ UIImagePNGRepresentation(image)!
        body.appendString(string: "--\(boundary)\r\n")
        body.appendString(string: "Content-Disposition: form-data; name=\"Filedata\"; filename=\"\(imageName)\"\r\n")
        body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageData)
        body.appendString(string: "\r\n")
        body.appendString(string: "--\(boundary)--\r\n")

        return body
    }

    private static func encodeParameters(_ params: [String: Any]?) -> String? {
        if let p = params {
            var pp: String = ""
            p.forEach({ key, value in
                if pp.count > 0 {
                    pp.append("&")
                }

                pp.append(key)
                pp.append("=")
                if let v = encodeUrl(url: value) {
                    pp.append(v)
                }
            })

            return pp
        } else {
            return nil
        }
    }

    private static func encodePostParameters(_ params: [String: Any]?) -> [URLQueryItem]? {
        if let ps = params {
            var items = [URLQueryItem]()
            ps.forEach({ key, value in
                items.append(URLQueryItem(name: key, value: String(describing: value)))
            })
            return items
        } else {
            return nil
        }
    }

    private static func getUrl(url: String) -> String {
        if url.index(of: "http://") != nil || url.index(of: "https://") != nil {
            return decodeUrl(url: url)
        }

        return Urls.baseUrl + decodeUrl(url: url)
    }

    // url编码
    private static func encodeURIComponent(string: String) -> String? {
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-_.!~*'()")

        return string.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)
    }
}

extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
