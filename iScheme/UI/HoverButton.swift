//
//  HoverButton.swift
//  iScheme
//
//  Created by lingwan on 2017/3/31.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation
import AppKit

final class HoverButton: NSButton {
    private var trackingArea: NSTrackingArea?
    
    override var intrinsicContentSize: NSSize {
        return NSMakeSize(4 + super.intrinsicContentSize.width + 4, super.intrinsicContentSize.height)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        trackingArea = trackingArea ?? NSTrackingArea.init(rect: NSRect.zero, options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved], owner: self, userInfo: nil)
        
        if !trackingAreas.contains(trackingArea!) {
            self.addTrackingArea(trackingArea!)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        layer?.cornerRadius = 5
        layer?.borderColor = NSColor.init(white: 0.98, alpha: 0.8).cgColor
        layer?.borderWidth = 1
    }
    
    override func mouseExited(with event: NSEvent) {
        layer?.borderWidth = 0
    }
}
