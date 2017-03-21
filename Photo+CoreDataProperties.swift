//
//  Photo+CoreDataProperties.swift
//  VirtualSpot
//
//  Created by Etjen Ymeraj on 3/14/17.
//  Copyright © 2017 Etjen Ymeraj. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imagePath: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var pin: Pin?

}
