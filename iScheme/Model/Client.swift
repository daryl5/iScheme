//
//  Client.swift
//  iScheme
//
//  Created by lingwan on 2017/6/25.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation
import AppKit

enum ClientState: ExpressibleByBooleanLiteral {
    case on;
    case off;
    
    init(booleanLiteral value: Bool) {
        self = value ? .on : .off
    }
}

protocol Client: CustomStringConvertible {
    var name: String { get set }
    
    var state: ClientState { get set }
    
    func consume(scheme: SchemeItem)
}

//CustomStringConvertible
extension Client {
    var description: String {
        return "\(name)(\(state))"
    }
}

struct QRCodeClient: Client {
    var name: String
    var state: ClientState
    
    func consume(scheme: SchemeItem) {
        print("qr: \(scheme)")
        
        QRCodeViewer.qrCodeView.showWithTitle(scheme.title, content: scheme.encodedScheme)
    }
}

struct iOSSimulatorClient: Client {
    var name: String
    var state: ClientState
    
    func consume(scheme: SchemeItem) {
        print("ios simulator: \(scheme)")
        
        let customAllowedSet =  CharacterSet(charactersIn:"^|#").inverted
        let encodedScheme = scheme.scheme.addingPercentEncoding(withAllowedCharacters: customAllowedSet)!
        
        ShellHelper.exec(launchPath: "/usr/bin/xcrun", arguments: ["simctl", "openurl", "booted", encodedScheme], callback: { _, error in
            guard !error.isEmpty else {
                return
            }
            
            NSApp.activate(ignoringOtherApps: true)
            
            let alert = NSAlert()
            alert.alertStyle = NSAlert.Style.informational
            alert.messageText = error
            alert.informativeText = encodedScheme
            alert.runModal()
            alert.window.becomeKey()
        })
    }
}

struct iOSDeviceClient: Client {
    var name: String
    var state: ClientState
    
    var bonjourClient: BonjourClient
    
    func consume(scheme: SchemeItem) {
        print("ios device: \(scheme)")
        
        guard !scheme.scheme.isEmpty, let data = scheme.scheme.data(using: .utf8) else {
            return
        }
        
        bonjourClient.socket.write(data, withTimeout: -1, tag: 0)
    }
}

struct AndroidClient: Client {
    var name: String
    var state: ClientState
    
    func consume(scheme: SchemeItem) {
        print("android: \(scheme)")
        
        let encodedScheme = "\"" + scheme.encodedScheme + "\""
        let adbPath = ConfigCenter.sharedInstance.adbPath
        
        ShellHelper.exec(launchPath: adbPath.value, arguments: ["shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", encodedScheme], callback: { _, error in
            guard !error.isEmpty else {
                return
            }
            
            //防止报错过长
            var errorDesc = error
            if errorDesc.count > 50 {
                errorDesc = String(errorDesc[..<errorDesc.index(errorDesc.startIndex, offsetBy: 50)])
            }
            
            NSApp.activate(ignoringOtherApps: true)
            
            let alert = NSAlert()
            alert.alertStyle = NSAlert.Style.informational
            alert.messageText = errorDesc
            alert.informativeText = encodedScheme
            alert.runModal()
            alert.window.becomeKey()
        })
    }
}
