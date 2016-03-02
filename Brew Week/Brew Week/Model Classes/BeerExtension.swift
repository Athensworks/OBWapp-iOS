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
import Alamofire


extension Beer {
	 var rateBeerURL: NSURL? {
		get {
			return NSURL(string: "http://www.ratebeer.com/beer/\(rateBeerID)/")
		}
	}

	class func beersFromJSON(jsonData: NSData) {
		let json = JSON(data: jsonData)

		let jsonBeersArray = json["beers"]

		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
		

		if let context = appDelegate.managedObjectContext {
			for (index: String, beerJSON: JSON) in jsonBeersArray {

				var beer = beerForIdentifier(beerJSON["id"].int32Value, inContext: context)

				if beer == nil {
					beer = NSEntityDescription.insertNewObjectForEntityForName("Beer", inManagedObjectContext: context) as? Beer
				}

				if let 🍺 = beer {
					🍺.name = beerJSON["name"].stringValue
					🍺.identifier = beerJSON["id"].int32Value
					🍺.brewery = beerJSON["brewery"].stringValue
					🍺.abv = beerJSON["abv"].doubleValue
					🍺.ibu = beerJSON["ibu"].int32Value
					🍺.favoriteCount = beerJSON["favorite_count"].int32Value
					🍺.tasteCount = beerJSON["taste_count"].int32Value
					🍺.limitedRelease = beerJSON["limited_release"].boolValue
					🍺.rateBeerID = beerJSON["rate_beer_id"].int32Value
					🍺.beerDescription = beerJSON["description"].stringValue
				}
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

	class func beerForIdentifier(identifier: Int32, inContext context: NSManagedObjectContext) -> Beer? {
		let request = NSFetchRequest(entityName: "Beer")

		request.predicate = NSPredicate(format: "identifier == %d", identifier)
		request.fetchLimit = 1

		if let result = context.executeFetchRequest(request, error: nil) {
			if result.count > 0 {
				return result[0] as? Beer
			}
		}

		return nil
	}

	func tasted(completion: ((Int) -> Void)) {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

		if let tasting = self.taste {
			self.taste = nil;

			managedObjectContext?.deleteObject(tasting)
		} else if let drinker = appDelegate.drinker {
			let tasting = NSEntityDescription.insertNewObjectForEntityForName("TastedBeer", inManagedObjectContext: self.managedObjectContext!) as! TastedBeer

			tasting.timeStamp = NSDate.timeIntervalSinceReferenceDate()
			tasting.drinker = drinker
			tasting.beer = self
		}

		reportTasted(completion)
		appDelegate.saveContext()
	}

	func favorited(completion: ((Int) -> Void)) {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

		if let favorited = self.favorite {
			self.favorite = nil

			managedObjectContext?.deleteObject(favorited)
		} else if let drinker = appDelegate.drinker {
			let favorited = NSEntityDescription.insertNewObjectForEntityForName("FavoritedBeer", inManagedObjectContext: self.managedObjectContext!) as! FavoritedBeer

			favorited.timeStamp = NSDate.timeIntervalSinceReferenceDate()
			favorited.drinker = drinker
			favorited.beer = self
		}

		reportFavorited(completion)
		appDelegate.saveContext()
	}

	private func reportTasted(completion: ((Int) -> Void) ) {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

		if let drinker = appDelegate.drinker {
			let beerID = Int(identifier)
			let guid = UIDevice.currentDevice().identifierForVendor.UUIDString
			let location = appDelegate.locationManager?.location

			//			{
			//				"beer_id": 123,
			//				"device_guid": "GUID",
			//				"age":  35,
			//				"lat": "Y",
			//				"lon": "X",
			//			}

			var params: [String:AnyObject] = ["beer_id":beerID, "device_guid":guid, "age":drinker.ageInYears]

			if let location = location {
				params["lat"] = location.coordinate.latitude
				params["lon"] = location.coordinate.longitude
			}

			Alamofire.request(.POST, Endpoint(path: "taste"), parameters: params, encoding: .JSON).responseJSON { (request, response, responseJSON, error) in
				println("/taste Response: \(responseJSON)")

				if let json = responseJSON as? [String: AnyObject] {
					if let count = json["count"] as? Int {
						self.tasteCount = Int32(count)
						completion(count)
					}
				}
			}
		}
	}

	private func reportFavorited(completion: ((Int) -> Void)) {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

		if let drinker = appDelegate.drinker {
			let beerID = Int(identifier)
			let guid = UIDevice.currentDevice().identifierForVendor.UUIDString
			let location = appDelegate.locationManager?.location

			//			{
			//				"beer_id": 123,
			//				"device_guid": "GUID",
			//				"age":  35,
			//				"lat": "Y",
			//				"lon": "X",
			//			}
			var params: [String:AnyObject] = ["beer_id":beerID, "device_guid":guid, "age":drinker.ageInYears]

			if let location = location {
				params["lat"] = location.coordinate.latitude
				params["lon"] = location.coordinate.longitude
			}

			Alamofire.request(.POST, Endpoint(path: "favorite"), parameters: params, encoding: .JSON).responseJSON { (request, response, responseJSON, error) in
				println("/favorite Response: \(responseJSON)")

				if let json = responseJSON as? [String: AnyObject] {
					if let count = json["count"] as? Int {
						self.favoriteCount = Int32(count)
						completion(count)
					}
				}
			}
		}
	}
}

