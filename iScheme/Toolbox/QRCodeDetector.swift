//
//  QRCodeDetector.swift
//  iScheme
//
//  Created by lingwan on 16/6/23.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Cocoa
import Carbon

typealias QrCodeInfo = (str:String, image:NSImage, bounds:NSRect)

final class HighlightWindow: NSWindow, CAAnimationDelegate {
    private var qrs = [QrCodeInfo]()
    static var windows = [NSWindow]()
    
    private class HighlightLayer: CALayer {
        @objc var progress = 0.0
        var highlightRects = [NSRect]()
        var a = 0.0
        
        override init(layer: Any) {
            super.init(layer: layer)
            if let l = layer as? HighlightLayer {
                highlightRects = l.highlightRects
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override init() {
            super.init()
        }
        
        override func draw(in ctx: CGContext) {
            a += 1.0
            NSGraphicsContext.saveGraphicsState()
            let context = NSGraphicsContext(cgContext: ctx, flipped: true)
            NSGraphicsContext.current = context
            
            let path = NSBezierPath(rect: self.bounds)
            for r in self.highlightRects {
                let mix = {(a:CGFloat, b:CGFloat, percentage:Double) -> CGFloat in a + (b - a) * CGFloat(percentage)}
                let mixRect = {(a:NSRect, b:NSRect, percentage:Double) -> NSRect in
                    return NSRect(
                        x: mix(a.origin.x, b.origin.x, percentage), 
                        y: mix(a.origin.y, b.origin.y, percentage), 
                        width: mix(a.size.width, b.size.width, percentage), 
                        height: mix(a.size.height, b.size.height, percentage))
                }
                let rect = mixRect(self.bounds, r, progress)
                let clipPath = NSBezierPath(rect: self.bounds)
                clipPath.appendRect(rect)
                clipPath.windingRule = .evenOddWindingRule
                clipPath.addClip()
            }
            NSColor(white: 0, alpha: 0.4 * CGFloat(progress)).set()
            path.fill()
            
            NSGraphicsContext.restoreGraphicsState()
        }
        
        override class func needsDisplay(forKey key: String) -> Bool {
            if (key == "progress") {
                return true
            }
            return super.needsDisplay(forKey: key)
        }
    }
    
    override init(contentRect: NSRect, styleMask aStyle: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: aStyle, backing: bufferingType, defer: flag)
        HighlightWindow.windows.append(self)
    }
    
    static func closeAll() {
        HighlightWindow.windows.forEach{$0.close()}
        HighlightWindow.windows.removeAll()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if (flag) {
            super.close()
        }
    }
    
    override func close() {
        self.ignoresMouseEvents = true
        let fadeOut = CABasicAnimation(keyPath: "opacity")
        fadeOut.duration = 0.12
        fadeOut.fromValue = 1
        fadeOut.toValue = 0
        fadeOut.fillMode = kCAFillModeBackwards
        fadeOut.isRemovedOnCompletion = false
        fadeOut.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        fadeOut.delegate = self
        self.contentView?.layer?.add(fadeOut, forKey: nil)
    }
    
    func setQrCodes(_ qrs: [QrCodeInfo], singleMode: Bool) {
        self.isReleasedWhenClosed = false
        self.isOpaque = false
        self.level = NSWindow.Level(rawValue: cStatusWindow)
        self.backgroundColor = NSColor.clear
        self.contentView!.wantsLayer = true
        self.contentView!.subviews.forEach{$0.removeFromSuperview()}
        self.contentView!.layer!.sublayers?.forEach{$0.removeFromSuperlayer()}
        let highlightLayer = HighlightLayer()
        highlightLayer.frame = self.contentView!.bounds
        highlightLayer.highlightRects = qrs.map{$0.bounds}
        self.contentView?.layer?.addSublayer(highlightLayer)
        highlightLayer.progress = 1
        let highlightAnimation = CABasicAnimation(keyPath: "progress")
        highlightAnimation.duration = 0.2
        highlightAnimation.fromValue = 0.0
        highlightAnimation.toValue = 1.0
        highlightAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        highlightLayer.add(highlightAnimation, forKey: "")
        
        self.qrs = qrs
        for n in 0..<qrs.count {
            let qr = qrs[n]
            let buttons = [(Localisation("SCREEN_QR_JUMP"), #selector(jumpButtonClicked(_:))), (Localisation("SCREEN_QR_COPY"), #selector(copyButtonClicked(_:)))]
            let buttonSize = CGFloat(qr.bounds.width) / (CGFloat(buttons.count) + (CGFloat(buttons.count) + 1.0) * 0.2)
            let spacing = buttonSize * 0.2
            
            for i in 0..<buttons.count {
                let button = NSButton(frame: NSMakeRect(qr.bounds.origin.x + spacing * (CGFloat(i)+1) + buttonSize * CGFloat(i), qr.bounds.origin.y + (qr.bounds.height - buttonSize) / 2, buttonSize, buttonSize))
                button.layer?.anchorPoint = NSMakePoint(0.5, 0.5)
                let style = NSMutableParagraphStyle()
                style.alignment = .center
                button.attributedTitle = NSAttributedString(string: buttons[i].0, attributes: [NSAttributedStringKey.foregroundColor:NSColor.white, NSAttributedStringKey.font:NSFont.systemFont(ofSize: buttonSize * 0.3), NSAttributedStringKey.paragraphStyle:style])
                button.setButtonType(.momentaryChange)
                button.wantsLayer = true
                button.layer?.backgroundColor = NSColor(white: 0, alpha: 0.8).cgColor
                button.layer?.cornerRadius = buttonSize / 2
                button.layer?.masksToBounds = true
                button.isBordered = false
                button.layer?.opacity = 0
                button.tag = n
                button.target = self
                button.action = buttons[i].1
                self.contentView!.addSubview(button)
                
                let fadeIn = CABasicAnimation(keyPath: "opacity")
                fadeIn.beginTime = CACurrentMediaTime() + Double(i) * 0.05 + 0.2
                fadeIn.duration = 0.15
                fadeIn.fromValue = 0
                fadeIn.toValue = 1
                fadeIn.isRemovedOnCompletion = false
                fadeIn.fillMode = kCAFillModeForwards
                fadeIn.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                button.layer?.add(fadeIn, forKey: "")
                
                let move = CABasicAnimation(keyPath: "position.y")
                move.beginTime = CACurrentMediaTime() + Double(i) * 0.05 + 0.2
                move.duration = 0.15
                move.fromValue = button.frame.origin.y - buttonSize * 0.6
                move.toValue = button.frame.origin.y
                move.isRemovedOnCompletion = false
                move.fillMode = kCAFillModeForwards
                move.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                button.layer?.add(move, forKey: "")
            }
        }
    }
    
    @objc private func jumpButtonClicked(_ button: NSButton) {
        HighlightWindow.closeAll()
        let scheme = qrs[button.tag].str
        if (NSEvent.modifierFlags.contains(.command)) {
            Spotlight.sharedInstance.show(scheme)
        } else {
            let schemeItem = SchemeItem.init(title: "iScheme", scheme: scheme)
            schemeItem.fire()
        }
    }
    
    @objc private func copyButtonClicked(_ button: NSButton) {
        HighlightWindow.closeAll()
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([qrs[button.tag].str as NSPasteboardWriting])
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        for qr in qrs {
            if (qr.bounds.contains(theEvent.locationInWindow)) {
                return
            }
        }
        HighlightWindow.closeAll()
    }
}

@available(OSX 10.10, *)
class QRCodeDetector {
    private var highlightWindow = HighlightWindow(contentRect: NSZeroRect, styleMask: NSWindow.StyleMask(rawValue: UInt(0)), backing: .buffered, defer: false)
    private var highlightWindows = [HighlightWindow]()
    
    @available(OSX 10.10, *)
    func decodeQr() {
        let qrInScreens = detectQr()
        let count = qrInScreens.reduce(0, {$0 + $1.count})
        
        if count == 0 {
            NSApp.activate(ignoringOtherApps: true)
            
            let alert = NSAlert()
            alert.alertStyle = NSAlert.Style.informational
            alert.messageText = Localisation("SCREEN_QR_NO")
            alert.runModal()
            alert.window.becomeKey()
        } else {
            highlightWindows.removeAll()
            for i in 0..<qrInScreens.count {
                let screen = NSScreen.screens[i]
                var qrs = qrInScreens[i]
                qrs = qrs.map {
                    var qr = $0
                    qr.bounds.origin.x /= screen.backingScaleFactor
                    qr.bounds.origin.y /= screen.backingScaleFactor
                    qr.bounds.size.width /= screen.backingScaleFactor
                    qr.bounds.size.height /= screen.backingScaleFactor
                    return qr
                }
                
                let window = HighlightWindow(contentRect: screen.frame, styleMask: NSWindow.StyleMask(rawValue: UInt(0)), backing: .buffered, defer: false)
                window.setQrCodes(qrs, singleMode: count == 1)
                window.setIsVisible(true)
                highlightWindows.append(window)
            }
        }
    }
    
    private func detectQr() -> [[QrCodeInfo]] {
        var	dspCount:CGDisplayCount = 0
        
        /* How many active displays do we have? */
        if CGGetActiveDisplayList(0, nil, &dspCount) != .success {
            return []
        }
        
        /* Allocate enough memory to hold all the display IDs we have. */
        let displays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: Int(dspCount))
        defer {
            displays.deallocate(capacity: Int(dspCount))
        }
        
        // Get the list of active displays
        if CGGetActiveDisplayList(dspCount, displays, &dspCount) != .success {
            return []
        }
        
        return (0..<Int(dspCount)).map{
            let cgImage = CGDisplayCreateImage(displays[$0])
            let ciImage = CIImage(cgImage: cgImage!)
            let detector = CIDetector.init(ofType: CIDetectorTypeQRCode, context: nil, options: nil)
            return detector!.features(in: ciImage).map{
                let qr = $0 as! CIQRCodeFeature
                let qrImage = ciImage.cropped(to: qr.bounds)
                let rep = NSCIImageRep(ciImage: qrImage)
                let nsImage = NSImage(size: rep.size)
                nsImage.addRepresentation(rep)
                return (str:qr.messageString!, image:nsImage, bounds:qr.bounds)
            }
        }
    }
}
