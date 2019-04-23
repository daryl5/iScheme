//
//  QRCodeViewer.swift
//  iScheme
//
//  Created by lingwan on 16/3/3.
//  Copyright © 2016年 lingwan. All rights reserved.
//

import Cocoa

typealias QRCodeWindowOnClose = () throws -> ()

final class QRCodeViewer: NSWindowController {
    
    static let qrCodeView = QRCodeViewer(windowNibName: "QRCodeViewer")

    private var onCloseAction: QRCodeWindowOnClose?
    
    @IBOutlet private weak var qrImageView: NSImageView!
    
    private let qrCodeGenerator: CIFilter = {
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setDefaults()
        
        return filter!
    }()
    
    override func windowDidLoad() {
        super.windowDidLoad()
        qrImageView.wantsLayer = true
        qrImageView.layer?.magnificationFilter = CALayerContentsFilter.nearest
        let imageCell = qrImageView.cell as! NSImageCell
        imageCell.imageFrameStyle = NSImageView.FrameStyle.none
        
        NotificationCenter.default.addObserver(self, selector: #selector(willClose), name: NSWindow.willCloseNotification, object: nil)
    }

    func showWithTitle(_ title: String?, content: String, onClose: @escaping QRCodeWindowOnClose = {}) {
        
        self.window?.title = title ?? "iScheme"
        onCloseAction = onClose
        
        qrCodeGenerator.setValue(content.data(using: String.Encoding.utf8) , forKey: "inputMessage")
        
        let output = qrCodeGenerator.outputImage
        let scaleX = qrImageView.frame.size.width / output!.extent.size.width
        let scaleY = qrImageView.frame.size.height / output!.extent.size.height
        let transformed = output?.transformed(by: CGAffineTransform.init(scaleX: scaleX, y: scaleY))
        let image = NSImage()
        image.addRepresentation(NSCIImageRep(ciImage: transformed!))
        qrImageView.image = image
        
        self.window?.center()
        self.showWindow(nil)
        self.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        NSApp.activate(ignoringOtherApps: true)
        self.window?.orderFrontRegardless()
    }
    
    @objc private func willClose() {
        do {
            try onCloseAction?()
        } catch {
            print("QRCodeWindowOnClose error: \(error)")
        }
    }
}
