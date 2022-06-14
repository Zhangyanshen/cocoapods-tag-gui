//
//  SpecRepo.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/28.
//

import Foundation
import SwiftyJSON

struct SpecRepo: Identifiable, Codable {
    var id: String
    var name: String
    var url: String
    var path: String
    var type: String
    
    init(_ dic: Dictionary<String, String>) {
        id = "\(dic["name"]?.hashValue ?? 0)"
        name = dic["name"] ?? ""
        url = dic["url"] ?? ""
        path = dic["path"] ?? ""
        type = dic["type"] ?? "git"
    }
        
    init(_ json: JSON) {
        id = String(json["name"].stringValue.hashValue)
        name = json["name"].stringValue
        url = json["url"].stringValue
        path = json["path"].stringValue
        type = json["type"].stringValue
    }
}
