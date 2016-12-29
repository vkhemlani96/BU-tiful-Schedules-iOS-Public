//
//  Node.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/30/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

// Node in the tree that holds a timeblock, all of its children and it's parent node
protocol Node {
    var parent : CourseNode? {get set}
    var isLeaf : Bool {get}
}

class CourseNode : Node {
    
    let isLeaf = false;
    var parent : CourseNode? = nil;
    
    var leaf : Leaf?
    var value : TimeBlock?
    var children = [CourseNode]()
    
    init() {
        parent = nil
        value = nil
        leaf = Leaf()
    }
    
    init(t : TimeBlock, p: CourseNode, l: Leaf) {
        value = t
        parent = p
        
        leaf = Leaf(oldLeaf : l)
        leaf!.addParent(parent: self)
    }
    
    func testPrint(_ depth : Int) {
        
        for child in children {
            for _ in 0..<depth {
                print( "\t", separator: "", terminator: "")
            }
            for sec in child.value!.getSections() {
                print("\(sec[0]) \(sec[1]) (\(sec[Section.TimeBlock.PROFESSOR]))", separator: "", terminator: " ")
            }
            if let l = child.leaf {
                if l.isFull() {
                    print(" - Full (\(l.getTimeBlocks().count))")
                } else {
                    print(" - Empty (\(l.getTimeBlocks().count))")
                }
            } else {
                print()
            }
            child.testPrint(depth+1)
        }
    }
    
    func testPrintParent(_ depth : Int) {
        for _ in 0..<depth {
            print( "\t", separator: "", terminator: "")
        }
        if let v = value {
            for sec in v.getSections() {
                print(sec[0] + sec[1], separator: "", terminator: " ")
            }
            print()
            if let p = parent {
                p.testPrintParent(depth+1)
            }
        }
    }
}


//TODO add download image in case it fails
class Leaf : Node {
    
    private static var counter = 0          // Counts number of total schedules *static*
    private var ID = -1
    
    private var data = [String: [String: NodeData]]()
    private var courseCount = 0
    private var image : UIImage? = nil
    private var classOnDays = [Bool](repeating: false, count: 7)
    private var compressedTimeBlocks = [[[Double]]?](repeating: nil, count : 7)
    
    private var downtime = 0.0
    private var avgStartTime = 0.0
    private var earliestStartTime = 0.0
    private var latestStartTime = 0.0
//    private var earliestEndTime = 0.0
    private var startTimeSpread = 0.0
    private var latestEndTime = 0.0
//    private var avgMidTime = 0
//    private var avgEndTime = 0
    private var avgDayLength = 0.0
    private var daysCount = 0
    private var rating : Double? = nil
    
    private var plannerURLs = [String]()
    private let PLANNER_PREFIX = "https://www.bu.edu/link/bin/uiscgi_studentlink.pl/1464900788?ModuleName=reg%2Fadd%2Fbrowse_schedule.pl&SearchOptionDesc=Specific+Class%28es%29&SearchOptionCd=N&ViewSem=Spring+2017&KeySem=20174&AddPlannerInd=Y&CurrentCoreInd=N"
    
    let isLeaf = true
    var parent : CourseNode?
    private var isScheduleFull = false;
    
    init(){}
    
    init(oldLeaf : Leaf) {
        self.isScheduleFull = oldLeaf.isScheduleFull
        self.courseCount = oldLeaf.courseCount
        self.plannerURLs = oldLeaf.plannerURLs
        self.data = oldLeaf.data
        self.classOnDays = oldLeaf.classOnDays
        self.compressedTimeBlocks = oldLeaf.compressedTimeBlocks
    }
    
    func getImage() -> UIImage? {
        if self.image == nil {
            self.image = ScheduleImageHelper.generateImgFromTimeBlocks(timeBlocks: self.getTimeBlocks())
        }
        return self.image
    }
    
    func getCourseCount() -> Int                    { return self.courseCount }
    func getID() -> Int                             { return self.ID }
    func getPlannerURLs() -> [String]               { return self.plannerURLs }
    func getTimeBlocks() -> [TimeBlock]             { return data.flatMap{key, values in values.map{subkey, subvalue in subvalue.timeBlock}} }
    func getClassOnDays() -> [Bool]                 { return self.classOnDays }
    func isFull() -> Bool                           { return self.isScheduleFull }
    func getData() -> [String: [String: NodeData]]  { return self.data }
    func getCompressedTimeBlocks() -> [[[Double]]?] { return self.compressedTimeBlocks }
    
    func getDowntime() -> Double                    { return self.downtime }
    func getDaysCount() -> Int                      { return self.daysCount }
    func getAvgStartTime() -> Double                { return self.avgStartTime }
    func getAvgDayLength() -> Double                { return self.avgDayLength }
    func getEarliestStartTime() -> Double           { return self.earliestStartTime }
    func getLatestStartTime() -> Double             { return self.latestStartTime }
    func getLatestEndTime() -> Double               { return self.latestEndTime }
    func getStartTimeSpread() -> Double             { return self.startTimeSpread }
    
    func getRating() -> Double {
        if let alreadyCalculated = rating {
            return alreadyCalculated
        }
        rating = Sort.calculateRating(daysCount: daysCount, dayLength: avgDayLength, downtime: downtime, spread: startTimeSpread, timeStart: avgStartTime)
        return rating!
    }
 
 
    func addParent(parent: CourseNode) {
        courseCount += 1
        
        let timeBlock = parent.value!
        
        // Add Data for given timeblock to dictionary
        let dataNode = NodeData(timeBlock: timeBlock)
        let type = timeBlock.getSectionType()
        let courseName = type.getCourse().getCourseID()
        
        if let _ = data[courseName] {
            data[courseName]![type.getName()] = dataNode
        } else {
            data[courseName] = [type.getName() : dataNode]
        }
        
        for time in timeBlock.getTimes() {
            self.classOnDays[Int(time[2])] = true
            
            let dayInt = Int(time[2])
            if let day = self.compressedTimeBlocks[dayInt] {
                
                var insertedBlock = false
                for b in 0..<day.count {
                    // If the current block ends when the new block starts, change the end of the current block to the end of the new block
                    if day[b][1] == time[0] {
                        // If the new block fills the gap between two consecutive blocks, connect them and delete the following block
                        if b < day.count-1 && day[b+1][0] == time[1] {
                            self.compressedTimeBlocks[dayInt]![b][1] = day[b+1][1]
                            self.compressedTimeBlocks.remove(at: b+1)
                        } else {
                            self.compressedTimeBlocks[dayInt]![b][1] = time[1]
                        }
                        insertedBlock = true
                        break
                    } else if time[1] == day[b][0] {
                        // If the existing block starts when the new block ends, change the start of the current block to the start of the new block
                        self.compressedTimeBlocks[dayInt]![b][0] = time[0]
                        insertedBlock = true
                        break
                    } else if time[0] < day[b][0] {
                        // If the existing block comes before the next block (and it hasnt connected to previous ones due to previous if statements) insert it before the next block
                        self.compressedTimeBlocks[dayInt]!.insert([time[0], time[1]], at: b)
                        insertedBlock = true
                        break
                    }
                }
                // If you never inserted the block because it comes after all existing blocks, insert it now
                if !insertedBlock {
                    self.compressedTimeBlocks[dayInt]!.append([time[0], time[1]])
                }
                
                
            } else {
                // If you didnt have any time blocks for this day, insert the first
                self.compressedTimeBlocks[dayInt] = [[time[0], time[1]]]
            }
            
        }
        
        // Parse the sections in the timeblock to form planner string
        var allFull = true
        for s in timeBlock.getSections() {
            
            if s[Section.TimeBlock.SEATS] != "0" {
                allFull = false
            }
            
            // Add professor to list
            dataNode.professors[s[Section.TimeBlock.PROFESSOR]] = true
            
            let info1 = s[Section.TimeBlock.COURSE_ID] as NSString
            
            // Parse courseID into parse, TODO: consider splitting by space
            let college = info1.substring(with: NSRange(location: 0, length: 3))
            let dept = info1.substring(with: NSRange(location: 4, length: 2))
            let course = info1.substring(with: NSRange(location: 6, length: 3))
            let section = s[Section.TimeBlock.NUMBER]
            
            let courseNumURL = courseCount % 5 == 0 ? 5 : courseCount % 5
            
            var appendingString = "&College\(courseNumURL)=\(college)"
            appendingString += "&Dept\(courseNumURL)=\(dept)"
            appendingString += "&Course\(courseNumURL)=\(course)"
            appendingString += "&Section\(courseNumURL)=\(section)"
            
            if courseCount % 5 == 1 {
                let URL = PLANNER_PREFIX + appendingString
                plannerURLs.append(URL)
            } else {
                plannerURLs[plannerURLs.count - 1] += appendingString
            }
        }
        
        self.isScheduleFull = self.isScheduleFull || allFull
        
    }
    
    func finalize() {
        self.ID = Leaf.counter
        Leaf.counter += 1
        
        for c in data.keys {
            for t in data[c]!.keys {
                for p in data[c]![t]!.professors.keys {
                    CourseList.COURSES[c]![t].foundProfessor(professor: p)
                }
                
            }
        }
        
        for d in 0..<self.compressedTimeBlocks.count {
            if let blocks = self.compressedTimeBlocks[d] {
                for b in 0..<blocks.count-1 {
                    self.downtime += blocks[b+1][0] - blocks[b][1]
                }
            }
        }
        
        let startEndTimes = compressedTimeBlocks.flatMap({$0}).map{[$0[0][0].truncatingRemainder(dividingBy: 24), $0.last![1].truncatingRemainder(dividingBy: 24)]}
        
        self.daysCount = startEndTimes.count
        
        let startTimes = startEndTimes.flatMap{$0[0]}
        let endTimes = startEndTimes.flatMap{$0[1]}
        let dayLengths = startEndTimes.flatMap{$0[1] - $0[0]}
//        let midTimes = startEndTimes.flatMap{($0[1] + $0[0])/2}
        
        self.avgStartTime = (startTimes.reduce(0, +) / Double(startTimes.count)) - 9.5
        if avgStartTime < 0 {avgStartTime *= -1}
        
        self.avgDayLength = dayLengths.reduce(0, +) / Double(dayLengths.count)
        
        self.earliestStartTime = startTimes.reduce(24, {last, next in return last <= next ? last : next})
        self.latestStartTime = startTimes.reduce(0, {last, next in return last >= next ? last : next})
        self.startTimeSpread = pow(startTimes.reduce(0, {last, next in return last + pow(next - avgStartTime, 2)}), 0.5)
//        let avgMidTimes = midTimes.reduce(0, +) / Double(midTimes.count)
//        let midTimesSpead = pow(midTimes.reduce(0, {last, next in return last + pow(next - avgMidTimes, 2)}), 0.5)
//        let avgEngTime = endTimes.reduce(0, +) / Double(endTimes.count)
//        self.latestEndTime = endTimes.reduce(0, {last, next in return last <= next ? last : next})
        self.latestEndTime = endTimes.reduce(0, {last, next in return last >= next ? last : next})
        
        Sort.maxDaysCount = Sort.maxDaysCount > self.daysCount ? Sort.maxDaysCount : self.daysCount
        Sort.maxDowntime = Sort.maxDowntime > self.downtime ? Sort.maxDowntime : self.downtime
        Sort.maxDayLength = Sort.maxDayLength > self.avgDayLength ? Sort.maxDayLength : self.avgDayLength
        Sort.maxSpread = Sort.maxSpread > self.startTimeSpread ? Sort.maxSpread : self.startTimeSpread
        Sort.maxTimeStart = Sort.maxTimeStart > self.avgStartTime ? Sort.maxTimeStart : self.avgStartTime
        
        
    }
    
}

class NodeData {
    
    var timeBlock : TimeBlock
    var professors = [String : Bool]()
    
    init (timeBlock : TimeBlock) {
        self.timeBlock = timeBlock
    }
    
}
