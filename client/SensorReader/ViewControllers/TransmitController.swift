//
//  TransmitControllerViewController.swift
//  SensorReader
//
//  Created by Admin on 10.04.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit
import CoreMotion

class TransmitController: UIViewController, UITableViewDataSource {
    
    enum MotionState {
        case connecting
        case gatherData
        case awaitTraining
        case predict
    }

    @IBOutlet weak var measurementGraph: MeasurementGraph!
    @IBOutlet weak var predictView: UIView!
    @IBOutlet weak var waitTrainingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var waitTrainingView: UIView!
    @IBOutlet weak var recordMotionTableView: UITableView!
    @IBOutlet weak var recordMotionLabel: UILabel!
    @IBOutlet weak var recordMotionView: UIView!
    @IBOutlet weak var confirmRecordedMotionsButton: UIButton!
    @IBOutlet weak var portLabel: UILabel!
    @IBOutlet weak var ipLabel: UILabel!
    @IBOutlet weak var connectionView: UIView!
    @IBOutlet weak var connectionIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    var state: MotionState = .connecting
    var ip: String = ""
    var port: String = ""
    var frequency: Double = 50
    var trainingDuration: Double = 5
    var chunk_size = 5
    
    var socket: WebSocket?
    var motions: [String] = []
    var recordingDict: [String: Recording] = [:]
    
    let motionManager = CMMotionManager()
    var queuedMeasurements: [Measurement]  = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initWebSocket()
    }
    
    func initViews() {
        cancelButton.layer.cornerRadius = 8
        statusLabel.text = "Verbinden"
        connectionIndicator.isHidden = false
        connectionIndicator.startAnimating()
        connectionView.layer.cornerRadius = 12
        ipLabel.text = ip
        portLabel.text = port
        confirmRecordedMotionsButton.layer.cornerRadius = 17
        recordMotionView.alpha = 0
        recordMotionTableView.dataSource = self
        confirmRecordedMotionsButton.isEnabled = false
        confirmRecordedMotionsButton.alpha = 0.5
        waitTrainingView.alpha = 0
        waitTrainingView.isHidden = true
        predictView.alpha = 0
        predictView.isHidden = true
        measurementGraph.setFrequency(frequency)
        measurementGraph.setTimeWindow(3)
    }
    
    
    func receivedConfig(_ configStr: String) {
        do {
            let data = configStr.data(using: .utf8)
            let config = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
            motions = config["motions"]! as! [String]
            frequency = config["frequency"]! as! Double
            trainingDuration = config["trainingDuration"]! as! Double
            chunk_size = config["chunkSize"]! as! Int
        } catch {
            print("failed parsing config json")
        }
        
        statusLabel.text = "Verbunden"
        recordMotionLabel.text = "Folgende Bewegungen für jeweils " + String(Int(trainingDuration)) + " Sekunden aufzeichnen."
        connectionIndicator.stopAnimating()
        connectionIndicator.isHidden = true
        recordMotionTableView.reloadData()
        UIView.animate(withDuration: 0.4, animations: {
            self.recordMotionView.alpha = 1
        })
    }
    
    func startPredicting() {
        print("start predicting")
        predictView.isHidden = false
        UIView.animate(withDuration: 0.3, animations: {
            self.waitTrainingView.alpha = 0
            self.predictView.alpha = 1
        }, completion: { _ in
            self.waitTrainingView.isHidden = true
        })
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = TimeInterval(1.0/frequency)
            motionManager.startDeviceMotionUpdates(to: .main, withHandler: { (data, error) in
                if let validData = data {
                    let measurement = Measurement(acc: validData.userAcceleration, rot: validData.rotationRate)
                    self.processMeasurement(measurement)
                }
            })
        }
        state = .predict
    }
    
    func processMeasurement(_ measurement: Measurement) {
        measurementGraph.displayNewMeasurement(measurement)
        queuedMeasurements.append(measurement)
        if queuedMeasurements.count >= chunk_size {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: queuedMeasurements.map({$0.asArray()}), options: JSONSerialization.WritingOptions())
                let jsonString = String(data: jsonData, encoding: .utf8)
                socket?.send(text: jsonString!)
                queuedMeasurements.removeAll()
            } catch {
                print("error generating json from measurement")
            }
        }
    }
    
    func newRecording(_ motionName: String, _ recording: Recording) {
        recordingDict[motionName] = recording
        if motions.allSatisfy({recordingDict[$0] != nil}) {
            confirmRecordedMotionsButton.isEnabled = true
            confirmRecordedMotionsButton.alpha = 1
        }
        recordMotionTableView.reloadData()
    }
    
    
    @IBAction func cancelClicked(_ sender: Any) {
        socket?.close()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func confirmRecordingsClicked(_ sender: Any) {
        UIView.animate(withDuration: 0.3, animations: {
            self.recordMotionView.alpha = 0
        }, completion: { _ in
            self.recordMotionView.isHidden = true
            self.waitTrainingView.isHidden = false
            self.waitTrainingIndicator.startAnimating()
            UIView.animate(withDuration: 0.3, animations: {
                self.waitTrainingView.alpha = 1
            })
        })
        state = .awaitTraining
        
        for motionName in motions {
            let measurements = recordingDict[motionName]!.measurements
            let jsonPayload: [String: Any] = [
                "motion": motionName,
                "measurements": measurements.map { $0.asArray() }
            ]
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonPayload, options: JSONSerialization.WritingOptions())
                let jsonString = String(data: jsonData, encoding: .utf8)
                socket?.send(text: jsonString!)
            } catch {
                print("error generating json from training measurements")
            }
        }
    }
    
    func initWebSocket() {
        
        socket = WebSocket("ws://" + ip + ":" + port)
        socket?.event.open = {
            print("open")
        }
        socket?.event.error = { error in
            print("error", error)
        }
        socket?.event.message = { message in
            if let text = message as? String {
                self.handleMessage(text)
            }
        }
    }
    
    func handleMessage(_ message: String) {
        if state == .connecting {
            receivedConfig(message)
        }
        else if state == .gatherData {
            print("received message while gathering training data:", message)
        }
        else if state == .awaitTraining {
            if message == "ready" {
                startPredicting()
            }
        }
        else if state == .predict {
            print("received message while predicting:", message)
        }
    }
    
    // data source for motionTrainingTableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return motions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let recordingCell = tableView.dequeueReusableCell(withIdentifier: "recordMotionCell", for: indexPath) as! RecordMotionCell
        
        let motionIndex = indexPath.row
        
        recordingCell.motionLabel.text = motions[motionIndex]
        recordingCell.recordButton.addTarget(self, action: #selector(recordMotionClicked), for: .touchUpInside)
        recordingCell.recordButton.tag = motionIndex
        let title = recordingDict[motions[motionIndex]] != nil ? "Wiederholen" : "Aufzeichnen"
        recordingCell.recordButton.setTitle(title, for: .normal)
        
        return recordingCell
    }
    
    @objc
    func recordMotionClicked(sender: UIButton) {
        let motionName = motions[sender.tag]
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "recordingController")
        let recordingController = vc as! RecordingController
        recordingController.motionName = motionName
        recordingController.duration = trainingDuration
        recordingController.frequency = frequency
        recordingController.onSaved = { recording in
            self.newRecording(motionName, recording)
        }
        recordingController.persist = false
        self.present(recordingController, animated: true, completion: nil)
        
    }

}
