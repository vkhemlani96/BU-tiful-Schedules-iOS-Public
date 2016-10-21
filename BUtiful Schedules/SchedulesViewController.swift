//
//  SchedulesViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/26/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class SchedulesViewController: UITableViewController {
    
    // Holds schedules passing through filter, initially will be set to all schedules
    var filteredSchedules : [Schedule]?
    
    // Sets filter variables
    var classDays = [Bool](repeating: true, count: 5)
    var classTimes = [0, 23.5]
    var professorFilters = [[String]]()
    var hideFull = false
    
    // Holds index of schedule that was selected
    var selectedIndex = 0
    
    // Initializes set of filtered schedules
    override func awakeFromNib() {
        if filteredSchedules == nil {
            filteredSchedules = CourseList.SCHEDULE_LEAVES
        }
    }
    
    // Adjusts layout based on schedules, called upon return from other controllers
    override func viewWillAppear(_ animated: Bool) {
        // Set title to count of schedules, will needed to be changed when return from filters controller
        if let schedules = filteredSchedules {
            self.title = String(schedules.count) + " Schedules Found"
        }
        
        // Scroll to selected schedule, can be changed by swiping within DetailedScheduleController
        let row = selectedIndex == 0 ? 0 : selectedIndex-1  // Go up one so that selected schedule is closer to middle of the screen
//        tableView.scrollToRow(at: IndexPath.init(row: row, section: 0), at: UITableViewScrollPosition.middle, animated: false)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let schedules = filteredSchedules {
            return schedules.count
        }
        return 0
    }
    
    // On selection of a schedule, set selectedIndex and transition to DetailedScheduleController
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = (indexPath as NSIndexPath).row
        self.performSegue(withIdentifier: "detailsSegue", sender: self)
    }
    
    // Create cell for each table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "scheduleCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ScheduleCell
        
        // Clear image of the cell (in case one was deleted and order had to be redone)
        cell.scheduleImageView.image = nil
        
        let schedule = self.filteredSchedules![(indexPath as NSIndexPath).row]
        
        // If image has already been loaded, display it and stop the loading animation
        if let img = schedule.getImage() {
            cell.scheduleImageView.image = img
            cell.loadingIndicator.stopAnimating()
//            cell.exclamationImage.isHidden = schedule.isEmpty()!  -  TODO
            cell.exclamationImage.isHidden = true
        } else {
            // Otherwise, animate the loading indicator and begin downloading the image
            cell.loadingIndicator.startAnimating()
            
            schedule.downloadImage({ ()->Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    // Once downloaded, update correct row
                    self.tableView!.beginUpdates()
                    if let t = self.tableView {
                        t.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                    }
                    self.tableView!.endUpdates()
                })
            })
        }
        
        return cell
        
    }
    
    // Filters out unwanted schedules
    func filter() {
        
        let shouldFilter = classDays != [Bool](repeating: true, count: 5) || classTimes != [0, 23.5] || professorFilters.count > 0 || hideFull
        // If any filter has been applied, begin filtering
        if shouldFilter {
            
            let startTime : Double? = classTimes[0] == 0 ? nil : classTimes[0]
            let endTime : Double? = classTimes[1] == 23.5 ? nil : classTimes[1]
            let days : [Bool]? = classDays == [Bool](repeating: true, count: 5) ? nil : classDays
            let profs : [[String]]? = professorFilters.count == 0 ? nil : professorFilters
            
            var filteredSchedules = [Schedule]()
            for schedule in self.filteredSchedules! {
                if (schedule.filter(startTime, endTime: endTime, days: days, profs: profs, hideFull: hideFull)) {
                    filteredSchedules += [schedule]
                }
            }
            
            self.filteredSchedules = filteredSchedules
        } else {
            // Otherwise, display alls chedules
            self.filteredSchedules = CourseList.SCHEDULE_LEAVES
        }
        
        // Update count with new schedules
        self.title = String(filteredSchedules!.count) + " Schedules Found"
        
        // Display back button with count on detailed schedules controller to indicate change
        let backItem = UIBarButtonItem()
        backItem.title = String(filteredSchedules!.count) + " Schedules Found"
        navigationItem.backBarButtonItem = backItem
        
        // Reload all cells
        tableView.reloadData()
    }
    
    // Handle removal of specific schedule
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Remove from filtered schedules and entire course list to not appear in current results
            let leafId = filteredSchedules![(indexPath as NSIndexPath).row].id
            CourseList.removeSchedule(leafId)
            filteredSchedules?.remove(at: (indexPath as NSIndexPath).row)
            
            // Fade out views and update count
            tableView.deleteRows(at: [indexPath], with: .fade)
            self.title = String(filteredSchedules!.count) + " Schedules Found"
            
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
            backItem.title = String(filteredSchedules!.count)
            navigationItem.backBarButtonItem = backItem
            
            let s = segue.destination as! DetailedScheduleViewController
            s.parentController = self
            s.index = selectedIndex
            tableView.reloadRows(at: [IndexPath(row: selectedIndex, section: 0)], with: .none)
        }
    }
    
}
