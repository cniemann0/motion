//
//  CaptureController.swift
//  SensorReader
//
//  Created by Admin on 30.01.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit
import CoreMotion

class CaptureController: UIViewController, ProcessMeasurementProtocol, UITextFieldDelegate {
    
    let motionManager = CMMotionManager()
    //let measurementManager: MeasurementManager = MeasurementManager()
    var duration: Double = Config.initialDuration
    var frequency: Double = Config.frequencies[Config.initialFrequencyIndex]
    var motionName = ""
    
    var recordingActive = false
    
    @IBOutlet weak var measurementGraph: MeasurementGraph!
    @IBOutlet weak var modeControl: UISegmentedControl!
    @IBOutlet weak var localView: UIView!
    @IBOutlet weak var transmitView: UIView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var transmitButton: UIButton!
    @IBOutlet weak var connectionSettingView: UIView!
    
    @IBOutlet weak var portField: UITextField!
    @IBOutlet weak var ipField: UITextField!
    
    @IBOutlet weak var frequencyLabel: UILabel!
    @IBOutlet weak var frequencyStepper: UIStepper!
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var durationStepper: UIStepper!
    
    @IBOutlet weak var motionView: UIView!
    @IBOutlet weak var motionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        frequencyStepper.minimumValue = 0
        frequencyStepper.maximumValue = Double(Config.frequencies.count - 1)
        frequencyStepper.value = Double(Config.initialFrequencyIndex)
        motionManager.deviceMotionUpdateInterval = TimeInterval(1/frequency)
        measurementGraph.setFrequency(frequency)
        frequencyLabel.text = String(Int(frequency)) + "Hz"
        durationStepper.minimumValue = Config.minDuration
        durationStepper.maximumValue = Config.maxDuration
        durationStepper.value = duration
        durationLabel.text = String(Int(duration)) + "sek"
        
        transmitView.isHidden = true
        transmitButton.layer.masksToBounds = true
        transmitButton.layer.cornerRadius = 17
        recordButton.layer.masksToBounds = true
        recordButton.layer.cornerRadius = 17
        motionView.layer.masksToBounds = true
        motionView.layer.cornerRadius = 12
        
        connectionSettingView.layer.cornerRadius = 8
        ipField.delegate = self
        portField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
    }
    
    @objc func willResignActive() {
        if !recordingActive {
            stopPreview()
        }
    }
    
    
    @objc func didBecomeActive() {
        if !recordingActive {
            startPreview()
        }
    }
    
    func startPreview() {
        print("start preview")
        
        startMotionUpdates()
    }
    
    func stopPreview() {
        print("stop preview")
        
        measurementGraph.clear()
        stopMotionUpdates()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //print("did appear")
        startPreview()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //print("did disappear")
        stopPreview()
    }
    
    func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main, withHandler: { data, error in
                if let validData = data {
                    let measurement = Measurement(acc: validData.userAcceleration, rot: validData.rotationRate)
                    self.processMeasurement(measurement)
                }
            })
        }
        
    }
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func processMeasurement(_ measurement: Measurement) {
        measurementGraph.displayNewMeasurement(measurement)
    }
    
    func setMotionName(_ newMotion: String) {
        if self.motionName != newMotion {
            self.motionName = newMotion
            motionLabel.text = motionName != "" ? motionName : "Keine Auswahl"
        }
    }
    
    @IBAction func selectedSegment(_ sender: UISegmentedControl) {
        let localSelected = (modeControl.selectedSegmentIndex == 0)
        localView.isHidden = !localSelected
        transmitView.isHidden = localSelected
    }
    
    @IBAction func frequencyChanged(_ sender: Any) {
        frequency = Config.frequencies[Int(frequencyStepper.value)]
        stopMotionUpdates()
        motionManager.deviceMotionUpdateInterval = TimeInterval(1/frequency)
        measurementGraph.setFrequency(frequency)
        measurementGraph.clear()
        startMotionUpdates()
        
        frequencyLabel.text = String(Int(frequency)) + "Hz"
    }
    
    @IBAction func durationChanged(_ sender: Any) {
        duration = durationStepper.value
        durationLabel.text = String(Int(duration)) + "sek"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let recordingController = segue.destination as? RecordingController {
            recordingController.motionName = motionName
            recordingController.duration = self.duration
            recordingController.frequency = self.frequency
            
            stopMotionUpdates()
            measurementGraph.clear()
            recordingActive = true
            recordingController.onDismiss = {
                self.recordingActive = false
                self.startMotionUpdates()
            }
        } else if let movementController = segue.destination as? MotionController {
            movementController.firstSelectedMotion = motionName
            movementController.onDismiss = { (selectedMotion: String) -> Void in
                self.setMotionName(selectedMotion)
            }
            movementController.captureController = self
        } else if let transmitController = segue.destination as? TransmitController {
            transmitController.ip = ipField.text!
            print(ipField.text!)
            print(portField.text!)
            transmitController.port = portField.text!
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    

}
