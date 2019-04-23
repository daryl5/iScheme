//
//  HoverTableCellView.swift
//  iScheme
//
//  Created by lingwan on 2017/4/1.
//  Copyright © 2017年 lingwan. All rights reserved.
//

import Foundation
import AppKit

final class HoverTableCellView: NSTableCellView {
    let buttonTitles = [Localisation("SEARCH_RESULT_QR"), Localisation("SEARCH_RESULT_COPY"), Localisation("SEARCH_RESULT_EDIT"), Localisation("SEARCH_RESULT_STICK")]
    var buttons: [NSButton]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        buttons = [10, 11, 12, 13].map() { viewWithTag($0) as! NSButton }
        //initial hidden
        buttons.forEach() { $0.isHidden = true }
        
        //localisation
        buttons.enumerated().forEach() { (index, button) in
            button.title = buttonTitles[index]
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        updateButtonView(hidden: true)
    }
    
    func updateButtonView(hidden: Bool) {
        let textField = viewWithTag(1)
        if let schemeTextField = textField as? NSTextField {
            schemeTextField.isHidden = hidden
            marquee(schemeTextField, hidden)
        }
        
        buttons.forEach() { $0.isHidden = hidden }
    }
    
    func marquee(_ textField: NSTextField, _ hidden: Bool) {
        if hidden {
            textField.layer?.removeAllAnimations()
        } else {
            let contentWidth = CGFloat.init(ceil(textField.stringValue.width(font: textField.font!))) + 2
            //adjust textFiled width with it's content size
            textField.frame.size.width = contentWidth
            
            guard let containerWidth = textField.superview?.frame.width, contentWidth >= containerWidth else {
                return
            }

            let distance = contentWidth - containerWidth
            let animation = CABasicAnimation.init(keyPath: "position.x")
            animation.fromValue = 0
            animation.toValue = -distance
            animation.beginTime = CACurrentMediaTime() + 0.8
            animation.duration = CFTimeInterval.init(distance / 80)
            animation.isRemovedOnCompletion = false
            animation.fillMode = CAMediaTimingFillMode.forwards
            textField.layer?.add(animation, forKey: "position.x")
        }
    }
}

extension String {
    func width(font: NSFont) -> CGFloat {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font])
        return boundingBox.width
    }
}
