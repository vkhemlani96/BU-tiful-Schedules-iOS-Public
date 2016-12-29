//
//  CourseList.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/21/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class CourseList {
    
    static var COURSE_IDS = [String]()
    static var COURSES = [String: Course]()
    static var SCHEDULE_HEAD = CourseNode()
    static var SCHEDULE_LEAVES = [Leaf]()
    static var COURSE_COUNT = 0
    
    // Init Courses array to blank array with specified length
    // Reset schedule tree to blank
    static func reset(_ count: Int) {
        COURSE_IDS = [String](repeating: "", count: count)
        COURSES = [:]
        SCHEDULE_HEAD = CourseNode()
        SCHEDULE_LEAVES = [Leaf]()
        COURSE_COUNT = 0
    }
    
    // Add the timeblock to the list
    static func add(_ sectionInfo : [String], index : Int) {
        // If course has already been stored, retrieve it (ie. CAS EC 101)
        let courseID = sectionInfo[Section.COURSE_ID]
        if COURSE_IDS[index] != courseID {
            if COURSE_IDS[index] != "" {
                COURSES[COURSE_IDS[index]] = nil
                COURSE_COUNT -= 1
            }
            COURSE_COUNT += 1
            COURSE_IDS[index] = courseID
            
            COURSES[courseID] = Course(sectionInfo: sectionInfo)
            print("\(index): \(sectionInfo[Section.COURSE_ID])")
            
        } else {
            COURSES[courseID]!.addTimeBlock(sectionInfo)
        }
    }
    
    // Create schedules without time conflicts under conditions given
    static func findWorkingSchedules() {
        // Determine which sections are able to be taken with other sections
        for c in COURSES.values {
            c.determineConditions()
        }
        
        // Keep track of what the height of the tree should be.
        var depth = 0
        var maxDepth = 0
        
        // Iterate through each course
        for j in 0..<COURSES.count {
            let course = COURSES[COURSE_IDS[j]]!
            let types = course.getSectionTypes() // Returns types in order they were found
            maxDepth += types.count   // Each type of section (Lecture, Discussion, ...) takes up a level of the tree
            
            // Go through each type of class
            for type in types {
                print("\(course.getCourseID()) \(type)")
                
                let sectionType = course[type]
                sectionType.setColorIndex(i: depth)
                
                // Get the list of the timeblocks
                let blockList = course[type].getTimeBlocks()
                
                // Keep track of if any schedule matches has been made
                var matches = false
                
                // If you're comparing the last type of section of the last course, save the leaf to the SCHEDULE_LEAVES array
                let saveLeaf = j == COURSES.count-1 && depth == maxDepth - 1
                
                // Go through each potential timeblock for a section type and try to add them
                for i in 0..<blockList.count {
                    let section = blockList[i]
                    let clean = i == blockList.count-1 && j == COURSES.count-1 // clean tree on last iteration
                    matches = schedulesHelper(SCHEDULE_HEAD, new: section, depth: depth, saveLeaf: saveLeaf, clean: clean) ? true : matches
                }
                
                // If none of them match, no possible schedules
                if !matches {
                    SCHEDULE_HEAD.testPrint(0)
                    SCHEDULE_HEAD = CourseNode()
                    print("failed")     //TODO
                    return
                }
                // Otherwise, increase the expected height of the tree
                depth += 1
            }
        }
        
        // Once all the schedules have been made, determine which of the professors have valid schedules
        testPrint()

        FilterManager.setSchedules(schedules: SCHEDULE_LEAVES)
    }
    
    /**
     * Function used to recursively move down branches of tree and add the leaf is appropriate
     * Params:
     * - node:Node - current node to compare on the tree
     * - new:TimeBlock - new TimeBlock you are trying to add to the ree
     * - depth:Int - current height relative to expected bottom of the tree
     * - saveLeaf:Bool - if you should save the leaf to list of leafs (ie. last timeblock being compared)
     * - clean:Bool - flag for whether you should remove dead leaves on the way up and not compare, TODO: more research on efficiency, currently off
     **/
    fileprivate static func schedulesHelper(_ node: CourseNode, new: TimeBlock?, depth: Int, saveLeaf : Bool, clean: Bool) -> Bool {
        // If you've reached the bottom of the tree
        if (depth == 0) {
            // Create a new courseNode and add it to the child of the current node
            if let new = new {
                let nextCourse = CourseNode(t: new, p: node, l: node.leaf!)
                
                node.children += [nextCourse]
                // Save the leaf if it is the last sections you are adding to tree
                if saveLeaf {
                    
                    nextCourse.leaf!.finalize()
                    SCHEDULE_LEAVES += [nextCourse.leaf!]
                    
                }
            }
            
            // Acknowledge the fact that you were able to add the leaf
            return true
            
        } else {
            
            if (depth > 1){
                node.leaf = nil
            }
            
            // Keep track of if you have been able to add to the tree
            var matches = false
            var indexesToRemove = [Int]() // Used to clean dead branches if clean flag is on
            
            // Iterate through children of current node
            for i in 0..<node.children.count {
                let child = node.children[i]
                
                if let new = new, let value = child.value {
                    // If times don't overlap
                    if (isValid(value, b: new)) {
                        
                        // ie. for WR 100, there are multiple sections happening at the same time, so sections are a property of timeblock
                        // for section in value.getSections() {
                            
                            // If sections are not part of the same course
                            if new.getSections()[0][0] != value.getSections()[0][0] {
                                
                                // Go down the tree for each section and check for matches
                                matches = schedulesHelper(child, new: new, depth: depth-1, saveLeaf: saveLeaf, clean: clean) ? true : matches
                                
                            } else if let condition = child.value!.getConditions()[value.getSections()[0][1]], let required = condition[new.getSectionType().getName()] {
                                // Otherwrise, if they are in the same course, you have to check for conditions
                                let blockCopy = new.copy()
                                // Remove any sections that do not fit with conditions
                                for newSection in blockCopy.getSections() {
                                    if !required.contains(newSection[1]) {
                                        blockCopy.removeSection(newSection[1])
                                    }
                                }
                                // move down with given sections that fit conditions
                                if (blockCopy.getSections().count > 0) {
                                    matches = schedulesHelper(child, new: blockCopy, depth: depth-1, saveLeaf: saveLeaf, clean: clean) ? true : matches
                                }
                                
                            } else {
                                // Otherwise if there are no conditions and they are in the same course, move down tree
                                matches = schedulesHelper(child, new: new, depth: depth-1, saveLeaf: saveLeaf, clean: clean) ? true : matches
                                
                            }
                            
                            
                        // }
                    } else if clean && depth > 1 {
                        // If they are not valid and clean flag is high, move done tree
                        schedulesHelper(child, new: nil, depth: depth-1, saveLeaf: saveLeaf, clean: clean)
                    }
                } else if clean && depth > 1 {
                    // If time block was bad but clean flag is on, clean
                    schedulesHelper(child, new: nil, depth: depth-1, saveLeaf: saveLeaf, clean: clean)
                }
                
                // If clean is high and there are no children, this branch is dead, mark it to remove
                if clean && child.children.count == 0 {
                    indexesToRemove += [i]
                }
            }
            
            // If clean is high, remove branches marked for remove
            if clean {
                for j in indexesToRemove.sorted().reversed() {
                    node.children.remove(at: j)
                }
            }
            
            // Return whether or not you were able to add it
            return matches
        }
    }
    
    // Take two timeblocks, sort all of them by end time
    // Check consecutive timeblocks and make sure the ending time of the first is before the starting time of the second
    fileprivate static func isValid(_ a: TimeBlock, b: TimeBlock) -> Bool {
        let times = a.getTimes() + b.getTimes()
        let sortedTimes = times.sorted(by: {
            if ($0[0] > $1[0]) {
                return false
            }
            return true
        })
        
        for i in 0..<sortedTimes.count {
            if i > 0 && sortedTimes[i][0] < sortedTimes[i-1][1] {
                return false
            }
            if i < sortedTimes.count-1 && sortedTimes[i][1] > sortedTimes[i+1][0] {
                return false
            }
        }
        return true
    }
    
    /*
    // Determine which professors have valid schedules
    fileprivate static func findPossibleProfs() {
        var nodes = SCHEDULE_HEAD.children
        var nextNodes = [CourseNode]()    // Holds next set of nodes to iterate through
        while nodes.count > 0 {
            // Get data needed to find lise of pofessors
            let courseID = nodes.first!.value!.getSections()[0][0]
            let courseType = nodes.first!.value!.getSectionType().getName()
            let course = COURSES[courseID]!
            
            // Get list of professors
            var profs = course.getProfessors()[courseType]!
            var nilCount = profs.keys.count
            // Go through each professor for a section type
            for n in nodes {
                if nilCount > 0 {
                    sectionLoop: for section in n.value!.getSections() {
                        let nodeProf = section[2]
                        if let found = profs[nodeProf] {
                            // Update the fact that you've found the professor
                            if !found {
                                profs.updateValue(true, forKey: nodeProf)
                                nilCount -= 1
                            }
                            // If you've found all of them, stop looking
                            if nilCount == 0 {
                                break sectionLoop
                            }
                        }
                    }
                }
                nextNodes += n.children
            }
            
            // Save what you've found
            course.updateProfessors(courseType, val: profs)
            
            // Move down the tree and keep going
            nodes.removeAll()
            nodes += nextNodes
            nextNodes.removeAll()
        }
    }
 */
    
    // Test print
    static func testPrint() {
        SCHEDULE_HEAD.testPrint(0)
        print()
        print("Schedules: " + String(SCHEDULE_LEAVES.count))
        print()
    }
    
    static func testPrintProf() {
        for id in COURSE_IDS {
            COURSES[id]!.testPrintProf()
        }
    }
    
    
    // Remove the schedule with the given id (id == initial index)
    // TODO implement binary-like search
    static func removeSchedule(_ id : Int) {
        var counter = id
        while counter >= 0 {
            if SCHEDULE_LEAVES[counter].getID() == id {
                print("removing at index " + String(counter))
                SCHEDULE_LEAVES.remove(at: counter)
                return
            }
            counter -= 1
        }
    }
    
}
