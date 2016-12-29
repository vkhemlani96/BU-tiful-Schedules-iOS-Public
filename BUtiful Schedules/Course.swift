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
    private var sectionTypes = [String]()
    fileprivate var courseMap = [String : SectionType]()        // Dictionary to group timeblocks by section type ["Lecture": SectionType]
    
    override init() {}
    init(sectionInfo : [String]) {
        super.init()
        courseID = sectionInfo[Section.COURSE_ID]
        self.addTimeBlock(sectionInfo)
    }
    
    func getCourseMap() -> [String: SectionType] {
        return courseMap
    }
    
    func getSectionTypes() -> [String] {
        return sectionTypes
    }
    
    func getCourseID() -> String {
        return courseID
    }
    
    func testPrint() {
        print(courseID)
        for type in self.sectionTypes {
            print(type)
            for block in courseMap[type]!.getTimeBlocks() {
                block.testPrint()
            }
        }
    }
    
    func testPrintProf() {
        for type in self.sectionTypes {
            self[type].testPrintProf()
        }
    }
    
    // Takes in the sectionID, finds it and then returns the section type
    func getSectionType(_ sectionID : String) -> String? {
        for type in sectionTypes {
            for blocks in courseMap[type]!.getTimeBlocks() {
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
        for type in self.sectionTypes {
            for block in courseMap[type]!.getTimeBlocks() {
                block.determineConditions()
            }
        }
    }
    
    // Add section to corresponding TimeBlock
    func addTimeBlock(_ sectionInfo : [String]) {
        
        let type = sectionInfo[Section.TYPE]
        
        // If the sectionType doesn't already exist, add it to the key list and the dictionary
        if !sectionTypes.contains(type) {
            sectionTypes.append(type)
            courseMap[type] = SectionType(course: self, name: type)
        }
        
        // Add the timeblock to the corresponding type
        courseMap[type]?.addTimeBlock(sectionInfo: sectionInfo)
        
    }
    
    subscript(sectionType: String) -> SectionType {
        get {
            return courseMap[sectionType]!
        }
    }
    
    
}
