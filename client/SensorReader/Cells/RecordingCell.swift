//
//  RecordingCell.swift
//  SensorReader
//
//  Created by Admin on 05.02.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit

class RecordingCell: UITableViewCell {

    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var recordingTitle: UILabel!
    @IBOutlet weak var recordingTimestamp: UILabel!
    @IBOutlet weak var recordingDuration: UILabel!
    @IBOutlet weak var recordingFrequency: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        roundedView.layer.masksToBounds = true
        roundedView.layer.cornerRadius = 8
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
