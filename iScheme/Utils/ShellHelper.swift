//
//  ShellHelper.swift
//  iScheme
//
//  Created by lingwan on 2016/12/21.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation

struct ShellHelper {
    public static func exec(launchPath: String, arguments: [String], callback: (String, String) -> Void) {
        guard !launchPath.isEmpty, arguments.filter({$0.isEmpty}).count == 0 else {
            return
        }
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.launch()
        task.waitUntilExit()
        
        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding:.utf8)
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding:.utf8)
        //默认是空字符串
        callback(output!, error!)
    }
}
