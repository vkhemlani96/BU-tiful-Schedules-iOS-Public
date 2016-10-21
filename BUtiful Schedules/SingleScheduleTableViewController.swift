//
//  SingleScheduleTableViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/31/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class SingleScheduleTableViewController: UITableViewController {
    
    var schedule : Schedule?
    var index = 0
    var parentController : DetailedScheduleViewController?

    override func viewDidAppear(_ animated: Bool) {
        parentController!.index = self.index
        parentController!.navigationController?.isToolbarHidden = false
    }

    // Rows contained in one section
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    // Return number of rows representing courses plus one for the picture
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schedule!.courseCount + 1
    }
    
    //
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).row == 0 {
            let screenWidth = self.view.frame.width
            let widthToHeightRatio = CGFloat(0.6866666667)
            let padding = CGFloat(10.0)
            
            return (screenWidth * widthToHeightRatio) + padding
        }
        
        //
        let x = CGFloat(schedule!.getSections()[(indexPath as NSIndexPath).row-1].count)
        return 19.5 + 9 + 17.5*x + 16
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // If cell is for image
        if (indexPath as NSIndexPath).row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! SingleScheduleImageTableViewCell
            // If the image has been loaded, display it and hide the loading indicator
            if let img = schedule!.getImage() {
                cell.scheduleImageView.image = nil  // Image would not appear without this
                cell.scheduleImageView.image = img
                cell.activityIndicator.isHidden = true
                cell.activityIndicator.stopAnimating()
            } else {
                // If not, show the loading indicator and download the image
                cell.activityIndicator.startAnimating()
                schedule!.downloadImage({ ()->Void in
                    DispatchQueue.main.async(execute: { () -> Void in
                        
                        // Reload the cell once the image loads
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
        
        // If cell is not for the image
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath) as! ScheduleDetailTableViewCell
        let sections = schedule!.getSections()[(indexPath as NSIndexPath).row-1] //-1 offset for image cell
        
        var showTitle = true    // Course name
        
        if ((indexPath as NSIndexPath).row > 1) {
            // If the previous section is a part of the same course, hide the course title
            let lastSection = schedule!.getSections()[(indexPath as NSIndexPath).row-2]
            showTitle = lastSection[0][0] != sections[0][0]
        }
        
        // Show/hide the title
        if showTitle {
            cell.titleView.text = sections[0][0]
        } else {
            cell.titleView.isHidden = true
        }
        
        // Show Discussion, Lecture, Lab, etc.
        cell.detailSubtitleView.text = schedule!.getSectionTypes()[(indexPath as NSIndexPath).row-1]
        
        // Display up to three sections
        let views = [cell.detail1View, cell.detail2View, cell.detail3View]
        for i in 0..<sections.count {
            
            let section = sections[i]
            let view = views[i]
            
            // Concat text in the form of "A1: Idson, STO B50, 250 Seats
            // STO B50 only appears if a room is given
            var text = section[Section.TimeBlock.NUMBER]
            text += ": " + section[Section.TimeBlock.PROFESSOR]
            if (section[Section.TimeBlock.BUILDING].characters.count > 0) {
                text += ", " + section[Section.TimeBlock.BUILDING]
                text += " " + section[Section.TimeBlock.ROOM]
            }
            text += ", " + section[Section.TimeBlock.SEATS] + " Seats"
            
            // If the class is full, strikethrough the line
            if text.range(of: " 0 Seats") != nil {
                let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: text)
                // Strikethrough from first character through entire line
                attributeString.addAttribute(NSStrikethroughStyleAttributeName, value: 1, range: NSMakeRange(0, text.characters.count))
                view?.attributedText = attributeString
            } else {
                // Otherwise, just display the text normally
                view?.text = text
            }
            
        }
        
        // If there are less than three sections, hide the rest of the views.
        for i in sections.count..<3 {
            views[i]?.isHidden = true
        }

        return cell
    }
    
    

}
