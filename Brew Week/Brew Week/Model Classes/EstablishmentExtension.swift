//
//  Establishment.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import CoreData

extension Establishment {
    class func establishmentsFromJSON(jsonDict: [String: AnyObject]) {
        guard let jsonEstablishmentsArray = jsonDict["establishments"] as? [[String: AnyObject]] else {
            return
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        if jsonEstablishmentsArray.count == 0 {
            return
        }
        
        var establishmentIDs = [Int]()
        
        for establishmentJSON in jsonEstablishmentsArray {
            if let identifier = establishmentJSON["id"] as? Int32 {
                var establishment = establishmentForIdentifier(identifier, inContext: appDelegate.managedObjectContext)
                
                if establishment == nil {
                    establishment = NSEntityDescription.insertNewObjectForEntityForName("Establishment", inManagedObjectContext: appDelegate.managedObjectContext) as? Establishment
                    
                    print("Adding new establishment: " + (establishmentJSON["name"] as? String ?? "No name") + "\n")
                }

                establishment?.address = establishmentJSON["address"] as? String ?? "No Address"
                establishment?.name = establishmentJSON["name"] as? String ?? "No Name"
                establishment?.lat = establishmentJSON["lat"] as? Float ?? 0
                establishment?.lon = establishmentJSON["lon"]as? Float ?? 0
                
                if let statuses = establishmentJSON["beer_statuses"] as? [[String: AnyObject]] {
                    for statusJSON in statuses {
                        establishment?.updateOrCreateStatusFromJSON(statusJSON)
                    }
                }
                
                establishmentIDs.append(Int(identifier))
            }
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

    func updateOrCreateStatusFromJSON(statusJSON: [String: AnyObject]) {
        guard let beerIdentifier = statusJSON["id"] as? Int32 else {
            return
        }

        let status = statusJSON["status"] as? String ?? "No Status"
        
		if let 🍺 = Beer.beerForIdentifier(beerIdentifier, inContext: managedObjectContext!) {
			var statusExists = false

            
			for item in beerStatuses {
				if let beerStatus = item as? BeerStatus {
					if beerStatus.beer == 🍺 {
						statusExists = true

						beerStatus.status = status
					}
				}
			}

			if statusExists == false {
				if let newStatus = NSEntityDescription.insertNewObjectForEntityForName("BeerStatus", inManagedObjectContext: managedObjectContext!) as? BeerStatus {
					newStatus.beer = 🍺
					newStatus.establishment = self
					newStatus.status = status
				}
			}
		}
	}
}
