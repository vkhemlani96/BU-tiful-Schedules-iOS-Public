//
//  DetailedScheduleViewController.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/30/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import Foundation
import UIKit


// Parent for SingleViewController, Planner View Controller
class DetailedScheduleViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var index = 0
    var parentController : SchedulesViewController?
    var identifier = "templateScheduleController"
    var firstFlag = true
    
    // Set up data source and delegate
    override func viewDidLoad() {
        self.dataSource = self
        self.delegate = self
        
        self.view.backgroundColor = UIColor.white
        
        // This will show in the next view controller being pushed
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
        
        self.navigationController?.isToolbarHidden = false
        
        let startingViewController = self.viewControllerAtIndex(self.index)
        let viewControllers : NSArray = [startingViewController!]
        self.setViewControllers(viewControllers as? [UIViewController], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Update selectedIndex in parent based on swipes
        parentController!.selectedIndex = index
        self.navigationController?.isToolbarHidden = true
    }
    
    // Instantiate SingleScheduleViewController with correct schedule index
    func viewControllerAtIndex(_ index: Int) -> UIViewController? {
        //first view controller = firstViewControllers navigation controller
        let v = self.storyboard!.instantiateViewController(withIdentifier: identifier) as! SingleScheduleTableViewController
        v.schedule = parentController!.schedules![index]
        
//        v.parentController = self
//        v.index = index
        return v
    }
    
    // Generate next view controller
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        //if the index is the end of the array, return nil since we dont want a view controller after the last one
        if index == parentController!.schedules!.count - 1 {
            return nil
        }
        
        //increment the index to get the viewController after the current index
        return self.viewControllerAtIndex(self.index + 1)
        
    }
    
    // Generate previous view controller
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        //if the index is 0, return nil since we dont want a view controller before the first one
        if index == 0 {
            return nil
        }
        
        //decrement the index to get the viewController before the current one
        return self.viewControllerAtIndex(self.index - 1)
        
    }
    
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // Saved image to iPhones photo storage
    @IBAction func saveImage(_ sender: UIBarButtonItem) {
        UIImageWriteToSavedPhotosAlbum(parentController!.schedules![index].getImage()!, nil, nil, nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "plannerSegue" {
            let s = segue.destination as! PlannerViewController
            s.schedule = parentController!.schedules![index]
        }
    }
    
    
}
