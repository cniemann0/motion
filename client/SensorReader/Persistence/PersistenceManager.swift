//
//  PersistenceManager.swift
//  SensorReader
//
//  Created by Admin on 28.02.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit

class PersistenceManager {

    let fileManager = FileManager.default
    var documentsURL: URL!
    let movementsFilename = "movements.txt"
    
    init() {
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func loadMotions() -> [String]? {
        let path = documentsURL.appendingPathComponent(movementsFilename)
        do {
            let content = try String(contentsOf: path, encoding: .utf8)
            return content.components(separatedBy: .newlines).filter { (line) -> Bool in
                line.count > 0
            }
        } catch {
            // no
            return nil
        }
    }
    
    func saveAllMotions(motions: [String]!) {
        let path = documentsURL.appendingPathComponent(movementsFilename)
        do {
            let content = motions.joined(separator: "\n")
            try content.write(to: path, atomically: true, encoding: .utf8)
        } catch {
            print("failed to write movements to file")
        }
    }
    
    func getAllRecordingURLs() -> [String]? {
        do {
            return try fileManager.contentsOfDirectory(atPath: documentsURL.path).filter { !$0.starts(with: ".") && !($0 == movementsFilename) }
        } catch {
            return nil
        }
    }
    
    func saveRecording(_ recording: Recording) {
        let path = documentsURL.appendingPathComponent(String(recording.name) + "-" + Util.dateFormatter.string(from: recording.timestamp) + ".json")
        let json = recording.toJson()!
        do {
            try json.write(to: path, atomically: true, encoding: .utf8)
        } catch {
            print("failed to write recording to file")
        }
    }
    
    func loadRecording(filename: String) -> Recording? {
        let filename = documentsURL.appendingPathComponent(filename + ".json")
        do {
            let json = try String(contentsOf: filename, encoding: .utf8)
            return Recording.fromJson(json)
        } catch {
            print("failed to load recording from file")
            return nil
        }
    }
    
    
}
