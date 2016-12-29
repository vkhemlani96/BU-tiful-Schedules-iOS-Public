//
//  ScheduleImageHelper.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 12/23/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//
import UIKit

class ScheduleImageHelper {
    
    static private let WIDTH = 662
    static private let HEIGHT = 490
    
    static let X_OFFSET : Double = 72
    static let Y_OFFSET : Double = 24
    static let X_DAY_WIDTH : Double = 73
    static let X_UNIT_DAY : Double = 74
    static let Y_UNIT_HOUR : Double = 29
    
    static private let COLORS : [UIColor] = [
        UIColor(red:0.40, green:0.20, blue:1.00, alpha:1.0),
        UIColor(red:0.60, green:0.60, blue:0.20, alpha:1.0),
        UIColor(red:1.00, green:1.00, blue:0.00, alpha:1.0),
        UIColor(red:0.00, green:1.00, blue:0.00, alpha:1.0),
        UIColor(red:0.60, green:0.80, blue:0.20, alpha:1.0),
        UIColor(red:0.60, green:0.60, blue:1.00, alpha:1.0),
        UIColor(red:1.00, green:0.00, blue:0.80, alpha:1.0),
        UIColor(red:0.60, green:1.00, blue:0.80, alpha:1.0),
        UIColor(red:0.60, green:0.40, blue:0.80, alpha:1.0),
        UIColor(red:0.80, green:0.60, blue:0.20, alpha:1.0),
        UIColor(red:1.00, green:0.80, blue:0.60, alpha:1.0),
        UIColor(red:0.80, green:0.80, blue:1.00, alpha:1.0),
        UIColor(red:1.00, green:0.60, blue:0.40, alpha:1.0),
        UIColor(red:0.80, green:0.40, blue:0.00, alpha:1.0),
        UIColor(red:0.00, green:0.60, blue:0.20, alpha:1.0),
        UIColor(red:0.00, green:0.80, blue:0.80, alpha:1.0),
        UIColor(red:1.00, green:0.80, blue:0.00, alpha:1.0),
        UIColor(red:0.00, green:1.00, blue:1.00, alpha:1.0),
        UIColor(red:0.60, green:0.40, blue:0.60, alpha:1.0)
    ]
    
    static func getColor(i : Int) -> UIColor {
        return COLORS[i % COLORS.count]
    }
    
    static func generateImgFromTimeBlocks(timeBlocks : [TimeBlock]) -> UIImage? {
        let imageSize = CGSize(width: WIDTH, height: HEIGHT)
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        let context = UIGraphicsGetCurrentContext()
        
        if let context = context {
            for t in timeBlocks {
                let rectangles = t.getImageRectangles()
                context.setFillColor(COLORS[t.getColorIndex() % COLORS.count].cgColor)
                for r in rectangles {
                    context.addRect(r)
                    context.drawPath(using: .fill)
                }
            }
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    static func generateRectanglesFromTimes(times: [[Double]]) -> [CGRect] {
        var rectangles = [CGRect]()
        
        for blocks in times {
            let x = (blocks[2] * X_UNIT_DAY) + X_OFFSET
            let y = (blocks[0].truncatingRemainder(dividingBy: 24) - 7) * Y_UNIT_HOUR + Y_OFFSET
            let width : Double = X_DAY_WIDTH
            let height = (blocks[1] - blocks[0]) * Y_UNIT_HOUR
            
            let rectangle = CGRect(x: x, y: y, width: width, height: height)
            
            rectangles += [rectangle]
        }
        
        return rectangles;
    }
    
}
