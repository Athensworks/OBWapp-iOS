//
//  Brewery.swift
//  
//
//  Created by Ben Lachman on 6/29/15.
//
//

import Foundation
import CoreData

class Brewery: NSManagedObject {

    @NSManaged var identifier: Int32
    @NSManaged var name: String
    @NSManaged var beers: NSSet

}
