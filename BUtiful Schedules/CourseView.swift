//
//  CourseView.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/20/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

class CourseView: UIView {
    
    // Size definitions
    let WIDTH = 90
    let HEIGHT = 30
    let SPACING = 10
    let indicatorOffset = 90*3 + 10*2
    
    // View definitions
    var collegeField, deptField, courseField: UITextField?
    var activityIndicator : UIActivityIndicatorView?
    var imageIndicator : UIImageView?
    
    // Controller info
    var controller : HomeTableViewController?
    var index : Int?
    
    init(frame: CGRect, screenWidth: Int, controller: HomeTableViewController, index: Int) {
        super.init(frame:frame)
        self.controller = controller
        self.index = index
        
        // Create college text field (ie. CAS)
        collegeField = UITextField(frame: CGRect(x: screenWidth/2 - (WIDTH * 3/2) - SPACING, y: 5, width: WIDTH, height: HEIGHT))
        collegeField?.backgroundColor = UIColor.white;
        collegeField?.borderStyle = UITextBorderStyle.roundedRect
        collegeField?.textAlignment = NSTextAlignment.center
        collegeField?.keyboardType = UIKeyboardType.alphabet
        collegeField?.autocapitalizationType = UITextAutocapitalizationType.allCharacters
        collegeField?.addTarget(self, action: #selector(CourseView.collegeFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        addSubview(collegeField!)
        
        // Create dept field (ie. EC)
        deptField = UITextField(frame: CGRect(x: screenWidth/2 - (WIDTH/2), y: 5, width: WIDTH, height: HEIGHT))
        deptField?.backgroundColor = UIColor.white;
        deptField?.borderStyle = UITextBorderStyle.roundedRect
        deptField?.textAlignment = NSTextAlignment.center
        deptField?.keyboardType = UIKeyboardType.alphabet
        deptField?.autocapitalizationType = UITextAutocapitalizationType.allCharacters
        deptField?.addTarget(self, action: #selector(CourseView.deptFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        addSubview(deptField!)
        
        // Create course field (ie. 101)
        courseField = UITextField(frame: CGRect(x: screenWidth/2 + (WIDTH/2) + SPACING, y: 5, width: WIDTH, height: HEIGHT))
        courseField?.backgroundColor = UIColor.white;
        courseField?.borderStyle = UITextBorderStyle.roundedRect
        courseField?.textAlignment = NSTextAlignment.center
        courseField?.keyboardType = UIKeyboardType.numberPad
        courseField?.addTarget(self, action: #selector(CourseView.courseFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        addSubview(courseField!)
        
        // Size activity indicator
        let indicatorCenter = screenWidth - ((screenWidth - indicatorOffset)/4);
        let indicatorFrame = CGRect(x: indicatorCenter-10, y: 10, width: 20, height: 20)
        activityIndicator = UIActivityIndicatorView(frame: indicatorFrame)
        activityIndicator?.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        activityIndicator?.isHidden = true;
        addSubview(activityIndicator!)
        
        // Create check/cross mark holder
        imageIndicator = UIImageView(frame: indicatorFrame)
        addSubview(imageIndicator!)
        
        // Place hint in the first text field
        if index == 0 {
            collegeField?.placeholder = "ex. CAS"
            deptField?.placeholder = "EC"
            courseField?.placeholder = "101"
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Move the cursor to the college field
    override func becomeFirstResponder() -> Bool {
        return collegeField!.becomeFirstResponder()
    }
    
    // Move the cursor to the deptField once the college field is filled out
    func collegeFieldDidChange(_ textField: UITextField) {
        //TODO check if valid against college names
        if textField.text!.characters.count == 3 {
            deptField!.becomeFirstResponder()
        }
    }
    
    // Move the cursor to the courseField once the dept field is filled out
    func deptFieldDidChange(_ textField: UITextField) {
        //TODO check if valid (all letters)
        if textField.text!.characters.count == 2 {
            courseField!.becomeFirstResponder()
        }
    }
    
    //TODO check if valid (all nums)
    func courseFieldDidChange(_ textField: UITextField) {
        // Check if textfield is done
        if textField.text!.characters.count == 3 {
            controller!.chooseNextResponder(index!+1)
            
            let collegeCount = collegeField!.text!.characters.count
            let deptCount = deptField!.text!.characters.count
            
            // If either the college field or the dept field is invalid, make it red
            if collegeCount != 3 {
                collegeField?.textColor = UIColor.red
            }
            
            if deptCount != 2 {
                deptField?.textColor = UIColor.red
            }
            
            // If all fields are valid, make the request
            if collegeCount == 3 && deptCount == 2 {
                CourseList.COURSES[index!] = nil
                activityIndicator?.startAnimating()
                imageIndicator?.isHidden = true
                controller!.makeGetRequestForCourse(self.getCourseInfo(), viewIndex: index!)
            }
        }
        
    }
    
    
    func success() {
        activityIndicator?.stopAnimating()
        imageIndicator?.image = UIImage(named: "Checkmark")
        imageIndicator?.isHidden = false
        collegeField?.textColor = UIColor.black
        deptField?.textColor = UIColor.black
        courseField?.textColor = UIColor.black
    }
    
    func failed() {
        activityIndicator?.stopAnimating()
        imageIndicator?.image = UIImage(named: "Delete")
        imageIndicator?.isHidden = false
        collegeField?.textColor = UIColor.red
        deptField?.textColor = UIColor.red
        courseField?.textColor = UIColor.red
    }
    
    func getCourseInfo() -> [String] {
        return [collegeField!.text!, deptField!.text!, courseField!.text!]
    }

}
