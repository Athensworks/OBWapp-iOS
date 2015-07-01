//
//  Drinker.swift
//  
//
//  Created by Ben Lachman on 6/29/15.
//
//

import Foundation
import CoreData

class Drinker: NSManagedObject {

    @NSManaged var age: NSTimeInterval
    @NSManaged var zip: String
    @NSManaged var tastedBeers: NSSet
    @NSManaged var favoritedBeers: NSSet

}
