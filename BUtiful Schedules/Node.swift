//
//  Node.swift
//  BUtiful Schedules
//
//  Created by Vinay Khemlani on 5/30/16.
//  Copyright © 2016 Void Bowels. All rights reserved.
//

import UIKit

// Node in the tree that holds a timeblock, all of its children and it's parent node
class Node {
    var value : TimeBlock?
    var children = [Node]()
    var parent : Node?
    
    init() {}
    
    init(t : TimeBlock, p: Node) {
        value = t
        parent = p
    }
    
    func testPrint(_ depth : Int) {
        for child in children {
            for _ in 0..<depth {
                print( "\t", separator: "", terminator: "")
            }
            for sec in child.value!.getSections() {
                print(sec[0] + sec[1], separator: "", terminator: " ")
            }
            print()
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
