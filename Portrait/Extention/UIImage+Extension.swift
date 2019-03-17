//
//  UIImage+Extension.swift
//  Portrait
//
//  Created by Rina Kotake on 2019/02/27.
//  Copyright © 2019 koooootake. All rights reserved.
//

import Foundation

extension UIImage {

    func resize(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        draw(in:CGRect(origin: CGPoint.zero, size: size))
        let reSizeImage: UIImage! = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return reSizeImage;
    }

    func scale(ratio: CGFloat) -> UIImage {
        let size = CGSize(width: self.size.width * ratio, height: self.size.height * ratio)
        return resize(size: size)
    }

    func cropping(to: CGRect) -> UIImage? {
        var opaque = false
        if let cgImage = cgImage {
            switch cgImage.alphaInfo {
            case .noneSkipLast, .noneSkipFirst:
                opaque = true
            default:
                //do nothing
                break
            }
        }
        UIGraphicsBeginImageContextWithOptions(to.size, opaque, scale)
        draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
