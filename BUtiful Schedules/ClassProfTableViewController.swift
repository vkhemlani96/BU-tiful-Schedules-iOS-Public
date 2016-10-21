//
//  ClassProfTableViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/29/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class ClassProfTableViewController: UITableViewController {
    
    var course = Course()
    var parentController : FilterTableViewController?
    var potentials = [IndexPath: Int]()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return course.getProfessors().keys.count
    }
    
    // Sections = type of class (Lecture, Discussion, Lab, etc.)
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Array(course.getProfessors().keys)[section]
    }

    // Rows = number of professors teaching type of class
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = Array(course.getProfessors().keys)[section];
        let profList = course.getProfessors()[key]!.keys
        return profList.count
    }

    // Create cell for each professor
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profCell", for: indexPath) as! ProfessorTableViewCell
        let profs = course.getProfessors()
        
        // Get professor name
        let type = Array(profs.keys)[(indexPath as NSIndexPath).section]
        let profName = Array(profs[type]!.keys)[(indexPath as NSIndexPath).row]
        let possible = profs[type]![profName]!
        
        // Set vars needed to filter
        cell.courseCode = course.getCourseID()
        cell.sectionType = type
        cell.professor = profName
        
        // If professor has any schedules available
        if possible {
            cell.textLabel?.text = profName
            
            let data = [course.getCourseID(), type, profName]
            // Set checkmark based on already filtered
            if parentController!.parentController!.isProfessorFiltered(data) {
                cell.accessoryType = UITableViewCellAccessoryType.none
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            }
            
            // Set count of schedules contained by professor
            displayScheduleCount(cell, indexPath: indexPath, data: data)
        } else {
            
            // Don't allow the user to select professors with no classes
            cell.isUserInteractionEnabled = false
            cell.textLabel?.textColor = UIColor.gray
            
            // Strikethrough out professor name and no possible schedules
            let profString: NSMutableAttributedString =  NSMutableAttributedString(string: profName)
            profString.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, profString.length))
            cell.textLabel?.attributedText = profString
            
            let detailedString: NSMutableAttributedString =  NSMutableAttributedString(string: "No Possible Schedules")
            detailedString.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, detailedString.length))
            cell.detailTextLabel?.attributedText = detailedString
            cell.accessoryType = UITableViewCellAccessoryType.none
        }

        return cell
    }
    
    // On select, toggle checkmark and update cell and filters
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)! as! ProfessorTableViewCell
        let data = [cell.courseCode, cell.sectionType, cell.professor]
        let filtered = cell.accessoryType == UITableViewCellAccessoryType.none
        
        if filtered {
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
            parentController!.parentController!.removeProfessorFilter(data)
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.none
            parentController!.parentController!.professorFilters.append(data)
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
        
    }
    
    // Show schedule counts for each professor
    func displayScheduleCount(_ cell : UITableViewCell, indexPath: IndexPath, data: [String]) {
        cell.textLabel!.font = UIFont.systemFont(ofSize: 16.0)
        
        // If count has already been calculated, display it
        if let calculated = potentials[indexPath] {
            cell.detailTextLabel?.text = String(calculated) + " Schedules"
        } else {
            // Otherwise, calculate it in background, show "Calculating..." in meantime, update when found a new one
            DispatchQueue.main.async(execute: { () -> Void in
                self.potentials.updateValue(self.calculateSchedules(data), forKey: indexPath)
                
                self.tableView!.beginUpdates()
                self.tableView!.reloadRows(
                    at: [indexPath],
                    with: UITableViewRowAnimation.none)
                self.tableView!.endUpdates()
            })
            cell.detailTextLabel?.text = "Calculating..."
        }
    }
    
    // Use helperfunction (calcHelper) to calculate number of schedules using professor
    fileprivate func calculateSchedules(_ data: [String]) -> Int {
        var count = 0
        for leaf in CourseList.SCHEDULE_LEAVES {
            if calcHelper(leaf.node, data: data) {
                count += 1
            }
        }
        return count
    }
    
    fileprivate func calcHelper(_ n: Node, data: [String]) -> Bool {
        
        if let val = n.value {
            let sections = val.getSections()
            // Check if section is the right type of section and course
            if sections[0][0] == data[0] && n.value!.getSectionType() == data[1] {
                // Check if any time blocks have the professor, if so, return true, otherwise return false
                for section in sections {
                    if section[2] == data[2] {
                        return true
                    }
                }
                return false
            }
            return calcHelper(n.parent!, data: data)
        }
        // If value null, reached the head, return false (should never occur)
        return false
        
    }

}
