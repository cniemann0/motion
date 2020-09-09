//
//  MeasurementGraphCanvas.swift
//  SensorReader
//
//  Created by Admin on 31.01.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit

class MeasurementGraphCanvas: CustomView {

    var measurements: [Measurement] = [Measurement]()
    var timeWindow: Double = 3
    var frequency: Double = 30
    var count: Int = 90
    let maxCount: Int = 500
    
    @IBOutlet var contentView: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews(nibName: "MeasurementGraphCanvas")
    }
    
    func setTimeWindow(_ window: Double) {
        self.timeWindow = window
        updateMaxCount()
    }
    
    func setFrequency(_ frequency: Double) {
        self.frequency = frequency
        updateMaxCount()
    }
    
    func updateMaxCount() {
        let newCount = Int(timeWindow * frequency)
        count = newCount > maxCount ? maxCount : newCount
    }
    
    func addMeasurement(_ measurement: Measurement) {
        measurements.insert(measurement, at: 0)
        if measurements.count > count {
            measurements.removeLast()
        }
    }
    
    func clearMeasurements() {
        measurements.removeAll()
    }
    
    override func draw(_ rect: CGRect) {
        
        let xStep = Double(rect.width)/Double(count-1)
        let centerV = Double(rect.height)/2
        let gHeight = Double(rect.height/4)
        
        let baselinePath = UIBezierPath()
        baselinePath.move(to: CGPoint(x: 0, y: centerV))
        baselinePath.addLine(to: CGPoint(x: Double(rect.width), y: centerV))
        UIColor.init(cgColor: CGColor(srgbRed: 0.5, green: 0.5, blue: 0.5, alpha: 0.2)).setStroke()
        baselinePath.lineWidth = 2
        baselinePath.stroke()
        
        if measurements.isEmpty { return }
        
        let paths = [UIBezierPath(), UIBezierPath(), UIBezierPath()]
        let colors: [UIColor] = [.red, .green, .blue]
        let (ax0, ay0, az0) = measurements[0].acceleration
        paths[0].move(to: CGPoint(x: Double(rect.width), y: centerV - gHeight*ax0))
        paths[1].move(to: CGPoint(x: Double(rect.width), y: centerV - gHeight*ay0))
        paths[2].move(to: CGPoint(x: Double(rect.width), y: centerV - gHeight*az0))
        
        for (i, measurement) in measurements.dropFirst().enumerated() {
            let (ax, ay, az) = measurement.acceleration
            let values = [ax, ay, az]
            for (k, path) in paths.enumerated() {
                path.addLine(to: CGPoint(x: Double(rect.width) - Double(i+1)*xStep, y: centerV - gHeight*values[k]))
            }
        }
        
        for (path, color) in zip(paths, colors) {
            color.setStroke()
            path.lineWidth = 1
            path.stroke()
        }
        
    }
    
}
