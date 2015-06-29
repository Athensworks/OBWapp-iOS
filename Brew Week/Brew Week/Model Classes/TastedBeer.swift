//
//  TastedBeer.swift
//  
//
//  Created by Ben Lachman on 6/29/15.
//
//

import Foundation
import CoreData

class TastedBeer: NSManagedObject {

    @NSManaged var timeStamp: NSTimeInterval
    @NSManaged var drinker: Drinker
    @NSManaged var beer: Beer

}
