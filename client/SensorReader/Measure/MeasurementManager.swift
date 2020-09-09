//
//  MeasurementManager.swift
//  SensorReader
//
//  Created by Admin on 31.01.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit
import CoreMotion

class MeasurementManager {

    let motionManager: CMMotionManager = CMMotionManager()
    var frequency: Double = 1
    var subscribers = [(key: String, subscriber: ProcessMeasurementProtocol)]()
    
    func addSubscriber(key: String, subscriber: ProcessMeasurementProtocol) {
        subscribers.append((key, subscriber))
    }
    
    func dropSubscriber(key: String) {
        subscribers = subscribers.filter() { $0.key != key }
    }
    
    func sendUpdates(_ measurement: Measurement) {
        for (_, subscriber) in subscribers {
            subscriber.processMeasurement(measurement)
        }
    }
    
    func startMeasuring() {
        if !motionManager.isAccelerometerAvailable { return }
        
        
        
        motionManager.accelerometerUpdateInterval = TimeInterval(1/frequency)
        motionManager.startAccelerometerUpdates(to: .main,
            withHandler: { accelerometerData, error in
                guard let accelerometerData = accelerometerData else { return }
                let acc = accelerometerData.acceleration
                let measurement = Measurement(acc.x, acc.y, acc.z, acc.x, acc.y, acc.z)
                self.sendUpdates(measurement)
            
        })
    }
    
    func stopMeasuring() {
        motionManager.stopAccelerometerUpdates()
    }
    
}
