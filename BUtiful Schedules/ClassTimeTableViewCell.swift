//
//  ClassTimeTableViewCell.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/27/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

// Cell used for class time filtering
class ClassTimeTableViewCell: UITableViewCell {

    @IBOutlet weak var pickerView: UIDatePicker!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
