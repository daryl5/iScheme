//
//  ConfigCenter.swift
//  iScheme
//
//  Created by lingwan on 16/4/5.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import Magnet
import Carbon

struct DiskSetting<VarType> {
    var key: String
    var defaultValue: VarType
    
    var value: VarType {
        get {
            return StandardDefaults.value(forKey: key) as? VarType ?? defaultValue
        }
        set {
            StandardDefaults.setValue(newValue, forKey: key)
            StandardDefaults.synchronize()
        }
    }
    
    init(_ key: String, _ defaultValue: VarType) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    private let StandardDefaults = UserDefaults.standard
}

final class ConfigCenter {
    
    static let sharedInstance = ConfigCenter()
    
    //For logging mode
    var mode: String {
        return androidMode.value ? "2-Android" : (needQRCode.value ? "3-Tester" : "1-iOS")
    }
    
    //For logging scheme count
    var firstTimeLaunch = DiskSetting<Bool>.init(.kFirstTimeLaunch, true)
    
    var iOSMode = DiskSetting<Bool>.init(.kiOSMode, false) {
        didSet {
            if iOSMode.value {
                ClientManager.manager.radioOniOS()
            }
        }
    }
    
    var needQRCode = DiskSetting<Bool>.init(.kNeedQRCode, true) {
        didSet {
            if needQRCode.value {
                ClientManager.manager.radioOnQRCode()
            }
        }
    }
    
    var androidMode = DiskSetting<Bool>.init(.kAndroidMode, false) {
        didSet {
            if androidMode.value {
                ClientManager.manager.radioOnAndroid()
            }
        }
    }
    
    var adbPath = DiskSetting<String>.init(.kAdbPath, "")
    
    var sandboxKey = DiskSetting<String>.init(.kSandboxKey, "")
    
    var iOSDeviceSupport = DiskSetting<Bool>.init(.kiOSDeviceSupport, false) {
        didSet {
            //rebuild menu
            NotificationCenter.default.post(name: Notification.Name(rawValue: kRebuildMenuNotification), object: nil)
        }
    }
    
    //go first
    var goFirstHotKey: KeyCombo? {
        set {
            if let validKeyCombo = newValue {
                _goFirstHotKeyData.value = NSKeyedArchiver.archivedData(withRootObject: validKeyCombo)
            } else {
                UserDefaults.standard.removeObject(forKey: _goFirstHotKeyData.key)
            }
        }
        get {
            return NSKeyedUnarchiver.unarchiveObject(with: _goFirstHotKeyData.value) as? KeyCombo
        }
    }
    
    private var _goFirstHotKeyData = DiskSetting<Data>.init(.kGoFirstHotKey, _defaultGoFirst ?? Data())

    private static var _defaultGoFirst: Data? {
        guard let goFirst = KeyCombo(keyCode: kVK_ANSI_E, cocoaModifiers: [.command, .shift]) else { return nil }
        return NSKeyedArchiver.archivedData(withRootObject: goFirst)
    }
    
    //quick jump
    var quickJumpHotKey: KeyCombo? {
        set {
            if let validKeyCombo = newValue {
                _quickJumpHotKeyData.value = NSKeyedArchiver.archivedData(withRootObject: validKeyCombo)
            } else {
                UserDefaults.standard.removeObject(forKey: .kQuickJumpHotKey)
            }
        }
        get {
            return NSKeyedUnarchiver.unarchiveObject(with: _quickJumpHotKeyData.value) as? KeyCombo
        }
    }
    
    private var _quickJumpHotKeyData = DiskSetting<Data>.init(.kQuickJumpHotKey, _defaultQuickJump ?? Data())
    
    private static var _defaultQuickJump: Data? {
        guard let quickJump = KeyCombo(keyCode: kVK_ANSI_Grave, cocoaModifiers: [.command, .shift]) else { return nil }
        return NSKeyedArchiver.archivedData(withRootObject: quickJump)
    }
    
    //init
    private init() {        
        if let goFirstHotKey = goFirstHotKey {
            HotKeyManager.shared.register(keyCombo: goFirstHotKey, identifier: kGoFirstRecorderIdentifier)
        }
        
        if let quickJumpHotKey = quickJumpHotKey {
            HotKeyManager.shared.register(keyCombo: quickJumpHotKey, identifier: kQuickJumpRecorderIdentifier)
        }
    }
}

//MARK: -
//MARK: UserDefaults Key

private extension String {
    static let kFirstTimeLaunch  = "kiSchemeFirstTimeLaunch"
    static let kiOSMode          = "kiSchemeiOSMode"
    static let kNeedQRCode       = "kiSchemeNeedQRCode"
    static let kAndroidMode      = "kiSchemeAndroidMode"
    static let kAdbPath          = "kiSchemeADBPath"
    static let kSandboxKey       = "kiSchemeSandboxKey"
    static let kGoFirstHotKey    = "kiSchemeGoFirstHotKey"
    static let kQuickJumpHotKey  = "kiSchemeQuickJumpHotKey"
    static let kiOSDeviceSupport = "kiSchemeiOSDeviceSupport"
    
}
