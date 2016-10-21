//
//  String.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/22/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import Foundation

// Extension of the string class to simplify use of needed functions
extension String {
    
    // Removes leading and trailing whitespaces
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    // Removes digits
    func trimNums() -> String {
        return self.trimmingCharacters(in: CharacterSet.decimalDigits)
    }
    
    // Remove letters
    func trimLetters() -> String {
        return self.trimmingCharacters(in: CharacterSet.letters)
    }
    
    // Returns [String] of regular expression matches
    func regexMatches (_ regex: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: regex,
                                                options: NSRegularExpression.Options())
            let nsString = self as NSString
            return regex.matches(in: self,options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, nsString.length))
                .map({
                    nsString.substring(with: $0.range)
                })
        } catch _ {
            print("FAILED")
            return []
        }
    }
    
    // Replaces regular expression matches
    func replaceRegex(_ regex: String, withString: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: regex,
                                                options: NSRegularExpression.Options())
            var nsString = self as NSString
            let results = regex.matches(in: self,options: NSRegularExpression.MatchingOptions(), range: NSMakeRange(0, nsString.length))
                .map({
                    nsString.substring(with: $0.range)
                })
            for str in results {
                nsString = nsString.replacingOccurrences(of: str, with: withString) as NSString
            }
            return String(nsString)
        } catch _ {
            return nil
        }
    }
}
