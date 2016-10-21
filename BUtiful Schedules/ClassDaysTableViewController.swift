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
        for i in 0..<5 {
            if !parentController!.parentController!.classDays[i] {
                tableView.cellForRow(at: IndexPath(row: i, section: 0))?.accessoryType = UITableViewCellAccessoryType.none
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Toggle checkmark and filter value on select
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType =
            tableView.cellForRow(at: indexPath)?.accessoryType == UITableViewCellAccessoryType.checkmark ? UITableViewCellAccessoryType.none : UITableViewCellAccessoryType.checkmark
        tableView.reloadRows(at: [indexPath], with: .none)
        
        parentController!.parentController!.classDays[(indexPath as NSIndexPath).row] = !parentController!.parentController!.classDays[(indexPath as NSIndexPath).row]
    }
    

}
