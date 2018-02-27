//
//  StringExtension.swift
//  iScheme
//
//  Created by lingwan on 2017/5/3.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation

extension String {
    //Scheme Process
    func containsCJK() -> Bool {
        let regex: String = ".*[\\u4e00-\\u9fa5].*"
        let pred: NSPredicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return pred.evaluate(with: self)
    }
    
    //Search
    func pinyin() -> String? {
        guard self.containsCJK() else {
            return nil
        }
        
        let str = NSMutableString(string: self) as CFMutableString
        if CFStringTransform(str, nil, kCFStringTransformMandarinLatin, false) &&
            CFStringTransform(str, nil, kCFStringTransformStripDiacritics, false) {
            return str as String
        }
        
        return nil
    }
    
    func fuzzyMatch(_ searchStr: String, caseSensitive: Bool = false) -> Bool {
        guard (!self.isEmpty && !searchStr.isEmpty)
            && (searchStr.count <= self.count) else {
                return false
        }
        
        var orig = caseSensitive ? self : self.lowercased()
        let match = caseSensitive ? searchStr : searchStr.lowercased()
        for matchC in match {
            guard let (_, remainder) = iScheme.first(matchC).run(orig) else {
                return false
            }
            orig = remainder
        }
        
        return true
    }
    
    //Bigbang
    enum Fragment {
        case seperator(String)
        case normal(String)
        
        func associated() -> String {
            switch self {
            case .seperator(let str):
                return str
            case .normal(let str):
                return str
            }
        }
    }
    
    func bigbang(with seperator: String = "?=&") -> [Fragment] {
        var str = self
        var fragments: [Fragment] = []
        
        let processResult: ([Character]) -> String? = { chars in
            return chars.count > 0 ? String(chars) : nil
        }
        
        let seperatorParser = character { seperator.contains($0) }.many.map { processResult($0) }
        let notSeperator = character { !seperator.contains($0) }.many.map { processResult($0) }
        
        while !str.isEmpty {
            if let (result, remainder) = notSeperator.run(str), let ret = result {
                fragments.append(.normal(ret))
                str = remainder
            }
            
            if let (result, remainder) = seperatorParser.run(str), let ret = result {
                fragments.append(.seperator(ret))
                str = remainder
            }
        }
        
        return fragments
    }
}
