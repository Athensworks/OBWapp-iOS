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

	@NSManaged var beersStatuses: NSSet

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
				let establishment = NSEntityDescription.insertNewObjectForEntityForName("Establishment", inManagedObjectContext: context) as! Establishment

				for (statusIndex: String, statusJSON: JSON) in establishmentJSON["beer_statuses"] {
					// id, status
					let status = NSEntityDescription.insertNewObjectForEntityForName("BeerStatus", inManagedObjectContext: context) as! BeerStatus

					status.establishment = establishment

					let request = NSFetchRequest(entityName: "Beer")

					request.predicate = NSPredicate(format: "identifier = %@", statusJSON["id"].int32Value)
					request.fetchLimit = 1

					if let result = context.executeFetchRequest(request, error: nil) {
						if result.count > 0 && result[0] is Beer {
							status.beer = result[0] as! Beer
						}
					}
				}

				establishment.identifier = establishmentJSON["id"].int32Value
				establishment.address = establishmentJSON["address"].stringValue
				establishment.name = establishmentJSON["name"].stringValue
				establishment.lat = establishmentJSON["lat"].floatValue
				establishment.lon = establishmentJSON["lon"].floatValue

//				establishment.beers =
			}
		}
	}
}
