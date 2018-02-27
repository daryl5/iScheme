//
//  NoTitleWindowController.swift
//  iScheme
//
//  Created by lingwan on 2016/12/10.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Cocoa

class NoTitleWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if let window = self.window {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
        }
    }
}
