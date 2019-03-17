//
//  UIView+Extension.swift
//  Portrait
//
//  Created by Rina Kotake on 2019/02/27.
//  Copyright © 2019 koooootake. All rights reserved.
//

import Foundation

extension UIView {

    func addConstraintsFitParentView(_ selectedView: UIView) {
        selectedView.translatesAutoresizingMaskIntoConstraints = false

        let views = ["subview" : selectedView]
        self.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[subview]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                metrics: nil,
                views: views
            )
        )
        self.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[subview]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                metrics: nil,
                views: views
            )
        )
    }
}
