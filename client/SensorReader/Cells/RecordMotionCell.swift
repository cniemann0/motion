//
//  MotionTrainingCell.swift
//  SensorReader
//
//  Created by Admin on 12.04.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit

class RecordMotionCell: UITableViewCell {

    
    @IBOutlet weak var backgrView: UIView!
    @IBOutlet weak var motionLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        backgrView.layer.cornerRadius = 12
    }

}
