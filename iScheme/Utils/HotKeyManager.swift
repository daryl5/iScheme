//
//  HotKeyManager.swift
//  iScheme
//
//  Created by lingwan on 16/3/17.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Cocoa
import Magnet
import Crashlytics

final class HotKeyManager: NSObject {
    
    public static let shared = HotKeyManager()
    
    @objc func hotKeyAction(_ sender: Any) {
        guard let hotKey = sender as? HotKey else {
            return
        }
        
        switch hotKey.identifier {
            case kGoFirstRecorderIdentifier:
                let sharedDataManager = DataManager.sharedInstance
                if sharedDataManager.schemeItems.count > 0 {
                    Answers.logCustomEvent(withName: "Hotkey", customAttributes: ["Mode": ConfigCenter.sharedInstance.mode, "Type": "1-Jump First"])

                    sharedDataManager.schemeItems[0].fire()
                }
                break
            case kQuickJumpRecorderIdentifier:
                Answers.logCustomEvent(withName: "Hotkey", customAttributes: ["Mode": ConfigCenter.sharedInstance.mode, "Type": "2-Quick Jump"])

                Spotlight.sharedInstance.show(nil)
                break
            default:
                break
        }
    }
    
    public func save(keyCombo: KeyCombo?, for identifier: String) {
        if let keyCombo = keyCombo {
            HotKeyCenter.shared.unregisterHotKey(with: identifier)
            
            register(keyCombo: keyCombo, identifier: identifier)
        } else {
            HotKeyCenter.shared.unregisterHotKey(with: identifier)
        }

        let config = ConfigCenter.sharedInstance
        
        switch identifier {
            case kGoFirstRecorderIdentifier:
                config.goFirstHotKey = keyCombo
                break
            case kQuickJumpRecorderIdentifier:
                config.quickJumpHotKey = keyCombo
                break
            default:
                break
        }
    }
    
    public func register(keyCombo: KeyCombo?, identifier: String) {
        guard let keyCombo = keyCombo else { return }
        
        let hotKey = HotKey(identifier: identifier, keyCombo: keyCombo, target: self, action: #selector(hotKeyAction))
        hotKey.register()
    }
}
