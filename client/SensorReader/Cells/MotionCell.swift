//
//  MotionCell.swift
//  SensorReader
//
//  Created by Admin on 10.03.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit

class MotionCell: UITableViewCell {

    var defaultBackground: UIColor = .quaternarySystemFill
    var selectedBackground: UIColor = .systemFill
    var cellSelected: Bool = false
    
    @IBOutlet weak var motionLabel: UILabel!
    @IBOutlet weak var cellBackground: UIView!
    @IBOutlet weak var selectionIndicator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        cellBackground.layer.masksToBounds = true
        cellBackground.layer.cornerRadius = 15
        cellBackground.backgroundColor = defaultBackground
        selectionIndicator.layer.masksToBounds = true
        selectionIndicator.layer.cornerRadius = 6
        selectionIndicator.alpha = 0
    }
    
    func setBackground(color: UIColor, animated: Bool) {
        if animated {
            UIView.animate(withDuration: TimeInterval(0.25), delay: 0, options: .curveEaseOut, animations: {
                self.cellBackground.backgroundColor = color
            }, completion: nil)
        } else {
            self.cellBackground.backgroundColor = color
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        if selected != cellSelected {
            cellSelected = selected
            let newColor = selected ? selectedBackground : defaultBackground
            setBackground(color: newColor, animated: !isHighlighted)
            UIView.animate(withDuration: TimeInterval(0.15), delay: 0, options: .curveEaseInOut, animations: {
                self.selectionIndicator.alpha = selected ? 1 : 0
            }, completion: nil)
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        if highlighted && !cellSelected {
            setBackground(color: selectedBackground, animated: true)
        } else if !cellSelected {
            cellBackground.backgroundColor = defaultBackground
        }
    }

}
