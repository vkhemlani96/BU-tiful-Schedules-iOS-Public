//
//  ClassDaysTableViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/27/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class ClassDaysTableViewController: UITableViewController {
    
    var parentController : FilterTableViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Iterate through class days and show checkmark depending of if filter is already set
        for day in FilterManager.DAYS_FILTER.noClassesOn {
            tableView.cellForRow(at: IndexPath(row: day - 1, section: 0))?.accessoryType = UITableViewCellAccessoryType.checkmark
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "No Classes On:"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Toggle checkmark and filter value on select
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) {
            FilterManager.adjustedFilteringParameters()
            
            let currentlyUnchecked = cell.accessoryType == UITableViewCellAccessoryType.none
            
            if currentlyUnchecked {
                FilterManager.DAYS_FILTER.noClassesOn.insert(indexPath.row + 1)   // Add one for sunday
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                FilterManager.DAYS_FILTER.noClassesOn.remove(indexPath.row + 1)     // Add one for sunday
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
        
    }
    

}
