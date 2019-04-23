//
//  GeneralPrefController.swift
//  iScheme
//
//  Created by lingwan on 2016/12/15.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import Cocoa
import MASPreferences
import Crashlytics

final class GeneralPrefController: NSViewController {
    @IBOutlet weak var iOSMode: NSButton!
    @IBOutlet weak var qrCodeMode: NSButton!
    @IBOutlet weak var androidMode: NSButton!
    
    var buttonList: Array<NSButton> {
        return [iOSMode, qrCodeMode, androidMode]
    }

    let config = ConfigCenter.sharedInstance
    
    @IBOutlet weak var adbPathTextField: NSTextField!
    @IBOutlet weak var sandboxTextField: NSTextField!
    
    override func viewDidLoad() {
        //load config
        qrCodeMode.state = config.needQRCode.value ? NSControl.StateValue.on : NSControl.StateValue.off
        androidMode.state = config.androidMode.value ? NSControl.StateValue.on : NSControl.StateValue.off
        iOSMode.state = config.iOSMode.value ? NSControl.StateValue.on : NSControl.StateValue.off
        
        adbPathTextField.stringValue = config.adbPath.value
        sandboxTextField.stringValue = config.sandboxKey.value
    }
    
    override func viewDidAppear() {
        Answers.logCustomEvent(withName: "Preference", customAttributes: ["Action": "1-General"])

        //是安卓模式且没设置adb，adbPathTextField获得焦点
        if config.androidMode.value && config.adbPath.value.isEmpty {
            focus(on: adbPathTextField, placeholder: Localisation("ADB_PATH_PROMPT"))
        }
    }
    
    func focusOnSandboxInput() {
        focus(on: sandboxTextField, placeholder: Localisation("SANDBOX_PROMPT"))
    }
    
    private func focus(on textField: NSTextField, placeholder: String) {
        let textColor = [NSAttributedString.Key.foregroundColor: NSColor.red]
        textField.placeholderAttributedString = NSAttributedString(string:placeholder, attributes:textColor)
        textField.becomeFirstResponder()
    }
    
    @IBAction func didChecked(_ sender: NSButton) {
        //adb & sandbox input resign first responder
        self.view.window?.makeFirstResponder(nil)
        adbPathTextField.placeholderAttributedString = nil
        sandboxTextField.placeholderAttributedString = nil
        
        //uncheck others
        buttonList.forEach { $0.state = ($0 == sender ? NSControl.StateValue.on : NSControl.StateValue.off) }
        
        config.iOSMode.value = sender == iOSMode
        config.needQRCode.value = sender == qrCodeMode
        config.androidMode.value = sender == androidMode
        
        //prompt for adb path
        if sender == androidMode && config.adbPath.value.isEmpty {
            focus(on: adbPathTextField, placeholder: Localisation("ADB_PATH_PROMPT"))
        }
    }
    
    //open sandbox on Enter
    @IBAction func sandboxDidEnter(_ sender: NSTextField) {
        guard !sender.stringValue.isEmpty else {
            return
        }
        
        SandboxFinder().openSandbox()
    }
}

extension GeneralPrefController: NSTextFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        
        if textField == adbPathTextField {
            config.adbPath.value = textField.stringValue
        } else {
            config.sandboxKey.value = textField.stringValue
        }
    }
}

extension GeneralPrefController: MASPreferencesViewController {
    var viewIdentifier: String {
        return "general"
    }
    
    public var toolbarItemImage: NSImage? { return NSImage.init(imageLiteralResourceName: NSImage.preferencesGeneralName) }
    
    public var toolbarItemLabel: String? { return Localisation("GENERAL") }
}
