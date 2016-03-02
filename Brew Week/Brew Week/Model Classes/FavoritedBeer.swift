//
//  FavoritedBeer.swift
//  
//
//  Created by Ben Lachman on 6/29/15.
//
//

import Foundation
import CoreData

class FavoritedBeer: NSManagedObject {

    @NSManaged var timeStamp: NSTimeInterval
    @NSManaged var drinker: Drinker
    @NSManaged var beer: Beer

}
