//
//  UIAlertController+Extension.swift
//  Portrait
//
//  Created by Rina Kotake on 2018/12/08.
//  Copyright © 2018年 koooootake. All rights reserved.
//

import Foundation

extension UIAlertController {
    
    static func show(title: String, message: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "🙆‍♂️OK🙆‍♀️", style: .default, handler: nil)
        alertController.addAction(action)
        guard let vc = Util.topmostViewController() else {
            assertionFailure()
            return
        }
        vc.present(alertController, animated: true, completion: nil)
    }
}
