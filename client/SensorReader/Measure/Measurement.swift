//
//  Measurement.swift
//  SensorReader
//
//  Created by Admin on 31.01.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit
import CoreMotion

class Measurement {
    
    let timestamp: TimeInterval = NSDate().timeIntervalSince1970;
    let acceleration: (x: Double, y: Double, z: Double)
    let rotation: (x: Double, y: Double, z: Double)
    
    init(_ ax: Double, _ ay: Double, _ az: Double, _ rx: Double, _ ry: Double, _ rz: Double) {
        acceleration = (ax, ay, az)
        rotation = (rx, ry, rz)
    }
    
    init(acc: CMAcceleration, rot: CMRotationRate) {
        acceleration = (acc.x, acc.y, acc.z)
        rotation = (rot.x, rot.y, rot.z)
    }
    
    func asArray() -> [Double] {
        let (ax, ay, az) = acceleration
        let (ox, oy, oz) = rotation
        return [ax, ay, az, ox, oy, oz]
    }
    
    func toJSONObject() -> [String: Any] {
        let jsonObject: [String: Any] = [
            "acceleration": [acceleration.x, acceleration.y, acceleration.z],
            "rotation": [rotation.x, rotation.y, rotation.z]
        ]
        return jsonObject
    }
}
