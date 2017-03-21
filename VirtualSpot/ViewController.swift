//
//  ViewController.swift
//  VirtualSpot
//
//  Created by Etjen Ymeraj on 3/14/17.
//  Copyright © 2017 Etjen Ymeraj. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    let stack = CoreDataStack(modelName: "Model")!

    var sharedContext: NSManagedObjectContext {
        return CoreDataStack(modelName: "Model")!.context
    }
}

