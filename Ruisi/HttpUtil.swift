//
//  HttpUtil.swift
//  Ruisi
//
//  Created by yang on 2017/6/24.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

extension String {
    var length:Int {
        return self.characters.count
    }

    func indexOf(target: Character) -> Int?{
        if let idx = self.characters.index(of: target) {
            let pos = self.characters.distance(from: self.startIndex, to: idx)
            return pos
        }else {
            return nil
        }
    }
    
    func index(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    
    func endIndex(of string: String, options: CompareOptions = .literal) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    
    func lastIndex(of string: String) -> Index? {
        return self.index(of: string, options: .backwards)
    }
    
    func lastEndIndex(of string: String) -> Index? {
        return self.endIndex(of: string, options: .backwards)
    }
    
    func indexes(of string: String, options: CompareOptions = .literal) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range.lowerBound)
            start = range.upperBound
        }
        return result
    }
    
    func ranges(of string: String, options: CompareOptions = .literal) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while let range = range(of: string, options: options, range: start..<endIndex) {
            result.append(range)
            start = range.upperBound
        }
        return result
    }
    
    
    func contains(s: String) -> Bool {
        return (self.range(of: s) != nil) ? true : false
    }
}


public class HttpUtil {

    public static func encodeUrl(url:String) -> String {
        let escapedString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return escapedString!
    }
    
    public static func decodeUrl(url:String) -> String {
        return url.replacingOccurrences(of: "&amp;", with: "&")
    }
    
    public static func GET(url:String, params: [String:String]?,callback: @escaping (Bool,String)-> Void){
        var url  =  getUrl(url: url)
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        
        if let p = encodeParameters(params){
            url =  url + p
        }
        
        let task = URLSession.shared.dataTask (with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                callback(false, String(describing: error))
                return
            }
            
            // check for http errors
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
                callback(false, "statusCode should be 200, but is \(httpStatus.statusCode)")
                return
            }else{
                
                if let res = String(data: data, encoding: .utf8){
                    callback(true,res)
                    return
                }
                
                callback(true,"response is empty")
                return
            }
        }
        task.resume()
    }
    
    public static func POST(url:String,params: String?,callback: @escaping (Bool, String) -> Void){
        let url  =  getUrl(url: url)
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        if let p = params{
            request.httpBody = p.data(using: .utf8)
        }
        let task = URLSession.shared.dataTask (with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("error=\(String(describing: error))")
                callback(false, String(describing: error))
                return
            }
            
            // check for http errors
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                print("statusCode should be 200, but is \(httpStatus.statusCode)")
                print("response = \(String(describing: response))")
                callback(false, "statusCode should be 200, but is \(httpStatus.statusCode)")
                return
            }else{
                if let res = String(data: data, encoding: .utf8){
                    callback(true,res)
                    return
                }
                
                callback(true,"response is empty")
                return
            }
        }
        
        task.resume()
    }
    
    private static func encodeParameters(_ params: [String:String]?) -> String? {
        if let p = params{
            var pp: String = ""
            p.forEach({ key,value in
                if pp.length > 0{
                    pp.append("&")
                }
                pp.append(encodeUrl(url: key))
                pp.append("=")
                pp.append(encodeUrl(url: value))
            })
            
            if pp.length > 0{
                pp = "?" + pp
            }
            print("params is \(pp)")
            return pp
        }else{
            return nil
        }
    }
    
    private static func getUrl(url:String) -> String {
        if url.index(of: "http://") != nil || url.index(of: "https://") != nil{
            return decodeUrl(url: url)
        }
        
        return baseUrl + decodeUrl(url: url)
    }
}
