//
//  BigbangEditor.swift
//  iScheme
//
//  Created by lingwan on 2017/5/11.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation
import AppKit
import Crashlytics

final class BigbangEditor: NoTitleWindowController {
    
    static let sharedEditor = BigbangEditor(windowNibName: "BigbangEditor")
    
    @IBOutlet weak var titleTextField: NSTextField!
    @IBOutlet weak var tokenField: NSTokenField!
    
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var jumpButton: NSButton!
    
    private var editingScheme: SchemeItem!
    private var isAdding: Bool = false
    
    private var editingText: String? {
        if let fragments = tokenField.objectValue as? [String.Fragment], fragments.count > 0 {
            return fragments.map { $0.associated() }.joined()
        }
        return nil
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        tokenField.delegate = self
        
        deleteButton.title = Localisation("BIGBANG_DELETE")
        saveButton.title = Localisation("BIGBANG_SAVE")
        jumpButton.title = Localisation("BIGBANG_JUMP")
    }
    
    func show(_ schemeItem: SchemeItem, isAdding: Bool = false) {
        guard let window = self.window else {
            return
        }
        
        editingScheme = schemeItem
        self.isAdding = isAdding
        
        titleTextField.stringValue = schemeItem.title
        tokenField.objectValue = schemeItem.scheme.bigbang()
        tokenField.becomeFirstResponder()
        tokenField.currentEditor()?.selectedRange = NSRange.init(location: Int.max, length: 0)

        window.center()
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        window.orderFrontRegardless()
        self.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func delete(_ sender: NSButton) {
        DataManager.sharedInstance.removeScheme(editingScheme)
        close()
    }
    
    @IBAction private func save(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "BigBang Action", customAttributes: ["Action": "1-Save"])

        guard let newText = editingText, !newText.isEmpty else {
            close()
            return
        }
        
        editingScheme.title = titleTextField.stringValue
        editingScheme.scheme = newText
        
        if isAdding {
            DataManager.sharedInstance.addScheme(editingScheme)
            let editPanel = ListEditor.sharedInstance
            editPanel.reload()
            editPanel.showWithEditingLast()
        } else {
            DataManager.sharedInstance.saveSchemes()
        }
        
        close()
    }
    
    @IBAction private func jump(_ sender: NSButton) {
        Answers.logCustomEvent(withName: "BigBang Action", customAttributes: ["Action": "2-Jump"])

        if let str = editingText {
            SchemeItem.init(title: editingScheme.title, scheme: str).fire()
        }
    }
}

extension BigbangEditor: NSTokenFieldDelegate {
    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {

        if let fragment = representedObject as? String.Fragment {
            return fragment.associated()
        } else if let fragments = representedObject as? [String.Fragment] {
            return fragments[0].associated()
        }
        return nil
    }
    
    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any? {
        return editingString.bigbang()
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        
        return tokens.flatMap({ (token) -> [String.Fragment] in
            if let fragments = token as? [String.Fragment] {
                return fragments
            } else if let fragment = token as? String.Fragment {
                return [fragment]
            }
            return []
        })
    }
    
    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenField.TokenStyle {
        
        guard let fragment = representedObject as? String.Fragment else {
            return .default
        }
        
        switch fragment {
            case .normal:
                return .default
            case .seperator:
                return .squared
        }
    }
    
    func tokenField(_ tokenField: NSTokenField, writeRepresentedObjects objects: [Any], to pboard: NSPasteboard) -> Bool {
        
        let ret = objects.reduce("") { (result, item) -> String in
            //copy plain text
            if let fragments = item as? Array<String.Fragment> {
                return result + fragments[0].associated()
            }
            //copy fragment directly
            else if let fragment = item as? String.Fragment {
                return result + fragment.associated()
            }
            return ""
        }
        
        pboard.clearContents()
        pboard.writeObjects([ret] as [NSPasteboardWriting])
        
        return true
    }
    
    public func tokenField(_ tokenField: NSTokenField, readFrom pboard: NSPasteboard) -> [Any]? {
        
        let ret = pboard.pasteboardItems?.reduce("") { (result, item) -> String in
            guard let str = item.string(forType: NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text")) else {
                return result
            }
            return result + str
        } ?? ""
        
        return ret.isEmpty ? nil : ret.bigbang()
    }
}
