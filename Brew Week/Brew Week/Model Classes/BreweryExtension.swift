//
//  BreweryExtension.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import CoreData

extension Brewery {
    class func breweriesFromJSON(jsonDict: [String: AnyObject]) {
        guard let jsonBreweriesArray = jsonDict["breweries"] as? [[String: AnyObject]] else {
            return
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        if jsonBreweriesArray.count == 0 {
            return
        }
        
        var breweryIDs = [Int]()
        
        for breweryJSON in jsonBreweriesArray {
            if let id = breweryJSON["id"] as? Int {
                let identifier = Int32(id)
                var brewery = breweryForIdentifier(identifier, inContext: appDelegate.managedObjectContext)
                
                if brewery == nil {
                    brewery = NSEntityDescription.insertNewObjectForEntityForName("Brewery", inManagedObjectContext: appDelegate.managedObjectContext) as? Brewery
                    
                    print("Adding new brewery: " + (breweryJSON["name"] as? String ?? "No name") + "\n")
                }

                if let 🏬 = brewery {
                    🏬.identifier = identifier
                    🏬.name = breweryJSON["name"] as? String ?? "No Name"
                }
                
                breweryIDs.append(Int(identifier))
            }
        }
        
//        let fetchRemovedBreweries = NSFetchRequest(entityName: "Brewery")
//        fetchRemovedBreweries.predicate = NSPredicate(format: "NOT (identifier IN %@)", breweryIDs)
//        
//        if let array = try? appDelegate.managedObjectContext.executeFetchRequest(fetchRemovedBreweries), results = array as? [NSManagedObject] {
//            if results.count > 0 {
//                print("Removing \(results.count) breweries")
//                
//                for brewery in results {
//                    appDelegate.managedObjectContext.deleteObject(brewery)
//                }
//            }
//        }
        
        appDelegate.saveContext()
    }

	class func breweryForIdentifier(identifier: Int32, inContext context: NSManagedObjectContext) -> Brewery? {
		let request = NSFetchRequest(entityName: "Brewery")

		request.predicate = NSPredicate(format: "identifier == %d", identifier)
		request.fetchLimit = 1

		if let result = (try? context.executeFetchRequest(request)) as? [Brewery] {
			if result.count > 0 {
				return result[0]
			}
		}

		return nil
	}
}
