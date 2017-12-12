//
//  HttpUtil.swift
//  Ruisi
//
//  Created by yang on 2017/6/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public class HttpUtil {
    
    public static func encodeUrl(url:Any) -> String? {
        return String(describing: url).encodeURIComponent()
        //let escapedString = .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        //return escapedString!
    }
    
    public static func decodeUrl(url:String) -> String {
        return url.replacingOccurrences(of: "&amp;", with: "&")
    }
    
    public static func GET(url:String, params: [String:String]?,callback: @escaping (Bool,String)-> Void){
        var url  =  getUrl(url: url)
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        
        if let p = encodeParameters(params){
            if url.contains("?") {
                url = url + "&" + p
            }else{
                url = url + "?" + p
            }
        }
        
        print("start http get url:\(url)")
        let task = URLSession.shared.dataTask (with: request) { data, response, error in
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
            }else{
                if let res = String(data: data, encoding: .utf8){
                    callback(true,res)
                    return
                }
                
                callback(true,"服务端无返回")
                return
            }
        }
        task.resume()
    }
    
    public static func POST(url:String, params: [String:Any]?,callback: @escaping (Bool, String) -> Void){
        let url  =  getUrl(url: url)
        
        var ps = params
        if let hash = App.formHash {
            if ps != nil {
                ps!["formhash"] = hash
            }else {
                ps = ["formhash":hash]
            }
        }
        
        let components = URLComponents(string: url)
        guard let u = components?.url else {callback(false,"请求链接不合法");  return }
        
        var request = URLRequest(url: u)
        request.httpMethod = "POST"
        
        if let p = encodeParameters(ps) {
            request.httpBody = p.data(using: .utf8)
        }
        
        print("start http post url:\(url)")
        let task = URLSession.shared.dataTask (with: request) { data, response, error in
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
            }else{
                if let res = String(data: data, encoding: .utf8){
                    callback(true,res)
                    return
                }
                callback(true,"服务端无返回")
                return
            }
        }
        
        task.resume()
    }
    
    private static func encodeParameters(_ params: [String:Any]?) -> String? {
        if let p = params{
            var pp: String = ""
            p.forEach({ key,value in
                if pp.count > 0{
                    pp.append("&")
                }
                
                pp.append(key)
                pp.append("=")
                if let v = encodeUrl(url: value) {
                    pp.append(v)
                }
            })
            
            return pp
        }else{
            return nil
        }
    }
    
    private static func encodePostParameters(_ params: [String:Any]?) -> [URLQueryItem]? {
        if let ps = params {
            var items = [URLQueryItem]()
            ps.forEach({ key,value in
                items.append(URLQueryItem(name: key, value: String(describing: value) ))
            })
            return items
        }else {
            return nil
        }
    }
    
    private static func getUrl(url:String) -> String {
        if url.index(of: "http://") != nil || url.index(of: "https://") != nil{
            return decodeUrl(url: url)
        }
        
        return Urls.baseUrl + decodeUrl(url: url)
    }
}

extension String {
    func encodeURIComponent() -> String? {
        let characterSet = NSMutableCharacterSet.alphanumeric()
        characterSet.addCharacters(in: "-_.!~*'()")
        
        return self.addingPercentEncoding(withAllowedCharacters: characterSet as CharacterSet)
    }
}
