//
//  MeasurementGraph.swift
//  SensorReader
//
//  Created by Admin on 31.01.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit

class MeasurementGraph: CustomView {
    
    @IBOutlet weak var graphCanvas: MeasurementGraphCanvas!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubviews(nibName: "MeasurementGraph")
    }
    
    func setTimeWindow(_ window: Double) {
        graphCanvas.setTimeWindow(window)
    }
    
    func setFrequency(_ frequency: Double) {
        graphCanvas.setFrequency(frequency)
    }
    
    func displayNewMeasurement(_ measurement: Measurement) {
        graphCanvas.addMeasurement(measurement)
        graphCanvas.setNeedsDisplay()
    }
    
    func clear() {
        graphCanvas.clearMeasurements()
        graphCanvas.setNeedsDisplay()
    }
    
}
