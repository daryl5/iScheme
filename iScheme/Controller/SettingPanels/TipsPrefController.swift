//
//  TipsPrefController.swift
//  iScheme
//
//  Created by lingwan on 2017/1/5.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation
import Cocoa
import MASPreferences
import WebKit
import Crashlytics

final class TipsPrefController: NSViewController {
    @IBOutlet weak var tipWebView: WebView!
    
    override func viewDidLoad() {
        let tipsUrl = Bundle.main.url(forResource: Localisation("TIPS-INDEX"), withExtension: "html", subdirectory: "Tips")
        tipWebView.mainFrameURL = tipsUrl!.absoluteString
    }
    
    override func viewDidAppear() {
        Answers.logCustomEvent(withName: "Preference", customAttributes: ["Action": "3-Tips"])
    }
}

extension TipsPrefController: MASPreferencesViewController {
    var viewIdentifier: String {
        return "tips"
    }
    
    public var toolbarItemImage: NSImage? { return NSImage(named: NSImage.Name(rawValue: "bulb")) }
    
    public var toolbarItemLabel: String? { return Localisation("TIPS") }
}
