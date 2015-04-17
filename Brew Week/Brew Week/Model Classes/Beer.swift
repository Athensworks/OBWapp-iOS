//
//  Beer.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON

class Beer: NSManagedObject {

	@NSManaged var name: String
	@NSManaged var identifier: Int32
	@NSManaged var brewery: String
	@NSManaged var limitedRelease: Bool
	@NSManaged var rateBeerID: Int32
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

extension Beer {
	class func beersFromJSON(jsonData: NSData) {
		let json = JSON(data: jsonData)

		let jsonBeersArray = json["beers"]

		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		

		if let context = appDelegate.managedObjectContext {
			for (index: String, beerJSON: JSON) in jsonBeersArray {
				let 🍺 = NSEntityDescription.insertNewObjectForEntityForName("Beer", inManagedObjectContext: context) as! Beer

				// If appropriate, configure the new managed object.
				// Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.

				🍺.name = beerJSON["name"].stringValue
				🍺.identifier = beerJSON["id"].int32Value
				🍺.brewery = beerJSON["brewery"].stringValue
				🍺.abv = beerJSON["abv"].doubleValue
				🍺.ibu = beerJSON["ibu"].int32Value
				🍺.favoriteCount = beerJSON["favorite_count"].int32Value
				🍺.tasteCount = beerJSON["taste_count"].int32Value
				🍺.limitedRelease = beerJSON["limited_release"].boolValue
				🍺.rateBeerID = beerJSON["rate_beer_id"].int32Value
				🍺.beerDescription = beerJSON["beer_description"].stringValue

				🍺.favorited = false
				🍺.tasted = false
			}


			// Save the context.
			var error: NSError? = nil
			if !context.save(&error) {
				// Replace this implementation with code to handle the error appropriately.
				// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				//println("Unresolved error \(error), \(error.userInfo)")
				abort()
			}
		}
	}
}

