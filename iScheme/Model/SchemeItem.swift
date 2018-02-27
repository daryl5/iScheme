//
//  SchemeItem.swift
//  iScheme
//
//  Created by lingwan on 16/3/21.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import Cocoa
import Crashlytics

extension SchemeItem: Equatable {
    static func ==(lhs: SchemeItem, rhs: SchemeItem) -> Bool {
        guard let lhsItems = lhs.subItems, let rhsItems = rhs.subItems else {
            return lhs.title == rhs.title && lhs.scheme == rhs.scheme
        }
        
        guard lhsItems.count == rhsItems.count else {
            return false
        }
        
        return zip(lhsItems, rhsItems).enumerated().filter() { $1.0 != $1.1 }.count == 0
    }
}

final class SchemeItem: Codable {
    //plist
    var title: String {
        didSet {
            pinyin = title.pinyin()?.replacingOccurrences(of: " ", with: "")
        }
    }
    var pinyin: String? //for search
    
    var scheme: String
    var encodedScheme: String {
        return processCJK(scheme)
    }
    
    var subItems: [SchemeItem]?
    
    //codable
    private enum CodingKeys: String, CodingKey {
        case title
        case scheme
        case subItems
    }
    
    //assigned when loaded from file
    weak var parentItem: SchemeItem?
    
    //log scheme count
    var schemeCount: Int {
        return 1 + (subItems?.reduce(0) { $0 + $1.schemeCount } ?? 0)
    }
    
    var menuItem: NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: #selector(clickSchemeItem), keyEquivalent:"")
        menuItem.target = self
        if let count = subItems?.count, count > 0 {
            let submenu = NSMenu()
            for subScheme in subItems! {
                let submenuItem = subScheme.menuItem
                submenuItem.target = subScheme
                submenu.addItem(submenuItem)
            }
            
            menuItem.submenu = submenu
        }
        return menuItem
    }
    
    init() {
        self.title = ""
        self.scheme = ""
    }
    
    init(title: String, scheme: String) {
        self.title = title
        self.scheme = scheme
        
        defer {
            //trigger title's didSet
            self.title = title
        }
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
        scheme = try values.decode(String.self, forKey: .scheme)
        do {
            subItems = try values.decode([SchemeItem].self, forKey: .subItems)
            subItems?.forEach() { $0.parentItem = self }
        } catch {}
        
        defer {
            //trigger title's didSet
            let t = title
            title = t
        }
    }
    
    @objc func clickSchemeItem() {
        let commandClick = NSEvent.modifierFlags.contains(.command) && !NSEvent.modifierFlags.contains(.shift)
        if commandClick {
            Answers.logCustomEvent(withName: "Menu Click", customAttributes: ["Mode": ConfigCenter.sharedInstance.mode, "Action": "3-Scheme QR"])

            QRCodeViewer.qrCodeView.showWithTitle(title, content: encodedScheme)
            return
        }
        
        Answers.logCustomEvent(withName: "Menu Click", customAttributes: ["Mode": ConfigCenter.sharedInstance.mode, "Action": "2-Scheme"])
        fire()
    }
    
    @objc func fire() {
        guard !title.isEmpty && !scheme.isEmpty else {
            return
        }
        
        ClientManager.manager.fire(scheme: self)
    }
    
    private func processCJK(_ scheme: String) -> String {
        guard scheme.containsCJK() else {
            return scheme
        }
        
        let subs = scheme.components(separatedBy: "?")
        if subs.count == 2 {
            var newScheme: String = String(subs[0])
            newScheme.append(Character("?"))
            
            let params: String = subs[1]
            let paramsArray: Array = params.components(separatedBy: "&")
            for (index, param) in paramsArray.enumerated() {
                let kv: Array = param.components(separatedBy: "=")
                if kv.count == 2 {
                    var value = kv[1]
                    if value.containsCJK() {
                        value = value.addingPercentEncoding(withAllowedCharacters: CharacterSet())!
                    }
                    newScheme.append(kv[0] + "=" + value)
                    if index < paramsArray.count - 1 {
                        newScheme.append("&")
                    }
                } else {
                    newScheme.append(param)
                }
            }
            
            return newScheme
        }
        
        return scheme
    }
    
    //MARK: Dictionary convert
    
    func buildFromDict(_ itemInDic: [String: AnyObject]) {
        title = itemInDic["title"] as! String
        scheme = itemInDic["scheme"] as! String
        if let subItemsArray = itemInDic["subItems"] as? Array<[String: AnyObject]> {
            subItems = subItemsArray.map({ subItemInDict in
                let subItem = SchemeItem()
                subItem.buildFromDict(subItemInDict)
                subItem.parentItem = self
                return subItem
            })
        }
    }
    
    func convertToDict() -> [String: AnyObject] {
        var dict = [String: AnyObject]()
        dict["title"] = title as AnyObject
        dict["scheme"] = scheme as AnyObject
        
        if let items = subItems {
            dict["subItems"] = items.map { $0.convertToDict() } as AnyObject
        }
        
        return dict
    }
}
