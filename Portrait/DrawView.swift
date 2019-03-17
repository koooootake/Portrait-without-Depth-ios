//
//  DrawView.swift
//  Portrait
//
//  Created by Rina Kotake on 2018/12/02.
//  Copyright © 2018年 koooootake. All rights reserved.
//

import UIKit

final class DrawView: UIImageView {
    var penColor = UIColor.white
    var penSize: CGFloat = 10
    private var path: UIBezierPath!
    private var lastDrawImage: UIImage?

    private var temporaryPath: UIBezierPath!
    private var points = [CGPoint]()

    private var pointCount = 0
    private var snapshotImage: UIImage?

    private var isCallTouchMoved = false

    private var imageSize: CGSize?

    func reset() {
        lastDrawImage = nil
        snapshotImage = nil
        image = nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        isUserInteractionEnabled = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let currentPoint = touches.first?.location(in: self) else {
            assertionFailure()
            return
        }

        path = UIBezierPath()
        path?.lineWidth = penSize
        path?.lineCapStyle = CGLineCap.round
        path?.lineJoinStyle = CGLineJoin.round
        path?.move(to: currentPoint)
        points = [currentPoint]
        pointCount = 0
    }

    ///Zoom時Drawを防ぐため
    func beginZooming() {
        image = lastDrawImage
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        isCallTouchMoved = true
        pointCount += 1
        guard let currentPoint = touches.first?.location(in: self) else {
            assertionFailure()
            return
        }

        points.append(currentPoint)
        if points.count == 2 {
            temporaryPath = UIBezierPath()
            temporaryPath?.lineWidth = penSize
            temporaryPath?.lineCapStyle = .round
            temporaryPath?.lineJoinStyle = .round
            temporaryPath?.move(to: points[0])
            temporaryPath?.addLine(to: points[1])
            image = drawLine()
        }else if points.count == 3 {
            temporaryPath = UIBezierPath()
            temporaryPath?.lineWidth = penSize
            temporaryPath?.lineCapStyle = .round
            temporaryPath?.lineJoinStyle = .round
            temporaryPath?.move(to: points[0])
            temporaryPath?.addQuadCurve(to: points[2], controlPoint: points[1])
            image = drawLine()
        }else if points.count == 4 {
            temporaryPath = UIBezierPath()
            temporaryPath?.lineWidth = penSize
            temporaryPath?.lineCapStyle = .round
            temporaryPath?.lineJoinStyle = .round
            temporaryPath?.move(to: points[0])
            temporaryPath?.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
            image = drawLine()
        }else if points.count == 5 {
            points[3] = CGPoint(x: (points[2].x + points[4].x) * 0.5, y: (points[2].y + points[4].y) * 0.5)
            if points[4] != points[3] {
                let length = hypot(points[4].x - points[3].x, points[4].y - points[3].y) / 2.0
                let angle = atan2(points[3].y - points[2].y, points[4].x - points[3].x)
                let controlPoint = CGPoint(x: points[3].x + cos(angle) * length, y: points[3].y + sin(angle) * length)
                temporaryPath = UIBezierPath()
                temporaryPath?.move(to: points[3])
                temporaryPath?.lineWidth = penSize
                temporaryPath?.lineCapStyle = .round
                temporaryPath?.lineJoinStyle = .round
                temporaryPath?.addQuadCurve(to: points[4], controlPoint: controlPoint)
            } else {
                temporaryPath = nil
            }
            path?.move(to: points[0])
            path?.addCurve(to: points[3], controlPoint1: points[1], controlPoint2: points[2])
            points = [points[3], points[4]]
            image = drawLine()
        }
        if pointCount > 50 {
            temporaryPath = nil
            snapshotImage = drawLine()
            path.removeAllPoints()
            pointCount = 0
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let currentPoint = touches.first?.location(in: self) else {
            assertionFailure()
            return
        }
        if !isCallTouchMoved { path?.addLine(to: currentPoint) }
        image = drawLine()
        lastDrawImage = image
        temporaryPath = nil
        snapshotImage = nil
        isCallTouchMoved = false
    }

    func drawLine() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        if snapshotImage != nil {
            snapshotImage?.draw(at: CGPoint.zero)
        }else {
            lastDrawImage?.draw(at: CGPoint.zero)
        }
        penColor.setStroke()
        path?.stroke()
        temporaryPath?.stroke()
        let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return capturedImage
    }
}

