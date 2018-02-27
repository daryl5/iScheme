//
//  AppDelegate.swift
//  iScheme
//
//  Created by lingwan on 16/3/2.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Cocoa
import Carbon
import Fabric
import Crashlytics

let kRebuildDeviceMenuNotification = "kRebuildDeviceMenuNotification"

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    //UI
    private let statusItem: NSStatusItem = {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.image = NSImage(named: NSImage.Name(rawValue: "StatusBarButtonImage"))
        return item
    }()
    
    let deviceItem = NSMenuItem(title: Localisation("DEVICES"), action: nil, keyEquivalent: "")
    
    //DataManager
    private let sharedDataManager = DataManager.sharedInstance
    
    //Config
    private let configCenter = ConfigCenter.sharedInstance

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        //Fabric
        Fabric.with([Crashlytics.self])
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

        //Log scheme count
        if configCenter.firstTimeLaunch.value {
            Answers.logCustomEvent(withName: "Launch", customAttributes: ["Scheme Count": sharedDataManager.schemeCount])
            configCenter.firstTimeLaunch.value = false
        }
        
        //UI
        buildMenu()

        //Data change notification
        NotificationCenter.default.addObserver(self, selector: .buildMenu, name: NSNotification.Name(rawValue: kRebuildMenuNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: .updateiOSDeviceList, name: NSNotification.Name(rawValue: kRebuildDeviceMenuNotification), object: nil)
        
        //更新检查
        UpdateManager().checkUpdate()
    }
    
    @objc fileprivate func buildMenu() {
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        
        let jumpItem = NSMenuItem(title: Localisation("QUICK_JUMP"), action: .quickJump, keyEquivalent: "")
        menu.addItem(jumpItem)
        
        //Devices
        if configCenter.iOSDeviceSupport.value {
            updateiOSDeviceList()
            menu.addItem(deviceItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        //Schemes
        for (index, schemeItem) in sharedDataManager.schemeItems.enumerated() {
            let menuItem = schemeItem.menuItem
            menuItem.keyEquivalent = index < 9 ? String(index + 1) : ""
            menu.addItem(menuItem)
        }

        menu.addItem(NSMenuItem.separator())
        
        //Toolbox
        menu.addItem(toolboxMenu())
        
        let settingsItem = NSMenuItem(title: Localisation("PREFERENCES"), action: .openSettings, keyEquivalent: ",")
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem(title: Localisation("EDIT"), action: .edit, keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: Localisation("QUIT"), action: .quit, keyEquivalent: "q"))
    }
    
    @objc fileprivate func quickJump() {
        Answers.logCustomEvent(withName: "Menu Click", customAttributes: ["Mode": configCenter.mode, "Action": "1-Quick Jump"])
        
        Spotlight.sharedInstance.show(nil)
    }
    
    @objc fileprivate func openSettings() {
        Answers.logCustomEvent(withName: "Menu Click", customAttributes: ["Mode": configCenter.mode, "Action": "6-Preferences"])

        SettingPanel.settingPanel.show()
    }
    
    @objc fileprivate func edit() {
        Answers.logCustomEvent(withName: "Menu Click", customAttributes: ["Mode": configCenter.mode, "Action": "7-Edit"])

        ListEditor.sharedInstance.show()
    }
    
    @objc fileprivate func quit() {
        Answers.logCustomEvent(withName: "Menu Click", customAttributes: ["Mode": configCenter.mode, "Action": "8-Quit"])

        NSApp.terminate(self)
    }
    
    //MARK: -
    //MARK: 设备列表
    @objc fileprivate func updateiOSDeviceList() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        let bonjour = BonjourServer.sharedServer
        ClientManager.manager.iOSClients.forEach { client in
            let item = NSMenuItem(title: client.name, action: .selectDevice, keyEquivalent: "")
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let bonjourItem = NSMenuItem(title: (bonjour.state == .on) ? Localisation("STOP_BONJOUR_SERVER") : Localisation("BONJOUR_SERVER"), action: .toggleBonjour, keyEquivalent: "")
        bonjourItem.state = bonjour.state == .on ? NSControl.StateValue.on : NSControl.StateValue.off
        bonjourItem.onStateImage = NSImage.init(named: NSImage.Name.statusAvailable)
        bonjourItem.offStateImage = NSImage.init(named: NSImage.Name.statusUnavailable)
        menu.addItem(bonjourItem)
        
        deviceItem.submenu = menu
    }
    
    @objc fileprivate func selectDevice(_ menuItem: NSMenuItem) {
//        //只有一个设备时不能取消选择
//        if DeviceManager.manager.deviceList.count == 1 {
//            return
//        }
//        
//        menuItem.state = (menuItem.state == NSControl.StateValue.on) ? NSControl.StateValue.off : NSControl.StateValue.on
//        DeviceManager.manager.selectDevice(atIndex: menuItem.tag)
    }
    
    @objc fileprivate func toggleBonjour(_ menuItem: NSMenuItem) {
        menuItem.state = (menuItem.state == NSControl.StateValue.on) ? NSControl.StateValue.off : NSControl.StateValue.on
        menuItem.title = (menuItem.state == NSControl.StateValue.on) ? Localisation("STOP_BONJOUR_SERVER") : Localisation("BONJOUR_SERVER")
        
        let bonjour = BonjourServer.sharedServer
        if menuItem.state == NSControl.StateValue.on {
            Answers.logCustomEvent(withName: "Start Server")

            bonjour.start()
        } else {
            bonjour.stop()
        }
    }
    
    //MARK: -
    //MARK: 工具箱
    private func toolboxMenu() -> NSMenuItem {
        let toolboxMenu = NSMenu()
        toolboxMenu.autoenablesItems = false
        
        let sandboxFinder = NSMenuItem(title: Localisation("OPEN_SANDBOX"), action: .openSandbox, keyEquivalent: "")
        toolboxMenu.addItem(sandboxFinder)
        
        let qrItem = NSMenuItem(title: Localisation("SCAN_SCREEN_QR"), action: .decodeQr, keyEquivalent: "")
        toolboxMenu.addItem(qrItem)
        
        let toolboxItem = NSMenuItem(title: Localisation("TOOLBOX"), action: nil, keyEquivalent: "")
        toolboxItem.submenu = toolboxMenu
        
        return toolboxItem
    }
    
    @objc fileprivate func openSandbox() {
        Answers.logCustomEvent(withName: "Menu Click", customAttributes: ["Mode": configCenter.mode, "Action": "4-Toolbox Sandbox"])
        SandboxFinder().openSandbox()
    }
    
    @objc fileprivate func decodeQr() {
        Answers.logCustomEvent(withName: "Menu Click", customAttributes: ["Mode": configCenter.mode, "Action": "5-Toolbox Decode QR"])

        QRCodeDetector().decodeQr()
    }
}

private extension Selector {
    static let buildMenu        = #selector(AppDelegate.buildMenu)
    
    static let quickJump        = #selector(AppDelegate.quickJump)
    static let selectDevice     = #selector(AppDelegate.selectDevice(_:))
    static let toggleBonjour    = #selector(AppDelegate.toggleBonjour)
    
    static let openSandbox      = #selector(AppDelegate.openSandbox)
    static let decodeQr         = #selector(AppDelegate.decodeQr)
    static let openSettings     = #selector(AppDelegate.openSettings)
    static let edit             = #selector(AppDelegate.edit)
    static let quit             = #selector(AppDelegate.quit)
    
    static let updateiOSDeviceList = #selector(AppDelegate.updateiOSDeviceList)
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        Answers.logCustomEvent(withName: "Open Menu", customAttributes: nil)
    }
}

//MARK: -
//MARK: Localisation
func Localisation(_ key: String, comment: String = "") -> String {
    return NSLocalizedString(key, comment: comment)
}
