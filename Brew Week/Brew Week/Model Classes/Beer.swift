//
//  Beer.swift
//  
//
//  Created by Ben Lachman on 6/29/15.
//
//

import Foundation
import CoreData

class Beer: NSManagedObject {

    @NSManaged var abv: Double
    @NSManaged var beerDescription: String
    @NSManaged var brewery: Brewery
    @NSManaged var favoriteCount: Int32
    @NSManaged var ibu: Int32
    @NSManaged var identifier: Int32
    @NSManaged var limitedRelease: Bool
    @NSManaged var name: String
    @NSManaged var notes: String
    @NSManaged var rateBeerID: Int32
    @NSManaged var tasteCount: Int32
    @NSManaged var statuses: NSSet
    @NSManaged var taste: TastedBeer?
    @NSManaged var favorite: FavoritedBeer?
    @NSManaged var drinkerReaction: Int32

}
