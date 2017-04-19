//
//  Forum.swift
//  Ruisi
//
//  Created by yang on 2017/4/17.
//  Copyright © 2017年 yang. All rights reserved.
//

class Forums{
    
    var gid :Int
    var name:String
    var login:Bool
    
    var forums:[Forum]?
    
    
    init(gid:Int,name:String,login:Bool) {
        self.gid = gid
        self.name = name
        self.login = login
    }
    
    func getSize() -> Int {
        if forums==nil{
            return 0
        }else{
            return forums!.count
        }
    }
    
    func setForums(forums:[Forum]) {
        self.forums = forums
    }
    
    
    class Forum  {
        
        var name :String
        var fid :Int
        var login :Bool
        
        
        init(fid:Int,name:String,login:Bool) {
            self.name = name
            self.fid = fid
            self.login = login
        }
    }
}
