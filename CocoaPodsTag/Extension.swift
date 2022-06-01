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

extension String: Identifiable {
    public var id: Int {
        return self.hashValue
    }
    
    // 去掉前后空格和换行
    func strip() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func tr(fromStr: String, toStr: String) -> String {
        self.replacingOccurrences(of: fromStr, with: toStr)
    }
    
    func regexReplace(with pattern: String) -> String {
        var finalStr = self
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            finalStr = regex.stringByReplacingMatches(in: self, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, self.count), withTemplate: "")
        } catch {
            debugPrint(error)
        }
        return finalStr
    }
    
    func matches(with pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let matches = regex.matches(in: self, options: [], range: NSMakeRange(0, self.count))
        var subStr = [String]()
        //解析出子串
        for match in matches {
            for i in 0 ..< match.numberOfRanges {
                subStr.append(String(self[Range(match.range(at: i), in: self)!]))
            }
        }
        return subStr.first
    }
}
