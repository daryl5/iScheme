//
//  AboutPrefController.swift
//  iScheme
//
//  Created by lingwan on 2016/12/15.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import Cocoa
import MASPreferences
import Crashlytics

final class AboutPrefController: NSViewController {
    @IBOutlet weak var nameTextField: NSTextField!
    @IBOutlet weak var versionTextField: NSTextField!
    @IBOutlet weak var copyrightTextField: NSTextField!
    
    @IBOutlet weak var contactMe: NSButton!
    @IBOutlet weak var donate: NSButton!
    
    override func viewDidLoad() {
        contactMe.title = Localisation("CONTACT_ME")
        donate.title = Localisation("DONATE")
        
        let info = Bundle.main.infoDictionary
        
        guard let bundleName = info?["CFBundleName"] as? String,
            let version = info?["CFBundleShortVersionString"] as? String,
            let bundleVersion = info?["CFBundleVersion"] as? String,
            let copyright = info?["NSHumanReadableCopyright"] as? String
            else { return }
        
        nameTextField.stringValue = bundleName
        versionTextField.stringValue = "Version " + version + " (build " + bundleVersion + ")"
        copyrightTextField.stringValue = copyright
    }
    
    override func viewDidAppear() {
        Answers.logCustomEvent(withName: "Preference", customAttributes: ["Action": "4-About"])
    }
    
    @IBAction func contactMeClicked(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "Contact", customAttributes: nil)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let result = pasteboard.setString("wyp853127566@gmail.com", forType: NSPasteboard.PasteboardType.string)
        if result {
            contactMe.title = Localisation("EMAIL_COPIED")
        }
    }
    
    @IBAction func donateClicked(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "Donate", customAttributes: nil)

        let url = URL(string: Localisation("DONATE_URL"))
        if let url = url {
            NSWorkspace.shared.open(url)
        }
    }
}

extension AboutPrefController: MASPreferencesViewController {
    var viewIdentifier: String {
        return "about"
    }
    
    public var toolbarItemImage: NSImage? { return NSImage.init(imageLiteralResourceName: NSImage.Name.info.rawValue) }
    
    public var toolbarItemLabel: String? { return Localisation("ABOUT") }
}
