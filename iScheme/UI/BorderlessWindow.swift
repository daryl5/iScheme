//
//  BorderlessWindow.swift
//  iScheme
//
//  Created by Sleen on 16/6/21.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Foundation
import Cocoa

class BorderlessWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}
