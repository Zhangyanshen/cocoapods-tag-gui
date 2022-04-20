//
//  Extension.swift
//  MacOSDemo
//
//  Created by zhangyanshen on 2022/4/14.
//

import Foundation

// 自定义操作符 =~
infix operator =~ : ATPrecedence
precedencegroup ATPrecedence {
    associativity: none
    higherThan: AdditionPrecedence
    lowerThan: MultiplicationPrecedence
}
func =~ (_ target: String, pattern: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return false }
    let matches = regex.matches(in: target, options: [], range: NSMakeRange(0, target.count))
    return matches.count > 0
}

extension String {
    // 去掉前后空格和换行
    func strip() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func tr(fromStr: String, toStr: String) -> String {
        self.replacingOccurrences(of: fromStr, with: toStr)
    }
}
