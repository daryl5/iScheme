//
//  ListEditor.swift
//  iScheme
//
//  Created by lingwan on 16/3/2.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Cocoa
import Crashlytics

final class ListEditor: NoTitleWindowController {
    
    static let sharedInstance = ListEditor(windowNibName: "ListEditor")

    @IBOutlet private weak var outlineView: NSOutlineView!
    
    private let kEditPanelPasteBoardType = "kEditPanelPasteBoardType"

    private let sharedDataManager = DataManager.sharedInstance
    private var schemeInEditing: SchemeItem?
    
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var copyButton: NSButton!
    @IBOutlet weak var editButton: NSButton!
    @IBOutlet weak var moveTopButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        addButton.title = Localisation("EDIT_ADD")
        deleteButton.title = Localisation("EDIT_DELETE")
        copyButton.title = Localisation("EDIT_COPY")
        editButton.title = Localisation("EDIT_EDIT")
        moveTopButton.title = Localisation("EDIT_STICK")
        
        let columns = outlineView.tableColumns
        columns[0].title = Localisation("EDIT_TITLE")
        columns[1].title = Localisation("EDIT_SCHEME")
        
        outlineView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: kEditPanelPasteBoardType)])

        NotificationCenter.default.addObserver(self, selector: #selector(willClose), name: NSWindow.willCloseNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectionChanged), name: NSOutlineView.selectionDidChangeNotification, object: nil)
    }
    
    func show() {
        self.window?.center()
        self.showWindow(nil)
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        NSApp.activate(ignoringOtherApps: true)
        self.window?.orderFrontRegardless()
    }
    
    func reload() {
        if self.isWindowLoaded {
            outlineView.reloadData()
        }
    }
    
    func showWithEditingLast() {
        show()
        
        let last = outlineView.numberOfRows - 1
        outlineView.scrollRowToVisible(last)
        outlineView.editColumn(0, row: last, with: nil, select: true)
    }
    
    @objc private func willClose() {
        //防止添加完，编辑完，没有回车或者点击外面保存直接关闭编辑窗口
        if outlineView.selectedCell() != nil {
            sharedDataManager.saveSchemes()
        }
        
        outlineView.deselectAll(self)
    }
    
    @objc private func dataSourceChanged() {
        outlineView.reloadData()
    }
    
    @objc private func selectionChanged(_ notify: Notification) {
        let selectionValid = outlineView.selectedRow >= 0
        deleteButton.isEnabled = selectionValid
        copyButton.isEnabled = selectionValid
        editButton.isEnabled = selectionValid
        moveTopButton.isEnabled = selectionValid
    }
    
    @IBAction private func add(_ sender: AnyObject) {
        sharedDataManager.addScheme(SchemeItem(title: Localisation("UNTITLED"), scheme: kDefaultScheme))
        outlineView.reloadData()
        outlineView.scrollRowToVisible(outlineView.numberOfRows - 1)
    }
    
    @IBAction private func remove(_ sender: AnyObject) {
        let row = outlineView.selectedRow
        if row == -1 {
            return
        }
        
        sharedDataManager.removeScheme(outlineView.item(atRow: row) as! SchemeItem)
        outlineView.abortEditing()
        outlineView.reloadData()
    }
    
    @IBAction private func copyScheme(_ sender: AnyObject) {
        Answers.logCustomEvent(withName: "Edit Operation", customAttributes: ["Action": "1-Copy"])

        let item = outlineView.item(atRow: outlineView.selectedRow) as! SchemeItem
        sharedDataManager.addScheme(SchemeItem(title: item.title, scheme: item.scheme))
        outlineView.reloadData()
        outlineView.scrollRowToVisible(outlineView.numberOfRows - 1)
        outlineView.deselectAll(self)
    }
    
    @IBAction func editScheme(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "Edit Operation", customAttributes: ["Action": "3-Edit"])

        let item = outlineView.item(atRow: outlineView.selectedRow) as! SchemeItem
        BigbangEditor.sharedEditor.show(item)
    }
    
    @IBAction private func moveTop(_ sender: AnyObject) {
        let index = outlineView.selectedRow
        //选中的就是置顶的
        if index == 0 {
            return
        }
        
        Answers.logCustomEvent(withName: "Edit Operation", customAttributes: ["Action": "2-Stick"])
        
        let ret = sharedDataManager.moveItem(outlineView.item(atRow: index) as! SchemeItem, toItem: nil, atIndex: 0)
        if ret {
            outlineView.reloadData()
            outlineView.scrollRowToVisible(0)
            outlineView.deselectAll(self)
        }
    }
}

extension ListEditor: NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {

        return item == nil
            ? sharedDataManager.schemeItems.count
            : ((item as! SchemeItem).subItems?.count ?? 0)
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        return (item as! SchemeItem).subItems != nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        return item == nil
            ? sharedDataManager.schemeItems[index]
            : (item as! SchemeItem).subItems![index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        
        let schemeItem = item as! SchemeItem
        
        if (tableColumn?.identifier)!.rawValue == "title" {
            return schemeItem.title
        } else {
            return schemeItem.scheme
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, byItem item: Any?) {
        
        var content: String = object as! String
        //去掉复制粘贴带来的回车
        content = content.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let schemeItem = item as! SchemeItem
        
        if (tableColumn?.identifier)!.rawValue == "title" {
            if content == "" {
                content = Localisation("UNTITLED")
            }
            schemeItem.title = content
        } else {
            if content == "" {
                content = kDefaultScheme
            }
            //移除粘贴时auto-correct给加的空格
            content = content.replacingOccurrences(of: " ", with: "")
            schemeItem.scheme = content
        }
        
        sharedDataManager.saveSchemes()
    }
    
    //MARK: Drag & Drop
    
    func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
        
        outlineView.deselectAll(self)
        schemeInEditing = items[0] as? SchemeItem
        pasteboard.declareTypes([NSPasteboard.PasteboardType(rawValue: kEditPanelPasteBoardType)], owner: self)
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        
        //不允许把A拖到A的子scheme里；不允许把A的子item拖到A上
        if let scheme = item as? SchemeItem {
            if scheme === schemeInEditing! || (scheme === schemeInEditing!.parentItem && index == -1) {
                return NSDragOperation()
            }
        }
        
        return NSDragOperation.move
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        
        let ret = sharedDataManager.moveItem(schemeInEditing!, toItem: item as? SchemeItem, atIndex: index)
        if ret {
            outlineView.reloadData()
            outlineView.expandItem(item)
        }
        
        return true
    }
}
