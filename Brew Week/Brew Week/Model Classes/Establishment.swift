//
//  Establishment.swift
//  
//
//  Created by Ben Lachman on 6/29/15.
//
//

import Foundation
import CoreData

class Establishment: NSManagedObject {

    @NSManaged var address: String
    @NSManaged var identifier: Int32
    @NSManaged var lat: Float
    @NSManaged var lon: Float
    @NSManaged var name: String
    @NSManaged var beerStatuses: NSSet

}
