//
//  Establishment.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON

class Establishment: NSManagedObject {

	@NSManaged var beerStatuses: NSSet

	@NSManaged var name: String
	@NSManaged var identifier: Int32
	@NSManaged var address: String
	@NSManaged var lat: Float
	@NSManaged var lon: Float
}

extension Establishment {
	class func establishmentsFromJSON(jsonData: NSData) {
		let json = JSON(data: jsonData)

		let jsonEstablishmentsArray = json["establishments"]

		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

		if let context = appDelegate.managedObjectContext {
			for (index: String, establishmentJSON: JSON) in jsonEstablishmentsArray {
				var establishment = establishmentForIdentifier(establishmentJSON["id"].int32Value, inContext: context)

				if establishment == nil {
					establishment = NSEntityDescription.insertNewObjectForEntityForName("Establishment", inManagedObjectContext: context) as? Establishment
				}

				for (index: String, statusJSON: JSON) in establishmentJSON["beer_statuses"] {
					establishment?.updateOrCreateStatusFromJSON(statusJSON)
				}

				establishment?.identifier = establishmentJSON["id"].int32Value
				establishment?.address = establishmentJSON["address"].stringValue
				establishment?.name = establishmentJSON["name"].stringValue
				establishment?.lat = establishmentJSON["lat"].floatValue
				establishment?.lon = establishmentJSON["lon"].floatValue
			}
		}
	}

	class func establishmentForIdentifier(identifier: Int32, inContext context: NSManagedObjectContext) -> Establishment? {
		let request = NSFetchRequest(entityName: "Establishment")

		request.predicate = NSPredicate(format: "identifier == %d", identifier)
		request.fetchLimit = 1

		if let result = context.executeFetchRequest(request, error: nil) as? [Establishment] {
			if result.count > 0 {
				return result[0]
			}
		}

		return nil
	}

	func updateOrCreateStatusFromJSON(statusJSON: JSON) {
		let beerIdentifier = statusJSON["id"].int32Value

		if let 🍺 = Beer.beerForIdentifier(beerIdentifier, inContext: managedObjectContext!) {
			for item in beerStatuses {
				if let beerStatus = item as? BeerStatus {
					if beerStatus.beer == 🍺 {
						beerStatus.status = statusJSON["status"].stringValue
					}
				}
			}
		}
	}

	func createStatus(beerIdentifier: Int32, statusString: String) {
		// id, status
		let status = NSEntityDescription.insertNewObjectForEntityForName("BeerStatus", inManagedObjectContext: managedObjectContext!) as! BeerStatus

		status.establishment = self
		status.status = statusString

		let request = NSFetchRequest(entityName: "Beer")

		request.predicate = NSPredicate(format: "identifier == %d", beerIdentifier)
		request.fetchLimit = 1

		if let result = managedObjectContext?.executeFetchRequest(request, error: nil) {
			if result.count > 0 && result[0] is Beer {
				status.beer = result[0] as! Beer
			}
		}
	}
}
