//
//  HomeTableViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 8/25/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit
import Alamofire
import Kanna

class HomeTableViewController: UITableViewController {
    
    let unknownChar = " " //NOT SPACE, ASCII CODE 160 aka. &nbsp;

    /*
     * Init global variables used throughout class
     */
    
    var classCount = 0                  // Used to know how many class text fields to create and how many GET request responses to expect
    var courseFields = [CourseView]()   // Stores the views containing the text fields to read from
    var finished = false                // Flag used to ensure finished processes is only called once as a result of request responses, TODO: consider removing
    
    var coursesParsed = 0               // Keeps count of how many request reponses have been received
    var listCell : ClassListCell?       // Store the final listCell containing the text fields so the goButton can be retrieved when needed, TODO: consider removing and using built-in function to retrieve cell when needed
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Disables over-scrolling
        self.tableView.bounces = false
    }
    
    @IBAction func classCountNext(_ sender: UIButton) {
//         Parse field to get count
                let cell = tableView.cellForRow(at: IndexPath(item: 1, section: 0)) as! ClassCountCell
                classCount = Int(cell.classCountField.text!)!
        
                // Creates an array to hold course info with correct size
                CourseList.reset(classCount);
                print("Count \(classCount)")
        
                let screenSize: CGRect = UIScreen.main.bounds
                let offset = 271;   // Size + padding of elements above
        
                // Create and hold subviews
                for i in 0..<classCount {
                    let view = CourseView(frame: CGRect(x: 0, y: offset + (i*40), width: Int(screenSize.width), height:40), screenWidth: Int(screenSize.width), controller: self, index: i)
                    courseFields += [view]
                    self.view.addSubview(view)
                }
        
                // Update table to recreate cells
                tableView.beginUpdates()
                tableView.endUpdates()
        
                // Focus on first text field so user can began typing
                chooseNextResponder(0)
                
                // Scroll text fields into view
                tableView.scrollToRow(at: IndexPath(row: 2, section: 0), at: UITableViewScrollPosition.bottom, animated: true)

    }
    /*
     *  Called when the user enters the number of classes and presses Next.
     *  Creates the correct amount of text fields and transitions to cell showing fields
     */
//    @IBAction func classCountNext(_ sender: AnyObject) {
//        // Parse field to get count
//        let cell = tableView.cellForRow(at: IndexPath(item: 1, section: 0)) as! ClassCountCell
//        classCount = Int(cell.classCountField.text!)!
//        
//        // Creates an array to hold course info with correct size
//        CourseList.reset(classCount);
//        print("Count \(classCount)")
//        
//        let screenSize: CGRect = UIScreen.main.bounds
//        let offset = 271;   // Size + padding of elements above
//        
//        // Create and hold subviews
//        for i in 0..<classCount {
//            let view = CourseView(frame: CGRect(x: 0, y: offset + (i*40), width: Int(screenSize.width), height:40), screenWidth: Int(screenSize.width), controller: self, index: i)
//            courseFields += [view]
//            self.view.addSubview(view)
//        }
//        
//        // Update table to recreate cells
//        tableView.beginUpdates()
//        tableView.endUpdates()
//        
//        // Focus on first text field so user can began typing
//        chooseNextResponder(0)
//        
//        // Scroll text fields into view
//        tableView.scrollToRow(at: IndexPath(row: 2, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
//    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3 // Heading cell, course count cell, course fields cell
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath as NSIndexPath).row {
        case 0:
            return tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath)
        case 1:
            return tableView.dequeueReusableCell(withIdentifier: "classCount", for: indexPath)
        case 2:
            listCell = (tableView.dequeueReusableCell(withIdentifier: "classList", for: indexPath) as! ClassListCell)
            listCell!.goButton.isEnabled = false
            listCell!.goButton.alpha = 0.4 as CGFloat
            return listCell!
        default:
            return tableView.dequeueReusableCell(withIdentifier: "titleCell", for: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ((indexPath as NSIndexPath).row == 0) {
            return 210;
        }
        if (classCount > 0) {
            // Each field takes us 40px including padding + external padding for cell
            return (indexPath as NSIndexPath).row == 1 ? 0 : CGFloat(123 + classCount * 40)
        } else {
            return (indexPath as NSIndexPath).row == 1 ? 156 : 0
        }
    }
    
    // Automatically move cursor to next field (index = current + 1)
    func chooseNextResponder(_ index: Int) {
        if index < classCount {
            courseFields[index].becomeFirstResponder();
        }
    }
    
    //  Make request for course
    func makeGetRequestForCourse(_ courseInfo: [String], viewIndex: Int) {
        // Use URL template to create complete URL for
        var URL = "https://www.bu.edu/link/bin/uiscgi_studentlink.pl/1476809936?ModuleName=univschr.pl&SearchOptionDesc=Class+Number&SearchOptionCd=S&KeySem=20174&ViewSem=Spring+2017&College=\(courseInfo[0])&Dept=\(courseInfo[1])&Course=\(courseInfo[2])"
        
        // Used if courses overflowed onto multiple pages (requiring multiple requests), have needed section to begin next search
        if courseInfo.count == 4{
            URL += "&Section=\(courseInfo[3])"
        }
        
        // Send request
        Alamofire.request(URL)
            .responseString { response in
                self.parseHTMLForClass(response.result.value!, courseInfo: courseInfo, viewIndex: viewIndex)
        }
    }
    
    // Callback from request, used to parse response
    func parseHTMLForClass(_ html: String, courseInfo: [String], viewIndex : Int) {
        
        //Convert to HTMLDocument class
        if let doc = Kanna.HTML(html: html, encoding: String.Encoding.utf8) {
            var condition : String?
            var foundSections = false
            
            // Valid data is present in rows of fourth table present on page
            // Mark as invalid if data not found
            
            if (doc.css("body > table").nodeSetValue.count < 3 || doc.css("body > table")[3].css("tr").nodeSetValue.count == 0) {
                print("did not find sections")
                courseFields[viewIndex].failed()
                return;
            }
            
            // Each row contains either condition or data on a class
            for row in doc.css("body > table")[3].css("tr") {
                
                //Selects condition row (one that doesnt
                if row.at_css("table") != nil {
                    
                    // Conditions usually contain the word 'must' followed by section letters/numbers (ie. Lecture AA must have a discussion A1 to A5
                    // In the future, gather more data on how to interpret conditions
                    var conditionText = row.text!.regexMatches("must(.)*\\W([A-Z]){1}([0-9]){1}")
                    if conditionText.count > 0 {
                        // Usually only one condition in text
                        condition = conditionText[0] //TODO multiple conditions in multiple rows?
                        
                        // Must also register for a discussion section B2-B3 and a lab section A2 or A5 -> "B2-B3|A2 or A5"
                        condition = condition!.regexMatches("[A-Z]{1}[0-9]{1}.*[A-Z]{1}[0-9]{1}").joined(separator: "|")
                    }
                    
                } else if let innerHTML = row.innerHTML {
                    // Found data on a course
                    if innerHTML.range(of: courseInfo[0] + unknownChar + courseInfo[1] + courseInfo[2]) != nil {
                        //Parses course info
                        foundSections = true
                        var sectionInfo = parseCourseLine(row)
                        
                        if let foundCondition = condition {
                            sectionInfo += [foundCondition]
                            condition = nil // Condition is applied onto Course, not each individual section, so only need to add it to one section, will be interpreted when added to CourseList class
                            
                        }
                        
                        // Add to CourseList for further organization
                        // Put it in the correct viewIndex, used in case user changes already downloaded data for a class, overrides that
                        CourseList.add(sectionInfo, index: viewIndex)
                    }
                }
            }
            
            // If no rows matched, class doesn't exist, mark as failed
            if !foundSections {
                courseFields[viewIndex].failed()
                return;
            }
            
            // Parse input field at bottom of webpage for next course to search
            let nextCourseInputs = [
                doc.css("input[name='College']")[0].toHTML?.regexMatches("value=\"\\w{3}"),
                doc.css("input[name='Dept']")[0].toHTML?.regexMatches("value=\"\\w{2}"),
                doc.css("input[name='Course']")[0].toHTML?.regexMatches("value=\"\\w{3}"),
                doc.css("input[name='Section']")[0].toHTML?.regexMatches("value=\"\\w{2}")
            ]
            let nextCourse = nextCourseInputs.map({(($0?.count)! > 0 ? $0?[0] : nil)?.replacingOccurrences(of: "value=\"", with: "")})
            
            // If course has the same college, dept and number, it is the section of the same class. This means that the class didn't fit into one page (i.e. many CAS EC 101 classes) so you must parse the next page
            if let nextCourseColl = nextCourse[0], let nextCourseDept = nextCourse[1], let nextCourseSec = nextCourse[2] {
                
                if nextCourseColl == courseInfo[0] && nextCourseDept == courseInfo[1] && nextCourseSec == courseInfo[2] {
                    makeGetRequestForCourse(nextCourse.map({$0!}), viewIndex: viewIndex)
                } else {    // Otherwise done with the class, mark as success
                    coursesParsed += 1
                    courseFields[viewIndex].success()
                }
                
            } else {    // If values are not present and cannot be parsed, mark as success
                coursesParsed += 1
                courseFields[viewIndex].success()
            }
        } else {    // If could not parse as HTML, mark as failed. TODO: consider further error checking
            courseFields[viewIndex].failed()
        }
        
        // If this was the final class, begin finished operations.
        if (coursesParsed == classCount) {
            finishedLoadingCourses();
            print("FINISHED");
        }
        
    }
    
    // Parses row from webpage into formatted data in a string array
    func parseCourseLine(_ node: XMLElement) -> [String] {
        var i = 0
        var sectionInfo = [String]()
        
        for text in node.css("font") {
            
            // Skip these 4 indecies
            if (i == 0 || i == 3 || i == 4 || i == 12) {
                i += 1
                continue
            } else if (i == 1) {
                // Course Code - ex. CAS EC101 A1 -> ["CAS EC101", "A1"]
                sectionInfo +=
                    [text.text!.regexMatches(".+\\d{3}")[0], String(text.text!.characters.suffix(2))]
            } else if (i == 2) {
                // Professor - ex. Intro Micro<br><a...>Watson</a> -> ["Watson"]
                sectionInfo += [text.innerHTML!.regexMatches("<br>.+")[0].replacingOccurrences(of: "<br>", with: "").replaceRegex("<a.+\">|<\\/a>", withString:"")!]
            } else if (i == 7) {
                // Room - ex. <a....></a>PHO<br>ARR... -> ["PHO<br>ARR"]
                sectionInfo += [text.innerHTML!.trim().replaceRegex("<a.+\">|<\\/a>", withString:"")!]
            } else {
                // Class Type, Days, etc. ex. ["Discussion"] or ["Mon,Wed<br>Fri"]
                sectionInfo += [text.innerHTML!.trim()]
            }
            
            i += 1
            
        }
        
        return sectionInfo
    }
    
    // Creates schedules once all the courses are found
    func finishedLoadingCourses() {
        // Checks to make sure function is not called twice, TODO: consider removing?
        if !finished {
            finished = true
            // Generates schedules
            CourseList.findWorkingSchedules()
            
            // Enabled go button
            if let cell = listCell {
                cell.goButton.isEnabled = true
                cell.goButton.alpha = 1
            }
        }
    }

    // Transitions to SchedulesViewController (displays graphical view of all schedules)
    @IBAction func onGoPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        self.performSegue(withIdentifier: "schedulesSegue", sender: self)
    }

}

class ClassCountCell: UITableViewCell {
    @IBOutlet weak var classCountField: UITextField!
    
}

class ClassListCell: UITableViewCell {
    @IBOutlet weak var goButton: UIButton!
    
}
