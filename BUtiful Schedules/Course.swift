//
//  Course.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/22/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class Course: NSObject {
    
    fileprivate var courseID = ""                               // "CAS EC 101"
    fileprivate var courseMap = [String : [TimeBlock]]()        // Dictionary to group timeblocks by section type ["Lecture": [TimeBlocks]]
    fileprivate var courseProf = [String : [String : Bool]]()   // ["Lecture":[["Watson":false], ["Prof2":false]]]
    var sortedKeys : [String]?;
    
    override init() {}
    init(sectionInfo : [String]) {
        courseID = sectionInfo[Section.COURSE_ID]
    }
    
    func getCourseMap() -> [String: [TimeBlock]] {
        return courseMap
    }
    
    // Sorts keys so that Lecture is first, Discussion is section and then the rest remain in order.
    // TODO: Remove discussion check?
    func getCourseMapKeys() -> [String] {
        if let keys = sortedKeys {
            return keys
        }
        func sortFunc(key1: String, key2: String) -> Bool {
            if key1 == "Lecture" {
                return true
            }
            if key2 == "Lecture" {
                return false
            }
            if key1 == "Discussion" {
                return true
            }
            if key2 == "Discussion" {
                return false
            }
            return true
        }
        sortedKeys = courseMap.keys.sorted(by: sortFunc);
        return sortedKeys!
    }
    
    func getCourseID() -> String {
        return courseID
    }
    
    func getProfessors() -> [String : [String: Bool]] {
        return courseProf
    }
    
    func updateProfessors(_ key: String, val: [String: Bool]) {
        courseProf.updateValue(val, forKey: key)
    }
    
    func testPrint() {
        print(courseID)
        for key in self.getCourseMapKeys() {
            print(key)
            for block in courseMap[key]! {
                block.testPrint()
            }
        }
    }
    
    // Takes in the sectionID, finds it and then returns the section type
    func getSectionType(_ sectionID : String) -> String? {
        let sectionTypes = self.getCourseMapKeys()
        for type in sectionTypes {
            for blocks in courseMap[type]! {
                for block in blocks.getSections() {
                    if block[1] == sectionID {
                        return type
                    }
                }
            }
        }
        return nil
    }

    // Check if ID's for either sectionInfo[] or Course object
    override func isEqual(_ object: Any?) -> Bool {
        if let o = object as? [String] {
            return o[0] == self.courseID
        } else if let o = object as? Course {
            return o.getCourseID() == self.courseID
        }
        return false
    }
    
    // See determineConditions in TimeBlock.swift
    func determineConditions() {
        for key in self.getCourseMapKeys() {
            for block in courseMap[key]! {
                block.determineConditions()
            }
        }
    }
    
    // Add section to corresponding TimeBlock
    func addTimeBlock(_ sectionInfo : [String]) {
        
        let type = sectionInfo[Section.TYPE]
        // If timeblocks exists, see if the section fits in it
        if var timeBlocks = courseMap[type] {
            for block in timeBlocks {
                // If section fits into timeblock, append it
                if block.isArrayEqual(sectionInfo) {
                    block.addSection(sectionInfo)
                    return
                }
            }
            
            // If the section doesn't fit in any, create a new one
            let newBlock = TimeBlock(course: self, sectionType: sectionInfo[Section.TYPE])
            newBlock.addSection(sectionInfo)
            timeBlocks += [newBlock]
            courseMap.updateValue(timeBlocks, forKey: sectionInfo[Section.TYPE])
        } else {
            // If the timeblock doesnt exist, create a new one
            let newBlock = TimeBlock(course: self, sectionType: sectionInfo[Section.TYPE])
            newBlock.addSection(sectionInfo)
            courseMap[sectionInfo[Section.TYPE]] = [newBlock]
        }
        
        // Add professor to array if professor doesn't already
        if var profs = courseProf[type] {
            if !profs.keys.contains(sectionInfo[Section.PROFESSOR]) {
                profs.updateValue(false, forKey: sectionInfo[Section.PROFESSOR])
                courseProf.updateValue(profs, forKey: type)
            }
        } else {
            courseProf[type] = [sectionInfo[Section.PROFESSOR] : false]
        }
        
        
    }
    
    
}
