//
//  SpecRepo.swift
//  CocoaPodsTag
//
//  Created by zhangyanshen on 2022/4/28.
//

import Foundation
import SwiftyJSON

struct SpecRepo: Identifiable {
    var id: String
    var name: String
    var url: String
    var path: String
    var type: String
    
    init(_ json: JSON) {
        id = String(json["url"].stringValue.hashValue)
        name = json["name"].stringValue
        url = json["url"].stringValue
        path = json["path"].stringValue
        type = json["type"].stringValue
    }
}
