//
//  Recording.swift
//  SensorReader
//
//  Created by Admin on 02.02.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit
import CoreData

class Recording {

    var timestamp: Date
    var duration: Double
    var frequency: Double
    var name: String
    var description: String
    var measurements: [Measurement]
    var exactDuration: Double
    var intervalVariance: Double

    init(timestamp: Date, duration: Double, frequency: Double, name: String, description: String, measurements: [Measurement], exactDuration: Double, intervalVariance: Double) {
        self.timestamp = timestamp
        self.duration = duration
        self.frequency = frequency
        self.name = name
        self.description = description
        self.measurements = measurements
        self.exactDuration = exactDuration
        self.intervalVariance = intervalVariance
    }
    
    func toJson() -> String? {
        let jsonObject: [String: Any] = [
            "timestamp": Util.dateFormatter.string(from: timestamp),
            "duration": duration,
            "frequency": frequency,
            "name": name,
            "description": description,
            "measurements": measurements.map() { $0.toJSONObject() },
            "exactDuration": exactDuration,
            "intervalVariance": intervalVariance
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions())
            let jsonString = String(data: jsonData, encoding: .utf8)
            return jsonString
        } catch {
            return nil
        }
    }
    
    static func fromJson(_ json: String) -> Recording {
        //not implemented, dummy values
        let timestamp = Date()
        let duration: Double = 5
        let frequency: Double = 20
        let name = json
        let description = ""
        let measurements = [Measurement]()
        let exactDuration: Double = 5
        let intervalVariance: Double = 0
        return Recording(timestamp: timestamp, duration: duration, frequency: frequency, name: name, description: description, measurements: measurements, exactDuration: exactDuration, intervalVariance: intervalVariance)
    }
    
}
