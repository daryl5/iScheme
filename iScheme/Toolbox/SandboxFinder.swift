//
//  SandboxFinder.swift
//  iScheme
//
//  Created by lingwan on 16/6/23.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import Cocoa

struct SandboxFinder {
    func openSandbox() {
        let sandboxKey = ConfigCenter.sharedInstance.sandboxKey
        
        guard !sandboxKey.value.isEmpty else {
            SettingPanel.settingPanel.showWithSandboxPrompt()
            return
        }

        let bootedDevice = bootedDeviceUDID()
        let alertInfo = { (title: String) in
            NSApp.activate(ignoringOtherApps: true)
            
            let alert = NSAlert()
            alert.alertStyle = NSAlert.Style.informational
            alert.messageText = title
            alert.runModal()
            alert.window.becomeKey()
        }
        
        guard bootedDevice != nil else {
            alertInfo(Localisation("NO_DEVICE_ERROR"))
            return
        }
        
        let applicationDir = "/Users/" + NSUserName() + "/Library/Developer/CoreSimulator/Devices/" + bootedDevice! + "/data/Containers/Data/Application/"
        do {
            let sandboxes = try FileManager.default.contentsOfDirectory(atPath: applicationDir)
            let resultFolders = sandboxes.filter { self.checkAppSandbox(applicationDir + $0, key: sandboxKey.value) }
            
            guard resultFolders.count > 0 else {
                alertInfo(Localisation("NO_SANDBOX_ERROR"))
                return
            }
            
            if resultFolders.count > 1 {
                alertInfo(Localisation("FOUND_SANDBOX") + String(resultFolders.count) + Localisation("SANDBOX_NUM"))
            }
            
            resultFolders.forEach { NSWorkspace.shared.open(URL(fileURLWithPath: applicationDir + $0))}
        } catch {}
    }
    
    private func checkAppSandbox(_ path: String, key: String) -> Bool {
        let plist = path + "/.com.apple.mobile_container_manager.metadata.plist"
        
        if let dict = NSDictionary(contentsOfFile: plist), let bundleId = dict["MCMMetadataIdentifier"] as? String {
            return bundleId.contains(key)
        }
        
        return false
    }
    
    private func bootedDeviceUDID() -> String? {
        var result: String?

        ShellHelper.exec(launchPath: "/usr/bin/xcrun", arguments: ["simctl", "list"], callback: { output, _ in
            do {
                let regex = try NSRegularExpression.init(pattern: "\\((.*?)\\) *\\(Booted\\)", options: NSRegularExpression.Options())
                let matchResult = regex.firstMatch(in: output, options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, output.utf8.count))
                if let range = matchResult?.range(at: 1), let stringRange = Range.init(range, in: output) {
                    result = String(output[stringRange])
                }
            } catch {
            }
        })
        
        return result
    }
}
