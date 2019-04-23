//
//  SettingPanel.swift
//  iScheme
//
//  Created by lingwan on 2016/12/19.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import MASPreferences

final class SettingPanel {
    static let settingPanel = SettingPanel()
    
    private var settingsPanel: MASPreferencesWindowController?
    
    //for focus on sandboxTextField
    private var generalPanel: GeneralPrefController?
    
    func show() {
        let advanced = AdvancedPrefController.init(nibName: "AdvancedPrefController", bundle: nil)
        let tips = TipsPrefController.init(nibName: "TipsPrefController", bundle: nil)
        let about = AboutPrefController.init(nibName: "AboutPrefController", bundle: nil)
        let general = GeneralPrefController.init(nibName: "GeneralPrefController", bundle: nil)
        generalPanel = general
        
        settingsPanel = MASPreferencesWindowController.init(viewControllers: [general, advanced, NSNull.init(), tips, about], title: Localisation("PREFERENCES"))
        settingsPanel?.select(at: 0)
        settingsPanel?.window?.center()
        settingsPanel?.showWindow(nil)
        settingsPanel?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.normalWindow)))
        NSApp.activate(ignoringOtherApps: true)
        settingsPanel?.window?.orderFrontRegardless()
    }
    
    func showWithSandboxPrompt() {
        show()
        generalPanel?.focusOnSandboxInput()
    }
}
