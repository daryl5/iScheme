//
//  Spotlight.swift
//  iScheme
//
//  Created by Sleen on 16/6/21.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import Cocoa
import Carbon
import Crashlytics

private let kCellHeight: CGFloat = 42
private let kDefaultTextTableSpace: CGFloat = 12

final class Spotlight: NSWindowController {
    
    static let sharedInstance: Spotlight = Spotlight(windowNibName: NSNib.Name(rawValue: "Spotlight"))

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var textTableSpace: NSLayoutConstraint!
    
    @IBOutlet weak var schemeTextFiled: NSTextField!
    @IBOutlet weak var addSchemeButton: NSButton!
    @IBOutlet weak var editSchemeButton: NSButton!
    
    private func updateButtonHidden(by input: String) {
        let isHidden = input.isEmpty
        addSchemeButton.isHidden = isHidden
        editSchemeButton.isHidden = isHidden
    }
    
    var searchResult: [SchemeItem] = []
    
    private var _flattenedSchemes = [SchemeItem]()
    private var flattenedSchemes: [SchemeItem] {
        return _flattenedSchemes.count > 0 ? _flattenedSchemes : {
            flattenSchemes(DataManager.sharedInstance.schemeItems)
            return _flattenedSchemes
        }()
    }
    private func flattenSchemes(_ items: [SchemeItem]) {
        items.forEach { item in
            _flattenedSchemes.append(item)
            if let subItems = item.subItems {
                flattenSchemes(subItems)
            }
        }
    }
    private func clearSchemesCache() {
        _flattenedSchemes.removeAll()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.isMovableByWindowBackground = true
        
        schemeTextFiled.placeholderString = Localisation("QUICK_JUMP_TIP")
        schemeTextFiled.delegate = self
        schemeTextFiled.superview?.wantsLayer = true
        schemeTextFiled.superview?.layer?.cornerRadius = 5
        schemeTextFiled.superview?.layer?.backgroundColor = NSColor.init(red: 0.96, green: 0.96, blue: 0.96, alpha: 0.96).cgColor
        
        NotificationCenter.default.addObserver(self, selector: #selector(lostFocus), name: NSWindow.didResignMainNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(gotFocus), name: NSWindow.didBecomeMainNotification, object: nil)
    }
    
    @objc func gotFocus() {
        schemeTextFiled?.selectText(nil)
    }
    
    @objc func lostFocus() {
        close()
        clearSchemesCache()
    }
    
    func show(_ text:String?) {
        guard let window = self.window, let mainScreen = NSScreen.main else {
            return
        }
        
        //再次打开时如果有关键词，则刷新搜索结果
        if !schemeTextFiled.stringValue.isEmpty {
            search(by: schemeTextFiled.stringValue)
        } else {
            //trigger window layout
            updateTableViewState()
        }
        
        window.backgroundColor = NSColor.init(red: 0, green: 0, blue: 0, alpha: 0)
        window.center()
        window.setFrameTopLeftPoint(NSPoint.init(x: self.window!.frame.origin.x, y: mainScreen.frame.size.height/5*4))
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        window.orderFrontRegardless()
        self.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func search(by keyword: String) {
        guard !keyword.isEmpty else {
            searchResult = []
            updateTableViewState()
            return
        }
        
        DispatchQueue.global().async { [weak self] in
            let ret = self?.flattenedSchemes.filter { $0.title.fuzzyMatch(keyword) || ($0.pinyin?.fuzzyMatch(keyword) ?? false) }
            guard let result = ret else {
                return
            }
            
            self?.searchResult = result.count >= 8 ? Array(result[0..<8]) : result
            
            DispatchQueue.main.async {
                self?.updateTableViewState()
            }
        }
    }
    
    private func updateTableViewState(animate: Bool = false) {
        tableView.reloadData()
        
        textTableSpace.constant = searchResult.count > 0 ? kDefaultTextTableSpace : 0
        
        let height = CGFloat(12 + 22 + ((searchResult.count > 0) ? kDefaultTextTableSpace : 0) + 12)
        let listHeight = CGFloat(searchResult.count) * kCellHeight
        let newHeight = CGFloat(height + listHeight)
        
        var newFrame = tableView.frame
        newFrame.size.height = listHeight
        tableView.frame = newFrame
        
        var windowFrame = window!.frame
        windowFrame.origin.y += windowFrame.size.height - newHeight;
        windowFrame.size.height = newHeight
        window?.setFrame(windowFrame, display: true, animate: animate)
    }
    
    @IBAction func addInputScheme(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "Quick Jump", customAttributes: ["Action": "3-Add"])

        DataManager.sharedInstance.addScheme(SchemeItem(title: Localisation("UNTITLED"), scheme: schemeTextFiled.stringValue))
        let editPanel = ListEditor.sharedInstance
        editPanel.reload()
        editPanel.showWithEditingLast()
        
        close()
    }
    
    @IBAction func editInputScheme(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "Quick Jump", customAttributes: ["Action": "4-Edit"])

        let scheme = SchemeItem(title: Localisation("UNTITLED"), scheme: schemeTextFiled.stringValue)
        BigbangEditor.sharedEditor.show(scheme, isAdding: true)
    }
    
    @IBAction private func qrCodeOnCell(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "Search Result Action", customAttributes: ["Action": "1-Scheme QR"])

        let scheme = searchResult[tableView.row(for: sender)]
        QRCodeViewer.qrCodeView.showWithTitle(scheme.title, content: scheme.scheme)
        close()
    }
    
    @IBAction private func copyOnCell(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "Search Result Action", customAttributes: ["Action": "2-Copy"])

        let scheme = searchResult[tableView.row(for: sender)]
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(scheme.scheme, forType: NSPasteboard.PasteboardType.string)
        close()
    }
    
    @IBAction private func editOnCell(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "Search Result Action", customAttributes: ["Action": "3-Edit"])

        let scheme = searchResult[tableView.row(for: sender)]
        BigbangEditor.sharedEditor.show(scheme)
        close()
    }
    
    @IBAction private func stickOnCell(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "Search Result Action", customAttributes: ["Action": "4-Stick"])

        let scheme = searchResult[tableView.row(for: sender)]
        DataManager.sharedInstance.moveItem(scheme, toItem: nil, atIndex: 0)
        ListEditor.sharedInstance.reload()
        close()
    }
}

//MARK: -
//MARK: TableView

extension Spotlight: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return searchResult.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellIdentifier = "kSpotlightCellIdentifier"
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: self) {
            if let label = cell.viewWithTag(0) as? NSTextField {
                label.stringValue = searchResult[row].title
            }
            
            if let scheme = cell.viewWithTag(1) as? NSTextField {
                scheme.stringValue = searchResult[row].scheme
                //default hidden
                scheme.isHidden = true
            }
            
            return cell
        }
        
        return nil
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let identifier = "kSpotlightRowViewIdentifier"
        var rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), owner: self) as? HoverTableRowView
        
        if rowView == nil {
            rowView = HoverTableRowView.init()
            rowView?.identifier = NSUserInterfaceItemIdentifier(rawValue: identifier)
        }
        
        rowView?.delegate = self
        rowView?.index = row
        
        return rowView
    }
    
    @IBAction func tableViewSingleClick(_ sender: NSTableView) {
        //command+Enter for qr-code
        if NSEvent.modifierFlags.contains(.command) {
            Spotlight.commandSchemeAction(self)
        } else {
            Spotlight.normalSchemeAction(self)
        }
    }
}

//MARK: -
//MARK: HoverTableRowViewDelegate

extension Spotlight: HoverTableRowViewDelegate {
    func mouseDidInsideRowView(at row: Int) {
        tableView.selectRowIndexes(IndexSet.init(integer: row), byExtendingSelection: false)
    }
}

//MARK: -
//MARK: NSTextFieldDelegate

extension Spotlight: NSTextFieldDelegate {
    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        //command+Enter for qr-code
        if NSEvent.modifierFlags.contains(.command) && (commandSelector == NSSelectorFromString("noop:")) {
            Spotlight.commandSchemeAction(self)
            return true
        }
        
        //enter
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            Spotlight.normalSchemeAction(self)
            return true
        }
        
        //down
        if (commandSelector == #selector(NSResponder.moveDown(_:))) {
            tableView.selectRowIndexes(IndexSet.init(integer: tableView.selectedRow + 1), byExtendingSelection: false)
            return true
        }
        //up
        else if (commandSelector == #selector(NSResponder.moveUp(_:))) {
            tableView.selectRowIndexes(IndexSet.init(integer: tableView.selectedRow - 1), byExtendingSelection: false)
            return true
        }
        
        return false
    }
    
    public override func controlTextDidChange(_ obj: Notification) {
        let input = (obj.object as! NSTextField).stringValue
        updateButtonHidden(by: input)
        search(by: input)
    }
}

//MARK: -
//MARK: Actions

extension Spotlight {
    private static let commandSchemeAction: (Spotlight) -> Void = { instance in
        instance.close()
        
        instance.getSchemeThen(do: { scheme in
            Answers.logCustomEvent(withName: "Quick Jump", customAttributes: ["Action": "2-Generate QR"])
            QRCodeViewer.qrCodeView.showWithTitle(nil, content: scheme)
        })
    }
    
    private static let normalSchemeAction: (Spotlight) -> Void = { instance in
        instance.close()
        
        instance.getSchemeThen(do: { scheme in
            Answers.logCustomEvent(withName: "Quick Jump", customAttributes: ["Action": "1-Jump"])
            let schemeItem = SchemeItem(title: "iScheme", scheme: scheme)
            schemeItem.fire()
        })
    }
    
    private func getSchemeThen(do action:(String) -> Void) {
        var scheme: String
        if searchResult.count > 0 && tableView.selectedRow >= 0 {
            scheme = searchResult[tableView.selectedRow].scheme
        } else {
            scheme = schemeTextFiled.stringValue.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        
        if (!scheme.isEmpty) {
            action(scheme)
        }
    }
}
