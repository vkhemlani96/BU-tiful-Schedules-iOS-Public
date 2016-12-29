//
//  ScheduleDetailTableViewCell.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/31/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class ScheduleDetailTableViewCell: UITableViewCell {

    // Holds the course code, ie. "CAS EC 101"
    @IBOutlet weak var titleView: UILabel!
    
    // Holds the section type, ie. "Lecture" or "Discussion"
    @IBOutlet weak var detailSubtitleView: UILabel!
    
    // Holds section infos ie. A1: Watson, STO B50, 4 Seats
    @IBOutlet weak var detail1View: UILabel!
    @IBOutlet weak var detail2View: UILabel!
    @IBOutlet weak var detail3View: UILabel!
    
    // Changes color to match course in the schedule image
    @IBOutlet weak var sectionColor: UIView!
}
