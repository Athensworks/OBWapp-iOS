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

	var status: String {
			set {
				self.willChangeValueForKey("status")
				self.setPrimitiveValue(newValue, forKey: "status")
				self.didChangeValueForKey("status")

				let index = BeerStatus.ordering.indexOf(newValue)
				self.section = Int32(index ?? Int.max)
			}
			get {
				self.willAccessValueForKey("status")
				let value = self.primitiveValueForKey("status") as? String
				self.didAccessValueForKey("status")

				return value ?? "unknown"
			}
	}

	@NSManaged var section: Int32
    @NSManaged var beer: Beer
    @NSManaged var establishment: Establishment

}
