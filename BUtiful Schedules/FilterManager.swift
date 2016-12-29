//
//  FilterManager.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 12/25/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import Foundation

class FilterManager {
    
    private(set) static var UNFILTERED_SCHEDULES = [Leaf]()
    private(set) static var FILTERED_SCHEDULES = [Leaf]()
    
    static var OPEN_SEATS_ONLY = false
    private(set) static var DAYS_FILTER = DaysFilter()
    private(set) static var PROFESSORS_FILTER = ProfessorFilter()
    
    private static var filters : [Filter] = [DAYS_FILTER, PROFESSORS_FILTER]
    private(set) static var needsRefiltering = false
    private(set) static var lastFilteredAt : Double = 0.0
    
    static func setSchedules(schedules: [Leaf]) {
        print(Sort.maxDaysCount, Sort.maxDayLength, Sort.maxDowntime, Sort.maxTimeStart, Sort.maxSpread)
        let sortedSchedules = schedules.sorted(by: Sort.SORT_FUNCTION)
        UNFILTERED_SCHEDULES = sortedSchedules
        FILTERED_SCHEDULES = sortedSchedules
    }
    
    static func adjustedFilteringParameters() {
        needsRefiltering = true
    }
    
    static func filter() {
        filter(completion: nil)
    }
    
    static func filter(completion : (() -> Void)?) {
        // Clear current filtered schedules
        FILTERED_SCHEDULES = []
        for schedule in UNFILTERED_SCHEDULES {
            var passesFilter = true
            
            for filter in filters {
                if !filter.passesFilter(leaf: schedule) {
                    passesFilter = false
                    break
                }
            }
            
            if passesFilter {
                FILTERED_SCHEDULES.append(schedule)
            }
        }
        
        lastFilteredAt = NSDate.timeIntervalSinceReferenceDate
        
        if completion != nil {
            completion!()
        }
    }
    
}

class Sort {
    class Weight {
        fileprivate static let DAYS_COUNT   = 0.42      // # of days with class
        fileprivate static let DAY_LENGTH   = 0.31      // Avg time between first class start and last class end
        fileprivate static let DOWNTIME     = 0.20      // Total number of time in between classes
        fileprivate static let TIME_SPREAD  = 0.0      // Spread in start time
        fileprivate static let TIME_START   = 0.07       // Difference of start from 9:30
    }
    
    static var maxDaysCount = 0
    static var maxDayLength = 0.0
    static var maxDowntime = 0.0
    static var maxSpread = 0.0
    static var maxTimeStart = 0.0
    
    /* Returns a value between 1 and 0, representing the value normalized to an exponential distribution with the worst-case value taking on a value of about 0.2*/
    static var exponential : (Double, Double) -> Double = { x, max in
        let normalizedX = x/max
        let lambda = 1.5
        let e = 2.71828
        let y = pow(e, -1 * lambda * normalizedX)
        
        return y
    }
    
    static var uniform : (Double, Double) -> Double = { x, max in
        return x/max
    }
    
    static func calculateRating(daysCount: Int, dayLength: Double, downtime: Double, spread: Double, timeStart: Double) -> Double{
        let daysComponent = (1 - uniform(Double(daysCount), Double(maxDaysCount))) * Weight.DAYS_COUNT
        let lengthComponent = exponential(dayLength, maxDayLength) * Weight.DAY_LENGTH
        let timeCompenent = exponential(downtime, maxDowntime) * Weight.DOWNTIME
        let spreadCompenent = exponential(spread, maxSpread) * Weight.TIME_SPREAD
        let startComponent = exponential(timeStart, maxTimeStart) * Weight.TIME_START
        
        return daysComponent + lengthComponent + timeCompenent + spreadCompenent + startComponent
    }
    
    static func SORT_FUNCTION(leaf1: Leaf, leaf2 : Leaf) -> Bool {
        return leaf1.getRating() > leaf2.getRating()
    }
    
}

protocol Filter {
    func passesFilter(leaf : Leaf) -> Bool
}

class DaysFilter : Filter {
    
    var noClassesOn = Set<Int>()
    
    init() {}
    
    internal func passesFilter(leaf: Leaf) -> Bool {
        for day in noClassesOn {
            if leaf.getClassOnDays()[day] {
                return false
            }
        }
        return true
    }
    
}

class ProfessorFilter : Filter {
    
    var professorsToFilterOut = [String : [String : Set<String>]]()
    
    
    internal func passesFilter(leaf: Leaf) -> Bool {
        // if the leaf is full and that filter is set, failed
        if FilterManager.OPEN_SEATS_ONLY && leaf.isFull() {
            return false
        }
        
        // Go through all the professors in the tree
        var leafData = leaf.getData()
        for courseName in leafData.keys {
            for sectionType in leafData[courseName]!.keys {
                if let data = leafData[courseName]?[sectionType] {
                    // if you dont care about whether there are seats that are empty, dont bother checking each professor to see if
                    var availableProfessors = false
                    
                    // For each professor, check if its in the filter
                    for var professor in data.professors {
                        if let filteredProfessors = professorsToFilterOut[courseName]?[sectionType], filteredProfessors.contains(professor.key)  {
                            
                            // If it is in the filter, set its NodeData dictionary value to false
                            professor.value = false
                            
                        } else {
                            // Otherwise, set its value true
                            // Set availableProfessors to true if it already is true, or if we dont care about open seats or if we do care and the seat is open
                            professor.value = true
                            availableProfessors = availableProfessors ||
                                !FilterManager.OPEN_SEATS_ONLY || data.timeBlock.getSections().map{
                                    $0[Section.TimeBlock.PROFESSOR] == professor.key && $0[Section.TimeBlock.SEATS] != "0"
                                    }.reduce(false){ previous, current in previous || current }
                        }
                    }
                    
                    if !availableProfessors {
                        return false
                    }
                }
            }
        }
        
        return true
        
        
    }
    
}

