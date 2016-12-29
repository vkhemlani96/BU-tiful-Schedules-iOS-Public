//
//  PopupViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 12/24/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class PopupViewController: UIViewController {
    
    private var schedule : Leaf?
    
    func setSchedule(schedule : Leaf) {
        self.schedule = schedule
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scheduleViewEmbedSegue" {
            let s = segue.destination as! SingleScheduleTableViewController
            s.schedule = self.schedule
        }
    }

}
