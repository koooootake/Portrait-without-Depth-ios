//
//  CustomButton.swift
//  Portrait
//
//  Created by Rina Kotake on 2019/03/17.
//  Copyright © 2019 koooootake. All rights reserved.
//

import UIKit

@IBDesignable
final class CustomButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 4 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

    @IBInspectable var borderWidth: CGFloat = 1 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }

    @IBInspectable var borderColor: UIColor? {
        didSet {
            layer.borderColor = borderColor?.cgColor
        }
    }

    @IBInspectable var topEdge: CGFloat = 2
    @IBInspectable var leftEdge: CGFloat = 8
    @IBInspectable var bottomEdge: CGFloat = 2
    @IBInspectable var rightEdge: CGFloat = 8

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height += topEdge + bottomEdge
        size.width += leftEdge + rightEdge
        return size
    }

    @IBInspectable var isScaleAspectFit: Bool = true {
        didSet {
            imageView?.contentMode = .scaleAspectFit
        }
    }
}
