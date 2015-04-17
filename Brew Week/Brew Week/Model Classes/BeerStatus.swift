//
//  BeerStatus.swift
//  Brew Week
//
//  Created by Ben Lachman on 4/16/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import Foundation
import CoreData

class BeerStatus: NSManagedObject {

    @NSManaged var status: String
    @NSManaged var beer: Beer
    @NSManaged var establishment: Establishment

}
