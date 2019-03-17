//
//  Util.swift
//  Portrait
//
//  Created by Rina Kotake on 2018/12/08.
//  Copyright © 2018年 koooootake. All rights reserved.
//

import Foundation

class Util {
    static func topmostViewController() -> UIViewController? {
        guard var vc = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }
        while vc.presentedViewController != nil {
            vc = vc.presentedViewController!
        }
        return vc
    }
}
