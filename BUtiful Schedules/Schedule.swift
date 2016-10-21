//
//  ScheduleLeaf.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/30/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

// Class holding a leaf that represents an individual schedule
// Schedules take the form of a branch of a tree, where the route from the leaf to the head node represents the classes in the schedule
class Schedule {
    
    // getImageURL is almost always called before other functions so nil variables are assigned
    // TODO: don't rely on getImageURL being called (ie. when user is scrolling horizontally through DetailedSchedules
    
    let node : Node                             // Leaf holding end of schedule
    fileprivate static var counter = 0          // Counts number of classes total schedule *static*
    let id : Int                                // Represents the index relative to all scheduels
    fileprivate var image : UIImage?            // Stores the image of the schedule to ensure it doesn't have to download it multiple times
    fileprivate var imageURL : String?          // Stores the computed image URL
    fileprivate var isFull : Bool?              // Indicates if any classes are full
    fileprivate var sections = [[[String]]]()   // Sections are stored as ImageURLs are created (to not have to iterate through list twice) and stored for later use
    fileprivate var sectionTypes = [String]()
    var courseCount = 0                         // Stores number of courses in schedule
    
    private static let PLANNER_PREFIX = "https://www.bu.edu/link/bin/uiscgi_studentlink.pl/1464900788?ModuleName=reg%2Fadd%2Fbrowse_schedule.pl&SearchOptionDesc=Specific+Class%28es%29&SearchOptionCd=N&ViewSem=Spring+2017&KeySem=20174&AddPlannerInd=Y&CurrentCoreInd=N"
    private static let IMAGE_PREFIX = "http://www.bu.edu/uiszl_j2ee/ScheduleImage/ScheduleImageServlet?"
    
    init (node : Node) {
        self.node = node            // Leaf unique to schedule
        self.image = nil
        self.imageURL = nil
        self.id = Schedule.counter  // Sets id to index of current schedule
        Schedule.counter += 1
    }
    
    // Returns if all classes have empty seats
    // TODO: consider changed to isFull?
    func isEmpty() -> Bool? {
        if let isFull = isFull {
            return !isFull
        }
        return nil
    }
    
    // Returns sections from head to leaf (order that the classes were searched in)
    func getSections() -> [[[String]]] {
        return self.sections.reversed()
    }
    
    // Return section types from head to leaf (order searched)
    func getSectionTypes() -> [String] {
        return self.sectionTypes.reversed()
    }
    
    // Create the url to add classes to planner in the form of prefix &College1=...&Dept1=...&Course1=...&Section1=...&College2=...
    // Planners can only add up to 5 at a time so create multiple schedules if there are more than 5 sections
    func getPlannerURLs() -> [String] {
        var urls = [String]()
        var currentURL = Schedule.PLANNER_PREFIX
        var courseNum = 0
        
        for sectionGroup in self.getSections() {
            for section in sectionGroup {
                // Get info for each section
                let info1 = section[Section.TimeBlock.COURSE_ID] as NSString
                
                // Parse courseID into parse, TODO: consider splitting by space
                let college = info1.substring(with: NSRange(location: 0, length: 3))
                let dept = info1.substring(with: NSRange(location: 4, length: 2))
                let course = info1.substring(with: NSRange(location: 6, length: 3))
                let section = section[Section.TimeBlock.NUMBER]
                
                courseNum %= 5
                courseNum += 1
                // If you've already done 5, save the url and start another one
                if courseNum == 1 && currentURL != Schedule.PLANNER_PREFIX {
                    urls.append(currentURL)
                    currentURL = Schedule.PLANNER_PREFIX
                }
                
                // Append to URL
                currentURL += "&College" + String(courseNum) + "=" + college
                currentURL += "&Dept" + String(courseNum) + "=" + dept
                currentURL += "&Course" + String(courseNum) + "=" + course
                currentURL += "&Section" + String(courseNum) + "=" + section
            }
        }
        
        // Add ending URL
        if currentURL != "" {
            urls.append(currentURL)
        }
        return urls
        
    }
    
    // Returns the URL needed to generate the schedule image, while storing info about schedule
    func getImageURL() -> String {
        
        // Return imageURL if computed before
        if let url = imageURL {
            return url
        }
        var URL = Schedule.IMAGE_PREFIX;
        
        var count = 1
        // Iterate through courses, adding onto URL
        var n = self.node
        while let parent = n.parent {
            // Updates schedule variable
            courseCount += 1
            self.sections.append(n.value!.getSections())
            self.sectionTypes.append(n.value!.getSectionType())
            
            // Iterate through sections
            let section = n.value!.getSections()[0]
            for time in n.value!.getTimes() {
                let c = String(count)
                let d = TimeBlock.getDayString(Int(time[2]))
                let tb = TimeBlock.getMilitaryTime(time[0])
                let te = TimeBlock.getMilitaryTime(time[1])
                // URL += "c1=CAS+EC101+BB&d1=Mon&tb1=1200&te1=1300&db1=20160907&de1=20161212&"
                URL += "&c" + c + "=" + section[0] + "+" + section[1]
                URL += "&d" + c + "=" + d
                URL += "&tb" + c + (tb < 1000 ? "=0" : "=") + String(tb)
                URL += "&te" + c + (te < 1000 ? "=0" : "=") + String(te)
                URL += "&db" + c + "=20160907" + "&de" + c + "=20161212"
                count += 1
            }
            // If none of the classes have been full so far, check if all of these sections are
            if isFull == nil || !isFull! {
                var isSectionFull = true
                for sec in n.value!.getSections() {
                    if sec[3] != "0" {
                        isSectionFull = false
                        break
                    }
                }
                if isSectionFull {
                    self.isFull = true
                }
            }
            
            // Move up tree
            n = parent
        }
        // Needed to validate image
        let activityTime = UInt64(Date().timeIntervalSince1970)
        let e = (10000000000 as UInt64) - activityTime
        
        // Add suffix to imageURL, store with instance and then return
        self.imageURL = URL.replaceRegex("\\s", withString: "+")!  + "&e=" + String(e) + "&height=412&width=600&LastActivityTime=" + String(activityTime)
        
        return self.imageURL!
        
    }
    
    // Downloaded Image and then call completion callback, called from downloadImage (below)
    // TODO: consider removing?
    func getDataFromUrl(_ url:URL, completion: @escaping ((_ data: Data?, _ response: URLResponse?, _ error: Error? ) -> Void)) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            completion(data, response, error)
        }.resume()
    }
    
    // Download image and return through callback
    // Store image data upon downloading
    func downloadImage(_ completion: @escaping ()->Void) {
        
        if let url = URL(string: self.getImageURL()) {
            getDataFromUrl(url) { (data, response, error)  in
                DispatchQueue.main.async { () -> Void in
                    guard let data = data , error == nil else {
                        print(error)
                        return
                    }
                    if let img = UIImage(data: data) {
                        self.setImage(img)
                        completion()
                    } else {
                        print("img is null")
                    }
                }
            }
        }
        
    }
    
    func getImage() -> UIImage? {
        return image
    }
    
    // TODO: consider removing?
    func setImage(_ image: UIImage) {
        self.image = image
    }
    
    // Goes through all the filters and see if schedule passes through
    func filter(_ startTime: Double?, endTime: Double?, days: [Bool]?, profs: [[String]]?, hideFull: Bool) -> Bool {
        let empty = self.isEmpty()
        
        if hideFull && empty != nil && !empty! {
            return false
        }
        
        
        var n = self.node
        while n.value != nil {
            if let block = n.value {
                let sectionType = block.getSectionType()
                let courseID = block.getSections()[0][0]

                if let profs = profs {
                    var validProfs = false
                    for section in block.getSections() {
                        let prof = section[2]
                        var validSection = true
                        for filteredProf in profs {
                            if filteredProf == [courseID, sectionType, prof] {
                                validSection = false
                                break
                            }
                        }
                        if validSection {
                            validProfs = true
                            break
                        }
                        
                    }
                    if !validProfs {
                        return false
                    }
                }
                
                if hideFull && empty == nil {
                    var isSectionFull = true
                    for sec in block.getSections() {
                        if sec[3] != "0" {
                            isSectionFull = false
                            break
                        }
                    }
                    if isSectionFull {
                        return false
                    }
                }
                
                for times in block.getTimes() {
                    
                    if let startTime = startTime {
                        if times[0].truncatingRemainder(dividingBy: 24.0) < startTime {
                            return false
                        }
                    }
                    
                    if let endTime = endTime {
                        if times[1].truncatingRemainder(dividingBy: 24) > endTime {
                            return false
                        }
                    }
                    
                    if let days = days {
                        if days[Int(times[2]) - 1] == false {
                            return false
                        }
                    }
                    
                }
            }
            n = n.parent!
        }
        return true
        
    }
    
    
    
}
