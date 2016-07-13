//
//  Beer.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import CoreData
import Alamofire


extension Beer {
	 var rateBeerURL: NSURL? {
		get {
			return NSURL(string: "http://www.ratebeer.com/beer/\(rateBeerID)/")
		}
	}

    class func beersFromJSON(jsonDict: [String: AnyObject]) {
        guard let jsonBeersArray = jsonDict["beers"] as? [[String: AnyObject]] else {
            return
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        if jsonBeersArray.count == 0 {
            return
        }
        
        var beerIDs = [Int]()
        
        for beerJSON in jsonBeersArray {
            guard let intIdentifier = beerJSON["id"] as? Int else {
                continue
            }
            
            let identifier = Int32(intIdentifier)
            
            var beer = beerForIdentifier(identifier, inContext: appDelegate.managedObjectContext)
            
            if beer == nil {
                beer = NSEntityDescription.insertNewObjectForEntityForName("Beer", inManagedObjectContext: appDelegate.managedObjectContext) as? Beer
            }
            
            if let 🍺 = beer {
                🍺.identifier = identifier
                🍺.name = beerJSON["name"] as? String ?? "Unknown Beer"
                🍺.abv = beerJSON["abv"] as? Double ?? 0
                🍺.ibu = Int32(beerJSON["ibu"] as? Int ?? 0)
                🍺.favoriteCount = Int32(beerJSON["favorite_count"] as? Int ?? 0)
                🍺.tasteCount = Int32(beerJSON["taste_count"] as? Int ?? 0)
                🍺.limitedRelease = beerJSON["limited_release"] as? Bool ?? false
                🍺.rateBeerID = Int32(beerJSON["rate_beer_id"] as? Int ?? 0)
                🍺.beerDescription = beerJSON["description"] as? String ?? ""
                if let breweryJSON = beerJSON["brewery"] as? [String: AnyObject], brewery = Brewery.breweryFromJSON(breweryJSON) {
                    🍺.brewery = brewery
                } else {
                    print("Did not find brewery (\(beerJSON["brewery"])) for \(🍺.name)")
                }
            }
        
            beerIDs.append(Int(identifier))
        }
        
        let fetchRemovedBeers = NSFetchRequest(entityName: "Beer")
        fetchRemovedBeers.predicate = NSPredicate(format: "NOT (identifier IN %@)", beerIDs)
        
        if let array = try? appDelegate.managedObjectContext.executeFetchRequest(fetchRemovedBeers), results = array as? [NSManagedObject] {
            if results.count > 0 {
                print("Removing \(results.count) beers")
                
                for beer in results {
                    appDelegate.managedObjectContext.deleteObject(beer)
                }
                
                appDelegate.saveContext()
            }
        }
    }

	class func beerForIdentifier(identifier: Int32, inContext context: NSManagedObjectContext) -> Beer? {
		let request = NSFetchRequest(entityName: "Beer")

		request.predicate = NSPredicate(format: "identifier == %d", identifier)
		request.fetchLimit = 1

		if let result = try? context.executeFetchRequest(request) {
			if result.count > 0 {
				return result[0] as? Beer
			}
		}

		return nil
	}

    func tasted(tasted: Bool, completion: ((Int) -> Void)) {
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

		reportTasted(tasted, completion: completion)
		appDelegate.saveContext()
	}

    func favorited(favorited: Bool, completion: ((Int) -> Void)) {
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

		reportFavorited(favorited, completion: completion)
		appDelegate.saveContext()
	}
    
    func reacted(reaction: Int32) -> (expectedTasteCount: Int32, expectedFavoriteCount: Int32) {
        let newlyTasted = drinkerReaction < 2 && reaction >= 2
        let untasted = drinkerReaction >= 2 && reaction < 2
        
        if newlyTasted {
            reportTasted(true) { _ in
                
            }
        } else if untasted {
            reportTasted(false) { _ in
                
            }
        }
        
        let newlyFavorited = drinkerReaction != 2 && reaction == 2
        let unfavorited = drinkerReaction == 2 && reaction != 2
        
        if newlyFavorited {
            reportFavorited(true) { _ in
                
            }
        } else if unfavorited {
            reportFavorited(false) { _ in
                
            }
        }
        
        
        drinkerReaction = reaction
        (UIApplication.sharedApplication().delegate as? AppDelegate)?.saveContext()
        
        return (tasteCount + (newlyTasted ? 1 : untasted ? -1 : 0), favoriteCount + (newlyFavorited ? 1 : unfavorited ? -1 : 0))
    }

    private func reportTasted(tasted: Bool, completion: ((Int) -> Void) ) {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

		if let drinker = appDelegate.drinker,
            let guid = UIDevice.currentDevice().identifierForVendor?.UUIDString {
			let beerID = Int(identifier)
			
			let location = appDelegate.locationManager?.location

			//			{
			//				"beer_id": 123,
			//				"device_guid": "GUID",
			//				"age":  35,
			//				"lat": "Y",
			//				"lon": "X",
			//			}

			var params: [String:AnyObject] = ["beer_id":beerID, "device_guid":guid, "state":tasted, "age":drinker.ageInYears]

			if let location = location {
				params["lat"] = location.coordinate.latitude
				params["lon"] = location.coordinate.longitude
			}

            Alamofire.request(.POST, Endpoint(path: "taste"), parameters: params, encoding: .JSON).validate().responseJSON { response in
                switch response.result {
                case .Success(let responseJSON):
                    
                    if let json = responseJSON as? [String: AnyObject],
                        let count = json["count"] as? Int {
                        self.tasteCount = Int32(count)
                        completion(count)
                    }
                case .Failure(let error):
                    print("Failed to report taste: \(error)")
                }
            }
		}
	}

    private func reportFavorited(favorited: Bool, completion: ((Int) -> Void)) {
		let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

		if let drinker = appDelegate.drinker,
            let guid = UIDevice.currentDevice().identifierForVendor?.UUIDString {
			let beerID = Int(identifier)
			let location = appDelegate.locationManager?.location

			//			{
			//				"beer_id": 123,
			//				"device_guid": "GUID",
			//				"age":  35,
			//				"lat": "Y",
			//				"lon": "X",
			//			}
			var params: [String:AnyObject] = ["beer_id":beerID, "device_guid":guid, "state":favorited, "age":drinker.ageInYears]

			if let location = location {
				params["lat"] = location.coordinate.latitude
				params["lon"] = location.coordinate.longitude
			}

			Alamofire.request(.POST, Endpoint(path: "favorite"), parameters: params, encoding: .JSON).validate().responseJSON { response in
                switch response.result {
                case .Success(let responseJSON):

                    if let json = responseJSON as? [String: AnyObject],
                        let count = json["count"] as? Int {
                            self.favoriteCount = Int32(count)
                            completion(count)
                    }
                case .Failure(let error):
                   print("Failed to report favorite: \(error)")
                }
			}
		}
	}
}

