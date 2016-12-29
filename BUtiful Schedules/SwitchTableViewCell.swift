//
//  SwitchTableViewCell.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 6/3/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

// Cell for the classes empty filter
class SwitchTableViewCell: UITableViewCell {
    
    var filterViewController : FilterTableViewController?
    
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var switchTextView: UILabel!
    
    var onSwitched : ((_ isOn : Bool) -> Void)?
    
    @IBAction func onSwitched(_ sender: UISwitch) {
        if onSwitched != nil {
            onSwitched!(sender.isOn)
        }
//        filterViewController?.parentController?.hideFull = sender.isOn
//        filterViewController?.parentController?.filter()
    }


}
