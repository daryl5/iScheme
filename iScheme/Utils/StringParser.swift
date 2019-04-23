//
//  StringParser.swift
//  iScheme
//
//  Created by lingwan on 2017/5/5.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation

struct Parser<Result> {
    typealias Stream = String
    let parse: (Stream) -> (Result, Stream)?
}

extension Parser {
    var many: Parser<[Result]> {
        return Parser<[Result]> { input in
            var result: [Result] = []
            var remainder = input
            while let (element, newRemainder) = self.parse(remainder) {
                result.append(element)
                remainder = newRemainder
            }
            
            return (result, remainder)
        }
    }
    
    func run(_ string: String) -> (Result, String)? {
        guard let (result, remainder) = parse(string) else {
            return nil
        }
        return (result, String(remainder))
    }
    
    func map<T>(_ transform: @escaping (Result) -> T) -> Parser<T> {
        return Parser<T> { input in
            guard let (result, remainder) = self.parse(input) else {
                return nil
            }
            return (transform(result), remainder)
        }
    }
}

func character(condition: @escaping (Character) -> Bool) -> Parser<Character> {
    return Parser { input in
        guard let char = input.first, condition(char) else {
            return nil
        }
        return (char, String(input[input.index(after: input.startIndex)...]))
    }
}

func first(_ character: Character) -> Parser<Character> {
    return Parser { input in
        guard let firstIndex = input.firstIndex(of: character) else {
            return nil
        }
        
        return (character, String(input[input.index(after: firstIndex)..<input.endIndex]))
    }
}
