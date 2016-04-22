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
        
        if jsonEstablishmentsArray.count == 0 {
            return
        }
        
        var establishmentIDs = [Int]()
        
        for (_, establishmentJSON): (String, JSON) in jsonEstablishmentsArray {
            var establishment = establishmentForIdentifier(establishmentJSON["id"].int32Value, inContext: appDelegate.managedObjectContext)
            
            if establishment == nil {
                establishment = NSEntityDescription.insertNewObjectForEntityForName("Establishment", inManagedObjectContext: appDelegate.managedObjectContext) as? Establishment
                
                print("Adding new establishment: " + establishmentJSON["name"].stringValue + "\n")
            }
            
            establishment?.identifier = establishmentJSON["id"].int32Value
            establishment?.address = establishmentJSON["address"].stringValue
            establishment?.name = establishmentJSON["name"].stringValue
            establishment?.lat = establishmentJSON["lat"].floatValue
            establishment?.lon = establishmentJSON["lon"].floatValue
            
            for (_, statusJSON): (String, JSON) in establishmentJSON["beer_statuses"] {
                establishment?.updateOrCreateStatusFromJSON(statusJSON)
            }
            
            establishmentIDs.append(establishmentJSON["id"].intValue)
        }
        
        let fetchRemovedEstablishments = NSFetchRequest(entityName: "Establishment")
        fetchRemovedEstablishments.predicate = NSPredicate(format: "NOT (identifier IN %@)", establishmentIDs)
        
        if let array = try? appDelegate.managedObjectContext.executeFetchRequest(fetchRemovedEstablishments), results = array as? [NSManagedObject] {
            if results.count > 0 {
                print("Removing \(results.count) establishments")
                
                for establishment in results {
                    appDelegate.managedObjectContext.deleteObject(establishment)
                }
                
                appDelegate.saveContext()
            }
        }
    }

	class func establishmentForIdentifier(identifier: Int32, inContext context: NSManagedObjectContext) -> Establishment? {
		let request = NSFetchRequest(entityName: "Establishment")

		request.predicate = NSPredicate(format: "identifier == %d", identifier)
		request.fetchLimit = 1

		if let result = (try? context.executeFetchRequest(request)) as? [Establishment] {
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
