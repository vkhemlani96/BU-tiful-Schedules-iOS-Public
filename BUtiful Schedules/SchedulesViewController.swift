//
//  SchedulesViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/26/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit
import PopupDialog

class SchedulesViewController: UITableViewController {
    
    // Holds schedules passing through filter, initially will be set to all schedules
    var schedules : [Leaf]?
    var lastReload = NSDate.timeIntervalSinceReferenceDate
    
    // Sets filter variables
    var classDays = [Bool](repeating: true, count: 5)
    var classTimes = [0, 23.5]
    var professorFilters = [[String]]()
    var hideFull = false
    
    // Holds index of schedule that was selected
    var selectedIndex = 0
    
    // Initializes set of filtered schedules
//    override func viewWillAppear() {
//        if schedules == nil {
//            schedules = FilterManager.FILTERED_SCHEDULES      //TODO CHange Leaf
//        }
//    }
    
    // Adjusts layout based on schedules, called upon return from other controllers
    override func viewWillAppear(_ animated: Bool) {
        if lastReload != FilterManager.lastFilteredAt {
            schedules = FilterManager.FILTERED_SCHEDULES
            tableView.reloadData()
        }
        
        // Set title to count of schedules, will needed to be changed when return from filters controller
        if let schedules = schedules {
            self.title = "\(schedules.count) Schedules Found"
        }
        
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let schedules = schedules {
            return schedules.count
        }
        return 0
    }
    
    // On selection of a schedule, set selectedIndex and transition to DetailedScheduleController
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = (indexPath as NSIndexPath).row
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "popupViewController") as! PopupViewController
        vc.setSchedule(schedule: schedules![selectedIndex])
        
        // Create the dialog
        let popup = PopupDialog(viewController: vc, buttonAlignment: .horizontal, transitionStyle: .bounceUp, gestureDismissal: true, completion: nil)
        let pv = PopupDialogDefaultView.appearance()
        pv.layer.cornerRadius = 0
        popup.viewController.view.frame = CGRect(x: 0, y: 0, width: 350, height: 500)
        
        let screenSize: CGRect = UIScreen.main.bounds
        
        let xImage = UIImageView(frame: CGRect(x: (screenSize.width/2)-12.5, y: screenSize.height-50, width: 25, height: 25))
        xImage.image = UIImage(named: "Delete (White)")
        popup.view.addSubview(xImage)
        
        let overlay = PopupDialogOverlayView.appearance()
        overlay.blurRadius = 5
        
        let buttons = [
            DefaultButton(title:"Save Image"){},
            DefaultButton(title:"Add to Planner"){}
        ]
        DefaultButton.appearance().separatorColor = UIColor(white: 1.0, alpha:0.6)
        DefaultButton.appearance().buttonColor = UIColor(red:0.75, green:0.00, blue:0.02, alpha:1.0)
        DefaultButton.appearance().titleColor = UIColor.white
        
        
        popup.addButtons(buttons)
        
        // Present dialog
        present(popup, animated: true, completion: nil)
        tableView.reloadRows(at: [IndexPath(row: selectedIndex, section: 0)], with: .none)
    }
    
    // Create cell for each table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "scheduleCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ScheduleCell
        
        // Clear image of the cell (in case one was deleted and order had to be redone)
        cell.scheduleImageView.image = nil
        
        let schedule = self.schedules![(indexPath as NSIndexPath).row]
        
        // If image has already been loaded, display it and stop the loading animation
        if let img = schedule.getImage() {
            cell.scheduleImageView.image = img
            cell.loadingIndicator.stopAnimating()
//            cell.exclamationImage.isHidden = schedule.isEmpty()!  -  TODO
            cell.exclamationImage.isHidden = true
        } else {
            print("ERROR---------\t\tImage not found")
        }
        
        return cell
        
    }
    
    // Filters out unwanted schedules
    func filter() {
        
//        let shouldFilter = classDays != [Bool](repeating: true, count: 5) || classTimes != [0, 23.5] || professorFilters.count > 0 || hideFull
//        // If any filter has been applied, begin filtering
//        if shouldFilter {
//            
//            let startTime : Double? = classTimes[0] == 0 ? nil : classTimes[0]
//            let endTime : Double? = classTimes[1] == 23.5 ? nil : classTimes[1]
//            let days : [Bool]? = classDays == [Bool](repeating: true, count: 5) ? nil : classDays
//            let profs : [[String]]? = professorFilters.count == 0 ? nil : professorFilters
//            
//            var filteredSchedules = [Leaf]()
//            for schedule in self.filteredSchedules! {
//                if (schedule.filter(startTime, endTime: endTime, days: days, profs: profs, hideFull: hideFull)) {
//                    filteredSchedules += [schedule]
//                }
//            }
//            
//            self.filteredSchedules = filteredSchedules
//        } else {
//            // Otherwise, display alls chedules
//            self.filteredSchedules = CourseList.SCHEDULE_LEAVES
//        }
//        
//        // Update count with new schedules
//        self.title = String(filteredSchedules!.count) + " Schedules Found"
//        
//        // Display back button with count on detailed schedules controller to indicate change
//        let backItem = UIBarButtonItem()
//        backItem.title = String(filteredSchedules!.count) + " Schedules Found"
//        navigationItem.backBarButtonItem = backItem
//        
//        // Reload all cells
//        tableView.reloadData()
    }
    
    // Handle removal of specific schedule
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Remove from filtered schedules and entire course list to not appear in current results
            let leafId = schedules![(indexPath as NSIndexPath).row].getID()
            CourseList.removeSchedule(leafId)
            schedules?.remove(at: (indexPath as NSIndexPath).row)
            
            // Fade out views and update count
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.title = String(schedules!.count) + " Schedules Found"
            
        }
    }
    
    // Used in ClassProfTableViewController to check if a professor has already been filtered,
    // Implemented here to ensure saved state
    func isProfessorFiltered(_ data: [String]) -> Bool {
        for prof in professorFilters {
            if prof[0] == data[0] && prof[1] == data[1] && prof[2] == data[2] {
                return true
            }
        }
        return false
    }
    
    // Removes professor from filter, see above function for more info
    func removeProfessorFilter(_ data : [String]) {
        for i in 0..<professorFilters.count {
            let prof = professorFilters[i]
            if prof[0] == data[0] && prof[1] == data[1] && prof[2] == data[2] {
                professorFilters.remove(at: i)
            }
        }
    }
    
    // Prepare layout based on segue (sets parent controller for children)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "filterSegue" {
            let s = segue.destination as! FilterTableViewController
            s.parentController = self
        } else if segue.identifier == "detailsSegue" {
            // Show back button item
            let backItem = UIBarButtonItem()
            backItem.title = String(schedules!.count)
            navigationItem.backBarButtonItem = backItem
            
            let s = segue.destination as! DetailedScheduleViewController
            s.parentController = self
            s.index = selectedIndex
            tableView.reloadRows(at: [IndexPath(row: selectedIndex, section: 0)], with: .none)
            print(CourseList.SCHEDULE_LEAVES[selectedIndex].getPlannerURLs())
        }
    }
    
}
