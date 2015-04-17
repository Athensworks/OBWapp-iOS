//
//  Beer.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import Foundation
import CoreData

class Beer: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var limitedRelease: Bool
    @NSManaged var rateBeerID: String
	@NSManaged var notes: String
    @NSManaged var abv: Double
    @NSManaged var ibu: Int32
    @NSManaged var favoriteCount: Int32
    @NSManaged var tasteCount: Int32
    @NSManaged var beerDescription: String
    @NSManaged var favorited: Bool
    @NSManaged var tasted: Bool
    @NSManaged var establishment: NSSet
    @NSManaged var drinker: Drinker

	
}


