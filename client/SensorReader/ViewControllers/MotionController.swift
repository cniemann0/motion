//
//  MotionController.swift
//  SensorReader
//
//  Created by Admin on 05.03.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit

class MotionController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var firstSelectedMotion = "" // set via segue
    var onDismiss: ((String) -> Void)? = nil
    var sortedMotions: [String]! = [String]()
    var addAction: UIAlertAction?
    let cellReuseIdentifier = "motionCell"
    
    let persistenceManager = PersistenceManager()
    var captureController: CaptureController?
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var addMotionButton: UIButton!
    @IBOutlet weak var motionTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        backButton.layer.masksToBounds = true
        backButton.layer.cornerRadius = 8
        addMotionButton.layer.masksToBounds = true
        addMotionButton.layer.cornerRadius = 8
        
        
        motionTableView.tableHeaderView = UIView()
        motionTableView.tableHeaderView?.frame.size.height = 10
        motionTableView.tableFooterView = UIView()
        motionTableView.tableFooterView?.frame.size.height = 10
        motionTableView.delegate = self
        motionTableView.dataSource = self

        if let motions = persistenceManager.loadMotions() {
            sortedMotions = motions.sorted()
        }
        selectMotion(firstSelectedMotion)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDismiss?(getSelectedMotion())
    }
    
    func selectMotion(_ motionName: String) {
        var selectedIndex = 0
        if let firstIndex = sortedMotions.firstIndex(where: {
            motion in
            return motion == motionName
        }) {
           selectedIndex = firstIndex + 1
        }
        motionTableView.selectRow(at: IndexPath(row: selectedIndex, section: 0), animated: true, scrollPosition: .top)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedMotions.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = motionTableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! MotionCell
        let text = indexPath.row == 0 ? "Keine Auswahl" : sortedMotions[indexPath.row - 1]
        cell.motionLabel.text = text
        cell.motionLabel.alpha = indexPath.row == 0 ? 0.35 : 1
        return cell
    }
    
    func addMotion(_ newMotion: String) {
        sortedMotions.append(newMotion)
        sortedMotions.sort()
        persistenceManager.saveAllMotions(motions: self.sortedMotions)
        motionTableView.reloadData()
        selectMotion(newMotion)
    }
    
    func getSelectedMotion() -> String {
        var motionName = ""
        if let selRow = motionTableView.indexPathForSelectedRow?.row {
            if selRow > 0 && selRow <= sortedMotions.count {
                motionName = sortedMotions[selRow-1]
            }
        }
        return motionName
    }

    @IBAction func addMotionPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Neue Bewegung", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { textField -> Void in
            textField.autocapitalizationType = .words
            textField.addTarget(self, action: #selector(self.editingChanged), for: .editingChanged)
        })
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .destructive, handler: nil))
        self.addAction = UIAlertAction(title: "Hinzufügen", style: .default, handler: { action -> Void in
            if let newMotion = alert.textFields![0].text {
                self.addMotion(newMotion)
            }
        })
        self.addAction!.isEnabled = false
        alert.addAction(self.addAction!)
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @objc func editingChanged(_ textField: UITextField) {
        if let text = textField.text {
            self.addAction?.isEnabled = text.count > 0
                                    && !text.contains(" ")
                                    && !text.contains("-")
                                    && !self.sortedMotions.contains(text)
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {
        //onDismiss?(getSelectedMotion())
        dismiss(animated: true, completion: nil)
    }

}
