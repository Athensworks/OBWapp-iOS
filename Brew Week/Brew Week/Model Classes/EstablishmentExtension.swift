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

extension Establishment {
	class func establishmentsFromJSON(jsonData: NSData) {
		let json = JSON(data: jsonData)

		let jsonEstablishmentsArray = json["establishments"]

		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

		if let context = appDelegate.managedObjectContext {
			if jsonEstablishmentsArray.count == 0 {
				return
			}

			var establishmentIDs = [Int]()

			for (index: String, establishmentJSON: JSON) in jsonEstablishmentsArray {
				var establishment = establishmentForIdentifier(establishmentJSON["id"].int32Value, inContext: context)

				if establishment == nil {
					establishment = NSEntityDescription.insertNewObjectForEntityForName("Establishment", inManagedObjectContext: context) as? Establishment

					print("Adding new establishment: " + establishmentJSON["name"].stringValue + "\n")
				}

				for (index: String, statusJSON: JSON) in establishmentJSON["beer_statuses"] {
					establishment?.updateOrCreateStatusFromJSON(statusJSON)
				}

				establishment?.identifier = establishmentJSON["id"].int32Value
				establishment?.address = establishmentJSON["address"].stringValue
				establishment?.name = establishmentJSON["name"].stringValue
				establishment?.lat = establishmentJSON["lat"].floatValue
				establishment?.lon = establishmentJSON["lon"].floatValue

				establishmentIDs.append(establishmentJSON["id"].intValue)
			}

			let fetchRemovedEstablishments = NSFetchRequest(entityName: "Establishment")
			fetchRemovedEstablishments.predicate = NSPredicate(format: "NOT (identifier IN %@)", establishmentIDs)

			if let results = (context.executeFetchRequest(fetchRemovedEstablishments, error: nil) as? [NSManagedObject]) {
				if results.count > 0 {
					print("Removing \(results.count) establishments")

					for establishment in results {
						context.deleteObject(establishment)
					}

					appDelegate.saveContext()
				}
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
			var statusExists = false

			for item in beerStatuses {
				if let beerStatus = item as? BeerStatus {
					if beerStatus.beer == 🍺 {
						statusExists = true

						beerStatus.status = statusJSON["status"].stringValue
					}
				}
			}

			if statusExists == false {
				if let newStatus = NSEntityDescription.insertNewObjectForEntityForName("BeerStatus", inManagedObjectContext: managedObjectContext!) as? BeerStatus {
					newStatus.beer = 🍺
					newStatus.establishment = self
					newStatus.status = statusJSON["status"].stringValue
				}
			}
		}
	}
}
