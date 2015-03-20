//
//  Drinker.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import Foundation
import CoreData

class Drinker: NSManagedObject {

    @NSManaged var age: NSTimeInterval
    @NSManaged var zip: String
    @NSManaged var beers: NSSet

}
