//
//  RecordingController.swift
//  SensorReader
//
//  Created by Admin on 02.02.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit
import CoreMotion
import AudioToolbox

class RecordingController: UIViewController, ProcessMeasurementProtocol {

    var onDismiss: (() -> Void)?
    var onSaved: ((Recording) -> Void)?
    var persist: Bool = true
    var motionName: String = ""
    var duration: Double = 0
    var exactDuration: Double = 0 //in case of inaccurate motion update intervals
    var intervalVariance: Double = 0 //variance around the configured interval
    var frequency: Double = 0
    var recordingTime: Date = Date()
    var isRecording: Bool = false
    
    
    let countdownSeconds = 3
    
    
    var measurements = [Measurement]()
    var clockTimer: Timer?
    var countdownTimer: Timer?
    let motionManager = CMMotionManager()
    let persistenceManager = PersistenceManager()

    @IBOutlet weak var countdownView: UIView!
    @IBOutlet weak var countdownCircle: ProgressCircle!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var progressCircle: ProgressCircle!
    @IBOutlet weak var measurementGraph: MeasurementGraph!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveButton.layer.masksToBounds = true
        saveButton.layer.cornerRadius = 17
        saveButton.alpha = 0
        saveButton.isEnabled = false
        descriptionLabel.alpha = 0.5
        descriptionLabel.text = motionName != "" ? motionName : "Unbenannt"
        cancelButton.layer.masksToBounds = true
        cancelButton.layer.cornerRadius = 8
        measurementGraph.setFrequency(frequency)
        measurementGraph.setTimeWindow(duration)
        countdownCircle.backgroundAlpha = 0
        countdownCircle.baseAngle = -CGFloat.pi/2
        countdownCircle.lineWidth = 10
        progressCircle.baseAngle = CGFloat.pi/2
        
        frequencyLabel.text = String(Int(frequency)) + "Hz"
        totalTimeLabel.text = "/" + String(Int(duration)) + " Sekunden"
        
        countdown(countdownSeconds)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isRecording {
            stopRecording(canceled: true)
        } else {
            countdownTimer?.invalidate()
        }
        onDismiss?()
    }
    
    func countdown(_ remainingSec: Int) {
        if remainingSec == 0 {
            UIView.animate(withDuration: TimeInterval(0.2), delay: 0, options: .curveEaseInOut, animations: {
                self.countdownView.alpha = 0
            }, completion: { _ in
                self.countdownView.isHidden = true
                self.startRecording()
            })
        } else {
            let frequency = 100
            var counter = 0
            countdownTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(1.0/Double(frequency)), repeats: true, block: { timer in
                let progress = (Double(self.countdownSeconds - remainingSec) + Double(counter)/Double(frequency))/Double(self.countdownSeconds)
                self.countdownCircle.setProgress(progress)
                if counter == 0 {
                    self.countdownLabel.text = String(remainingSec)
                    UIView.animate(withDuration: TimeInterval(0.1), animations: {
                        self.countdownLabel.alpha = 1
                    }, completion: { _ in
                        UIView.animate(withDuration: 0.9, delay: 0, options: .curveEaseIn, animations: {
                            self.countdownLabel.alpha = 0
                        }, completion: nil)
                    })
                }
                if counter == frequency {
                    timer.invalidate()
                    self.countdown(remainingSec - 1)
                }
                counter += 1
            })
        
            
        }
    }
    
    func vibrate() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func startRecording() {
        vibrate()
        statusLabel.text = "Aktiv"
        isRecording = true
        recordingTime = Date()
        
        // start motion updates
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = TimeInterval(1.0/frequency)
            var counter = 0
            let maxCount = Int(self.duration*self.frequency)
            var first: Double = 0.0
            var previous: Double = 0.0
            var totalSquaredDiff: Double = 0
            let expectedInterval: Double = 1/frequency
            motionManager.startDeviceMotionUpdates(to: .main, withHandler: { (data, error) in
                if let validData = data {
                    let ts = validData.timestamp
                    if counter == 0 {
                        self.startClockTimer()
                        first = ts
                    } else {
                        let diff = ts - previous
                        totalSquaredDiff += pow(diff - expectedInterval, 2)
                    }
                    previous = ts
                    
                    let measurement = Measurement(acc: validData.userAcceleration, rot: validData.rotationRate)
                    self.processMeasurement(measurement)
                    counter += 1
                    if counter == maxCount {
                        self.motionManager.stopDeviceMotionUpdates()
                        self.stopRecording(canceled: false)
                        self.exactDuration = ts - first
                        self.intervalVariance = totalSquaredDiff/(Double(counter - 1))
                    }
                }
            })
        }
    }
    
    func startClockTimer() {
        let startTime = DispatchTime.now()
        clockTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.01), repeats: true, block: { timer in
            let elapsedSeconds: Double = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1000000000
            let progress = elapsedSeconds/self.duration
            self.progressCircle.setProgress(progress)
            
            let seconds: Int = Int(elapsedSeconds)
            let centiSeconds: Int = Int((elapsedSeconds - Double(Int(elapsedSeconds)))*100)
            self.updateTimeLabel(seconds: seconds, centiSeconds: centiSeconds)
        })
    }
    
    func stopRecording(canceled: Bool) {
        isRecording = false
        clockTimer?.invalidate()
        motionManager.stopDeviceMotionUpdates()

        if !canceled {
            vibrate()
            //updateTimeLabel(seconds: Int(duration), centiSeconds: 0)
            self.progressCircle.setProgress(1)
            statusLabel.text = "Fertig"
            saveButton.isEnabled = true
            UIView.animate(withDuration: TimeInterval(0.3), animations: {
                self.saveButton.alpha = 1
            })
        }
    }
    
    func processMeasurement(_ measurement: Measurement) {
        if isRecording {
            measurementGraph.displayNewMeasurement(measurement)
            measurements.append(measurement)
        }
    }

    func cancelRecording() {
        if isRecording {
            stopRecording(canceled: true)
        }
        dismiss(animated: true, completion: nil)
    }

    func updateTimeLabel(seconds: Int, centiSeconds: Int) {
        let secondsStr = String(seconds)
        let centiSecondsStr = String(centiSeconds)
        timeLabel.text = (secondsStr.count == 1 ? "0" + secondsStr : secondsStr) + "," + (centiSecondsStr.count == 1 ? "0" + centiSecondsStr : centiSecondsStr)
    }
    
    @IBAction func cancelClicked(_ sender: Any) {
        cancelRecording()
    }
    
    @IBAction func saveClicked(_ sender: Any) {
        let recording = Recording(timestamp: recordingTime, duration: duration, frequency: frequency, name: motionName, description: "", measurements: measurements, exactDuration: exactDuration, intervalVariance: intervalVariance)
        if persist {
            persistenceManager.saveRecording(recording)
        }
        onSaved?(recording)
        dismiss(animated: true, completion: nil)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
