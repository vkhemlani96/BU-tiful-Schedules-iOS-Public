//
//  SectionType.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 12/24/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import Foundation

class SectionType {
    
    private var course : Course
    private var name : String
    private var colorIndex = -1
    private var professors = [String : Int]()
    private var timeBlocks = [TimeBlock]()
    
    init(course: Course, name: String) {
        self.course = course
        self.name = name
    }
    
    func getCourse() -> Course {
        return course
    }
    
    func getName() -> String {
        return name
    }
    
    func getColorIndex() -> Int {
        return colorIndex
    }
    
    func setColorIndex(i : Int) {
        colorIndex = i
    }
    
    func getProfessors() -> [String: Int] {
        return professors
    }
    
    func foundProfessor(professor: String) {
        professors[professor]! += 1
    }
    
    func addTimeBlock(sectionInfo : [String]) {
        
        var foundExisting = false
        for block in timeBlocks {
            // If section fits into an existing timeblock, append it
            if block.isArrayEqual(sectionInfo) {
                block.addSection(sectionInfo)
                foundExisting = true
            }
        }
        
        // If the section doesn't fit in any, create a new one
        if !foundExisting {
            let newBlock = TimeBlock(sectionType: self)
            newBlock.addSection(sectionInfo)
            timeBlocks += [newBlock]
        }
        
        let professor = sectionInfo[Section.PROFESSOR]
        if !professors.keys.contains(professor) {
            professors[professor] = 0
        }
        
    }
    
    func getTimeBlocks() -> [TimeBlock] {
        return timeBlocks
    }
    
    func testPrint() {
        for t in timeBlocks {
            t.testPrint()
        }
    }
    
    func testPrintProf() {
        print("\(self.name) : \(professors)")
    }
    
    subscript(timeBlockIndex: Int) -> TimeBlock {
        get {
            return timeBlocks[timeBlockIndex]
        }
    }
    
}
