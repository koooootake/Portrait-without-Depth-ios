//
//  ViewModel.swift
//  Portrait
//
//  Created by Rina Kotake on 2019/03/10.
//  Copyright © 2019 koooootake. All rights reserved.
//

import UIKit

class ViewModel {
    var status: Status
    enum Status {
        case load
        case segment
        case result
        case dof
    }

    var isHiddenSegmentView = true
    var isHiddenResultImageView = true
    var isHiddenGradientView = true
    var navigationTitle = ""
    var viewBackgroundColor = UIColor(named: "GGray")!

    init() {
        status = .load
    }

    func reload(status: Status) {
        switch status {
        case .load:
            isHiddenSegmentView = true
            isHiddenResultImageView = true
            isHiddenGradientView = true
            navigationTitle = "Chose image"
            viewBackgroundColor = UIColor(named: "GGray")!

        case .segment:
            isHiddenSegmentView = false
            isHiddenResultImageView = true
            isHiddenGradientView = true
            navigationTitle = "Segment"
            viewBackgroundColor = UIColor(named: "GBlue")!

        case .result:
            isHiddenSegmentView = true
            isHiddenResultImageView = false
            isHiddenGradientView = true
            navigationTitle = ""
            viewBackgroundColor = UIColor(named: "GGray")!

        case .dof:
            isHiddenSegmentView = true
            isHiddenResultImageView = true
            isHiddenGradientView = false
            navigationTitle = "DOF"
            viewBackgroundColor = UIColor(named: "GYellow")!
        }
    }
}
