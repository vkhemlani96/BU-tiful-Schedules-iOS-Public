//
//  ClassTimesTableViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/27/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class ClassTimesTableViewController: UITableViewController {
    
    var parentController :  FilterTableViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2    // Start time and end time
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2    // Title cell and pickerView cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath as NSIndexPath).row == 0 ? 44 : 165   // Height varies for type of cell
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Title cell only displays title
        if ((indexPath as NSIndexPath).row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "timesCell", for: indexPath)
            cell.textLabel?.text = (indexPath as NSIndexPath).section == 0 ? "Start Time" : "End Time"
            return cell
        }
        
        // Otherwise, set pickView to current filters time
        let cell = tableView.dequeueReusableCell(withIdentifier: "timesCell", for: indexPath) as! ClassTimeTableViewCell
        
        // Section 0 = start time, Section 1 = end time
        let time = parentController!.parentController!.classTimes[(indexPath as NSIndexPath).section]
        let hours = Int(time / 1) * 100
        let mins = Int(time.truncatingRemainder(dividingBy: 1) * 60)
        
        // COnvert time int to string
        var timeString = String(hours + mins)
        while timeString.characters.count < 4 {
            timeString = "0" + timeString
        }
        
        // Convert string to date format and set in pickerView
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateFormat = "kkmm"
        print(dateFormatter.date(from: timeString))
        cell.pickerView.date = dateFormatter.date(from: timeString)!
        
        return cell
    }
    
    // Store time filter on disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let parent = self.parentController {
            let cal = Calendar.current
            for i in 0..<2 {
                let cell = tableView.cellForRow(at: IndexPath(row: 1, section: i)) as! ClassTimeTableViewCell
                let comp = NSCalendar.Unit.hour.union(NSCalendar.Unit.minute)
                let comps = (cal as NSCalendar).components(comp, from: cell.pickerView.date)
                
                parent.parentController!.classTimes[i] = Double(comps.hour!) + Double(comps.minute!)/60.0
            }
        }
    }
    
}
