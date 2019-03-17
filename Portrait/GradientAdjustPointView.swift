//
//  GradientAdjustPointView.swift
//  Portrait
//
//  Created by Rina Kotake on 2019/03/10.
//  Copyright © 2019 koooootake. All rights reserved.
//

import UIKit

protocol GradientAdjustPointViewDelegate: class {
    func startViewTouchesMoved(_ view: GradientAdjustPointView, point: CGPoint)
    func endViewTouchesMoved(_ view: GradientAdjustPointView, point: CGPoint)
}

class GradientAdjustPointView: UIView {

    private var locationInitialTouch: CGPoint!
    weak var delegate: GradientAdjustPointViewDelegate?
    private var pointType: PointType?

    enum PointType {
        case start
        case end
    }

    init() {
        super.init(frame: CGRect.zero)
    }

    func setup(pointType: PointType) {
        isUserInteractionEnabled = true

        self.pointType = pointType
        switch pointType {
        case .start:
            layer.borderColor = UIColor.white.cgColor
            backgroundColor = UIColor(named: "GGray")
        case .end:
            layer.borderColor = UIColor(named: "GGray")!.cgColor
            backgroundColor = UIColor.white
        }
        layer.cornerRadius = frame.width / 2
        layer.borderWidth = 4
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            locationInitialTouch = location
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveView(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveView(touches)
    }

    private func moveView(_ touches: Set<UITouch>) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            frame = frame.offsetBy(dx: location.x - locationInitialTouch.x, dy: location.y - locationInitialTouch.y)

            guard let type = pointType else {
                assertionFailure()
                return
            }
            switch type {
            case .start:
                delegate?.startViewTouchesMoved(self, point: frame.origin)
            case .end:
                delegate?.endViewTouchesMoved(self, point: frame.origin)
            }
        }
    }
}

