//
//  ProgressCircle.swift
//  SensorReader
//
//  Created by Admin on 02.02.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit

class ProgressCircle: CustomView {

    var progress: CGFloat = 0
    var backgroundAlpha: CGFloat = 0.3
    var baseAngle: CGFloat = 0
    var lineWidth: CGFloat = 5
    
    @IBOutlet var contentView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews(nibName: "ProgressCircle")
        self.setNeedsDisplay()
    }
    
    func setProgress(_ progress: Double) {
        let newProgress = CGFloat(progress)
        if newProgress != self.progress {
            self.progress = newProgress
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        let progressAngle = baseAngle + 2*CGFloat.pi * progress
        let center = CGPoint(x: rect.width/2, y: rect.height/2)
        
        let lightPath = UIBezierPath(arcCenter: center, radius: rect.width/2 - lineWidth, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true)
        let lightColor = tintColor.withAlphaComponent(self.backgroundAlpha)
        lightColor.setStroke()
        lightPath.lineWidth = lineWidth
        lightPath.stroke()
        
        let circlePath = UIBezierPath(arcCenter: center, radius: rect.width/2 - lineWidth, startAngle: baseAngle, endAngle: progressAngle , clockwise: true)
        tintColor.setStroke()
        circlePath.lineWidth = lineWidth
        circlePath.stroke()
        
    }

}
