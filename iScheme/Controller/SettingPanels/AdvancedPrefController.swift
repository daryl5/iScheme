//
//  AdvancedPrefController.swift
//  iScheme
//
//  Created by lingwan on 2016/12/15.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import Cocoa
import MASPreferences
import KeyHolder
import Magnet
import Carbon
import Crashlytics

let kGoFirstRecorderIdentifier      = "kGoFirstRecorderIdentifier"
let kQuickJumpRecorderIdentifier    = "kQuickJumpRecorderIdentifier"

final class AdvancedPrefController: NSViewController {
    @IBOutlet weak var goFirstRecorder: RecordView!
    @IBOutlet weak var quickJumpRecorder: RecordView!
    @IBOutlet weak var iOSSupportButton: NSButton!
    
    override func viewDidLoad() {
        //shotcut
        let config = ConfigCenter.sharedInstance
        goFirstRecorder.identifier = NSUserInterfaceItemIdentifier(rawValue: kGoFirstRecorderIdentifier)
        quickJumpRecorder.identifier = NSUserInterfaceItemIdentifier(rawValue: kQuickJumpRecorderIdentifier)
        
        goFirstRecorder.delegate = self
        quickJumpRecorder.delegate = self
        
        let tintColor = NSColor(red: 0.164, green: 0.517, blue: 0.823, alpha: 1)
        goFirstRecorder.tintColor = tintColor
        quickJumpRecorder.tintColor = tintColor
        
        goFirstRecorder.keyCombo = config.goFirstHotKey
        quickJumpRecorder.keyCombo = config.quickJumpHotKey
        
        //iOS real device supported
        iOSSupportButton.state = config.iOSDeviceSupport.value ? NSControl.StateValue.on : NSControl.StateValue.off
    }
    
    override func viewDidAppear() {
        Answers.logCustomEvent(withName: "Preference", customAttributes: ["Action": "2-Advanced"])
    }
    
    @IBAction func iOSDeviceSupportCheck(_ sender: NSButton) {
        ConfigCenter.sharedInstance.iOSDeviceSupport.value = (sender.state == NSControl.StateValue.on)
    }
}

extension AdvancedPrefController: RecordViewDelegate {
    func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
        HotKeyManager.shared.save(keyCombo: keyCombo, for: recordView.identifier!.rawValue)
    }
    
    func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
        return true
    }
    
    func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
        return true
    }
    
//    func recordViewDidClearShortcut(_ recordView: RecordView) {
//        HotKeyManager.shared.save(keyCombo: nil, for: recordView.identifier!.rawValue)
//    }
    
    func recordViewDidEndRecording(_ recordView: RecordView) {
    }
    
    func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo) {
    }
    
    
//    func recordViewShouldBeginRecording(_ recordView: KeyHolder.RecordView) -> Bool
//
//    func recordView(_ recordView: KeyHolder.RecordView, canRecordKeyCombo keyCombo: Magnet.KeyCombo) -> Bool
//
//    func recordView(_ recordView: KeyHolder.RecordView, didChangeKeyCombo keyCombo: Magnet.KeyCombo?)
//
//    func recordViewDidEndRecording(_ recordView: KeyHolder.RecordView)
}

extension AdvancedPrefController: MASPreferencesViewController {
    var viewIdentifier: String {
        return "advanced"
    }
    
    public var toolbarItemImage: NSImage? { return NSImage.init(imageLiteralResourceName: NSImage.advancedName) }
    
    public var toolbarItemLabel: String? { return Localisation("ADVANCED") }
}
