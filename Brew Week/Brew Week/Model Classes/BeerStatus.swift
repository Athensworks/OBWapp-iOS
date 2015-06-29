//
//  BeerStatus.swift
//  
//
//  Created by Ben Lachman on 6/29/15.
//
//

import Foundation
import CoreData

class BeerStatus: NSManagedObject {

    @NSManaged var status: String
    @NSManaged var beer: Beer
    @NSManaged var establishment: Establishment

}
