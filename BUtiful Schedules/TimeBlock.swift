//
//  TimeBlock.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/22/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//
import UIKit

// TimeBlocks
// These classes represent all of the timeblocks for one section and contains all the sections that have identical timeblocks
// For example, 3 WR 100 sections may be Mon 1-2, Wed 1-2, Fri 1-2
class TimeBlock {
    
    fileprivate var course = Course()
    fileprivate var sections = [[String]]() // [["CAS WR 100", "A1", Prof, Seats, Building, Room], ["CAS WR 100", "B1", Prof, Seats, Building, Room], ["CAS WR 100", "C1", Prof, Seats, Building, Room]]
    fileprivate var times = [[Double]]()    // [[StartTime (hours from midnight sunday), EndTime, Day]] => [[37.0, 38.0, 1], [85.0, 86.0, 3], [133.0, 134.0, 5]]
    fileprivate var sectionType = String()  // Independent, Lecture, Discussion, etc.
    fileprivate var conditions = [String: [String: [String]]]()
    
    fileprivate let ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    init() {}
    
    // Can be created with a Course object and the corresponding section type of the sections it holds
    init(course: Course, sectionType: String) {
        self.course = course
        self.sectionType = sectionType
    }
    
    // Usual init, course, sections that fall into time block, times of blocks, section type, conditions for following timeblocks
    init(course: Course, sections: [[String]], times: [[Double]], sectionType : String, conditions: [String: [String: [String]]]) {
        self.course = course
        self.sections = sections
        self.times = times
        self.sectionType = sectionType
        self.conditions = conditions
    }
    
    func getSectionType() -> String {
        return sectionType
    }
    
    func getSections() -> [[String]] {
        return sections
    }
    
    // Remove section by coming section number, eg. A1, B1, etc.
    func removeSection(_ sectionID : String) {
        for i in 0..<sections.count {
            if (sections[i][1] == sectionID) {
                sections.remove(at: i)
                return
            }
        }
        
    }
    
    func getTimes() -> [[Double]] {
        return times
    }
    
    func getConditions() -> [String: [String: [String]]] {
        return conditions
    }
    
    func testPrint() {
        print(sections)
        print(times)
        print(conditions)
    }
    
    // Creates new TimeBlock with same properties
    func copy() -> TimeBlock {
        let copy = TimeBlock(course: course, sections: sections, times: times, sectionType : sectionType, conditions: conditions)
        return copy
    }
    
    // Checks if all time blocks are the same
    func isArrayEqual(_ sectionInfo : [String]) -> Bool {
        let newTimes = TimeBlock.calculateTimes(sectionInfo)
        for time in newTimes {
            for oldTime in times {
                if time != oldTime {
                    return false
                }
            }
        }
        return true
        
    }
    
    // Add section to section array with consolidated properties
    func addSection(_ sectionInfo : [String]) {
        // If this is the first section, get its times
        if times.count == 0 {
            times += TimeBlock.calculateTimes(sectionInfo)
        }
        
        // Consolidate necessary info into new array
        var section = [
            sectionInfo[Section.COURSE_ID].trim(),
            sectionInfo[Section.NUMBER].trim(),
            sectionInfo[Section.PROFESSOR].trim(),
            sectionInfo[Section.SEATS].trim(),
            sectionInfo[Section.BUILDING].trim(),
            sectionInfo[Section.ROOM].trim(),
        ]
        
        // If it has conditions, append it to the consolidated section array
        if sectionInfo.count > Section.CONDITIONS {
            section += [sectionInfo[Section.CONDITIONS]]
        }
        
        // Add array
        sections += [section]
    }
    
    // Convert times string into double array [startTime (relative to Sun. 12am), endTime, day]
    fileprivate static func calculateTimes(_ sectionInfo: [String]) -> [[Double]] {
        var times = [[Double]]()
        var sections = sectionInfo[Section.DAYS].components(separatedBy: "<br>")    // ie. Mon,Wed<br>Fri
        if (sections.count > 1 && sections[0] == sections[1]) {                     // ie. Fri,Fri
            sections.remove(at: 1)
        }
        
        // Split times to correspond to split up days
        let startTimes = sectionInfo[Section.START].components(separatedBy: "<br>") // ie. 3:00pm<br>12:00pm
        let endTimes = sectionInfo[Section.END].components(separatedBy: "<br>")     // ^^^^
        
        // For each line
        for i in 0..<sections.count {
            // Split the days
            let days = sections[i].components(separatedBy: ",")
            for d in days {
                let d = d.trim()
                let timeBlock = [
                    
                    // Get the times that correspond with the day and convert them to doubles
                    // If there are multiple days but only one time, use the one time
                    TimeBlock.getAbsoluteTime(d, time: i < startTimes.count ? startTimes[i].trim() : startTimes[0].trim()),
                    TimeBlock.getAbsoluteTime(d, time: i < endTimes.count ? endTimes[i].trim() : endTimes[0].trim()),
                    Double(TimeBlock.getDayInt(d))
                    
                ]
                // If the day was incorrect, assume time was not parse correctly
                if timeBlock[2] != -1.0 {
                    times += [timeBlock]
                }
            }
        }
        
        return times;
    }
    
    // See helper function below
    func determineConditions() {
        for section in sections {
            if (section.count == 7) {
                determineConditions(section[1], conditions: section[6])
            }
        }
    }
    // "A1|A5" -> ["A1","A2"..."A5"]
    func determineConditions(_ sectionCode : String, conditions : String) {
        let foundCond = conditions.components(separatedBy: "|")
        for cond in foundCond {
            let sectionsRegex = cond.regexMatches("[A-Z]{1}[0-9]{1}")
            var sections = [String]()
            if let sectionType = course.getSectionType(sectionsRegex[0]) {
                let letter1 = sectionsRegex[0].trimNums()       // "A" from "A1"
                let letter2 = sectionsRegex[1].trimNums()       // "C" from "C1"
                let sectionLetters = ALPHABET.regexMatches("[" + letter1 + "-" + letter2 + "]")[0]  // "A","C" - "ABC"
                
                for sectionLetter in sectionLetters.characters {
                    for sectionNumber in Int(sectionsRegex[0].trimLetters())!...Int(sectionsRegex[1].trimLetters())! {
                        sections += [String(sectionLetter) + String(sectionNumber)]
                    }
                }
                // Appends conditions to global conditions variable
                self.conditions[sectionCode] = [sectionType : sections]
            }
        }
    }
    
    // Convert day string to int, TODO: consider replacing with an dictionary
    fileprivate static func getDayInt(_ day : String) -> Int {
        switch(day) {
        case "Sun": return 0
        case "Mon": return 1
        case "Tue": return 2
        case "Wed": return 3
        case "Thu": return 4
        case "Fri": return 5
        case "Sat": return 6
        default:    return -1
        }
    }
    
    // Covert day in to string, TODO: consider replaying with an array
    static func getDayString(_ day : Int) -> String {
        switch(day) {
        case 0: return "Sun"
        case 1: return "Mon"
        case 2: return "Tue"
        case 3: return "Wed"
        case 4: return "Thu"
        case 5: return "Fri"
        case 6: return "Sat"
        default: return "Sun"
        }
    }
    
    // Convert Mon at 12pm to 36 (hours relative to Sun 12am)
    fileprivate static func getAbsoluteTime(_ day: String, time: String) -> Double {
        var absoluteTime = 0;
        absoluteTime = getDayInt(day) * 24  // Converts monday to 24
        
        // If day was not parsable, return 0
        if absoluteTime < 0 {
            return 0
        }
        
        // Seperate into hours and minutes
        var timeParts = time.components(separatedBy: ":") // "2:30pm" -> ["2","30pm"]
        absoluteTime += Int(timeParts[0].trim())! % 12 // add whole numbers and 12%12 = 0
        if (timeParts[1].contains("pm")) {
            absoluteTime += 12
        }
        
        // Calc minutes to decimal and add to hours int
        return Double(absoluteTime) + (Double(timeParts[1].replaceRegex("[apm]", withString: "")!)! / 60.0)
    }
    
    // Needed to generate schedule images
    static func getMilitaryTime (_ time: Double) -> Int {
        let hours = (Int(time) % 24) * 100  // Int() removes minutes, %24 removes day dependency, appends two zeros
        let mins = Int(time.truncatingRemainder(dividingBy: 1) * 60)    // Take decimal and multiply by 60 to get minutes int
        return hours + mins // Add hours to minutes to get military time as int
    }
    
}
