//
//  DataManager.swift
//  iScheme
//
//  Created by lingwan on 16/3/3.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Cocoa

//Notification
let kRebuildMenuNotification = "kRebuildMenuNotification"

//初始/默认 scheme
let kDefaultScheme = "https://www.google.com"

final class DataManager {
    static let sharedInstance = DataManager()
    
    private var jsonFilePath: String {
        return "file://" + NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/Schemes.json"
    }
    private let configCenter = ConfigCenter.sharedInstance

    var schemeItems: Array<SchemeItem> = []
    
    //Log scheme count
    var schemeCount: Int {
        return schemeItems.reduce(0) { $0 + $1.schemeCount }
    }

    init() {
        loadSchemes()
        NotificationCenter.default.post(name: Notification.Name(rawValue: kRebuildMenuNotification), object: nil)
    }
    
    func saveSchemes() {
        writeToFile(schemes: schemeItems)
        NotificationCenter.default.post(name: Notification.Name(rawValue: kRebuildMenuNotification), object: nil)
    }
    
    private func loadSchemes() {
        //json
        if let url = URL.init(string: jsonFilePath) {
            do {
                schemeItems = try JSONDecoder().decode([SchemeItem].self, from: Data.init(contentsOf: url))
                //数据被删除完了
                if (schemeItems.count == 0) {
                    writeInitData()
                }
                
                //read json succeed, return
                return
            } catch {}
        }
        
        //plist
        let plistPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/Schemes.plist"
        if let items = NSMutableArray.init(contentsOfFile: plistPath) {
            //0是fileVersion
            items.removeObject(at: 0);
            for item in items {
                let schemeItem = SchemeItem()
                schemeItem.buildFromDict(item as! [String : AnyObject])
                schemeItems.append(schemeItem)
            }
            
            //把plist转化为json文件；删除plist
            writeToFile(schemes: schemeItems)
            do {
                try FileManager.default.removeItem(atPath: plistPath)
            } catch {}
        } else {
            //如果没写过初始数据就写入默认数据
            writeInitData()
        }
    }
    
    private func writeInitData() {
        schemeItems = [SchemeItem(title: Localisation("INIT_SCHEME"), scheme: kDefaultScheme)]
        writeToFile(schemes: schemeItems)
    }
    
    private func writeToFile(schemes: [SchemeItem]) {
        do {
            let data = try JSONEncoder().encode(schemes)
            let string = String(decoding: data, as: UTF8.self)
            if let fileURL = URL.init(string: jsonFilePath) {
                try string.write(to: fileURL, atomically: false, encoding: .utf8)
            }
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            
            let alert = NSAlert()
            alert.alertStyle = NSAlert.Style.informational
            alert.messageText = Localisation("WRITE_FILE_ERROR")
            alert.runModal()
            alert.window.becomeKey()
        }
    }
}

//MARK: -
//MARK: 编辑
extension DataManager {
    func addScheme(_ item: SchemeItem) {
        schemeItems.append(item)
        saveSchemes()
    }
    
    func removeScheme(_ item: SchemeItem) {
        if item.parentItem == nil {
            if let index = schemeItems.index(of: item) {
                schemeItems.remove(at: index)
                saveSchemes()
            }
            return
        }
        
        let parent = item.parentItem!
        parent.subItems!.remove(at: (parent.subItems!.index(of: item))!)
        if parent.subItems!.count == 0 {
            parent.subItems = nil
        }
        saveSchemes()
    }
    
    @discardableResult func moveItem(_ item: SchemeItem, toItem parentItem: SchemeItem?, atIndex index: Int) -> Bool {
        let outer2outer = (item.parentItem == nil) && (parentItem == nil)
        let sub2sameSub: Bool = {
            if let parent1 = item.parentItem, let parent2 = parentItem {
                if parent1 === parent2 {
                    return true
                }
            }
            return false
        }()
        
        //同层级拖移：最外层拖移；一个item的子item内拖移
        if outer2outer {
            let fromIndex = schemeItems.index(of: item)
            if fromIndex == nil || fromIndex == index || fromIndex == index - 1 {
                return false
            }
            schemeItems.moveItem(fromIndex!, toIndex: index)
        } else if sub2sameSub {
            let fromIndex = item.parentItem!.subItems!.index(of: item)
            if fromIndex == nil || fromIndex == index || fromIndex == index - 1 {
                return false
            }
            item.parentItem!.subItems!.moveItem(fromIndex!, toIndex: index)
        }
        //跨层级移动：里到最外，里到另一个的里，外到里
        else {
            //有parentItem，代表插入到新的parent里
            if let toParent = parentItem {
                if index == -1 {
                    if toParent.subItems == nil {
                        toParent.subItems = []
                    }
                    toParent.subItems?.append(item)
                } else {
                    toParent.subItems?.insert(item, at: index)
                }
            }
            //没有parentItem，代表拖到最外层
            else {
                schemeItems.insert(item, at: index)
            }
            
            //从旧的里移出
            var fromIndex: Int?
            //原本是里层的，有parent
            if let fromParent = item.parentItem {
                fromIndex = fromParent.subItems!.index(of: item)
                if fromIndex == nil {
                    return false
                }
                fromParent.subItems!.remove(at: fromIndex!)
                if fromParent.subItems?.count == 0 {
                    fromParent.subItems = nil
                }
            }
            //原本就是最外层的
            else {
                fromIndex = schemeItems.index(of: item)
                if fromIndex == nil {
                    return false
                }
                schemeItems.remove(at: fromIndex!)
            }
            
            //设置parent
            item.parentItem = parentItem
        }
        
        saveSchemes()
        
        return true
    }
}

extension Array where Iterator.Element == SchemeItem {
    mutating func moveItem(_ fromIndex: Int, toIndex: Int) {
        var toIndex = toIndex
        if fromIndex < toIndex {
            toIndex -= 1
        }
        
        let object = self[fromIndex]
        self.remove(at: fromIndex)
        self.insert(object, at: toIndex)
    }
}
