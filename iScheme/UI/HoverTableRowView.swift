//
//  HoverTableRowView.swift
//  iScheme
//
//  Created by lingwan on 2017/3/29.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation
import AppKit

protocol HoverTableRowViewDelegate: class {
    func mouseDidInsideRowView(at row:Int)
}

final class HoverTableRowView: NSTableRowView {
    weak var delegate: HoverTableRowViewDelegate?
    
    //set in tableView delegate
    var index: Int = -1
    
    //shouldTrackMouse = if mouse moved
    private var shouldTrackMouse = false
    
    private var _mouseInside: Bool = false
    private var mouseInside: Bool {
        set {
            if newValue != _mouseInside {
                _mouseInside = newValue
                self.setNeedsDisplay(bounds)
                
                //select this row
                if _mouseInside {
                    delegate?.mouseDidInsideRowView(at: index)
                }
                
                //show/hide button view
                guard subviews.count > 0, let cellView = subviews[0] as? HoverTableCellView else {
                    return
                }
                cellView.updateButtonView(hidden: !_mouseInside)
            }
        }
        get {
            return _mouseInside
        }
    }
    
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        trackingArea = trackingArea ?? NSTrackingArea.init(rect: NSRect.zero, options: [.inVisibleRect, .activeAlways, .mouseEnteredAndExited, .mouseMoved], owner: self, userInfo: nil)
        
        if !trackingAreas.contains(trackingArea!) {
            self.addTrackingArea(trackingArea!)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mouseInside = false
        shouldTrackMouse = false
    }
    
    override func mouseEntered(with event: NSEvent) {
        shouldTrackMouse = true
    }
    
    override func mouseMoved(with event: NSEvent) {
        mouseInside = shouldTrackMouse
    }
    
    override func mouseExited(with event: NSEvent) {
        shouldTrackMouse = false
        mouseInside = false
    }
    
    override func drawBackground(in dirtyRect: NSRect) {
        if mouseInside {
            NSColor(calibratedWhite: 0.82, alpha: 1).setFill()
            __NSRectFill(bounds)
        }
    }
}
