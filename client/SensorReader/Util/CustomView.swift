//
//  CustomView.swift
//  SensorReader
//
//  Created by Admin on 01.02.20.
//  Copyright © 2020 Niemann Studios. All rights reserved.
//

import UIKit

class CustomView: UIView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func initSubviews(nibName: String) {
        let nib = UINib(nibName: nibName, bundle: nil)
        let contentView = nib.instantiate(withOwner: self, options: nil).first as! UIView
        self.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }

}
