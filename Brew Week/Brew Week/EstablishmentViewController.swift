//
//  EstablishmentViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 5/29/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import CoreData
import Alamofire


class EstablishmentViewController: UITableViewController, NSFetchedResultsControllerDelegate, ManagedObjectViewController, UISearchResultsUpdating {
	
    let searchController = UISearchController(searchResultsController: nil)
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var filteredEstablishments = [Establishment]()

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
		Alamofire.request(.GET, Endpoint(path: "beers")).validate().responseJSON { response in
            switch response.result {
            case .Success(let beersJSON as [String: AnyObject]):
                Beer.beersFromJSON(beersJSON)
                
                guard let guid = UIDevice.currentDevice().identifierForVendor?.UUIDString else {
                    return
                }
                
                var params: [String: AnyObject] = ["device_guid": guid];
                let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
                
                //			{
                //				"beer_id": 123,
                //				"device_guid": "GUID",
                //				"age":  35,
                //				"lat": "Y",
                //				"lon": "X",
                //			}
                
                if let drinker = appDelegate?.drinker {
                    params["age"] = drinker.ageInYears
                }
                
                if let location = appDelegate?.locationManager?.location {
                    params["lat"] = location.coordinate.latitude
                    params["lon"] = location.coordinate.longitude
                }
                
                //, parameters: params, encoding: .JSON
                Alamofire.request(.GET, Endpoint(path: "establishments"), parameters: params, encoding: .URL).validate().responseJSON { response in
                    switch response.result {
                    case .Success(let value as [String: AnyObject]):
                        Establishment.establishmentsFromJSON(value)
                    case .Failure(let error):
                        print("Establishments response is error: \(error)")
                    default:
                        print("Establishments response is incorrectly typed")
                   }
                }
            case .Failure(let error):
                print("Beers response is error: \(error)")
            default:
                print("Beers response is incorrectly typed")
            }
  		}
	}

	override func viewDidAppear(animated: Bool) {
		if (UIApplication.sharedApplication().delegate as? AppDelegate)?.drinker == nil {
			let modal = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("UserVerificationViewController") as! UserVerificationViewController

			modal.modalTransitionStyle = .CoverVertical

			self.presentViewController(modal, animated: true, completion: nil)
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	//MARK: insertNewObject
	@IBAction func insertNewObject(sender: AnyObject) {
		let context = self.fetchedResultsController.managedObjectContext
		let entity = self.fetchedResultsController.fetchRequest.entity!
		let 🏬 = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as! Establishment

		// If appropriate, configure the new managed object.
		// Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
		🏬.name = "Dive Bar"
		🏬.address = "12 Grimey Lane"


		// Save the context.
		do {
			try context.save()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			//println("Unresolved error \(error), \(error.userInfo)")
			abort()
		}
	}

	// MARK: - Segues

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showBeers" {
			if let indexPath = self.tableView.indexPathForSelectedRow {
                let selectedEstablishment: Establishment
                if filtering {
                    selectedEstablishment = filteredEstablishments[indexPath.row]
                } else {
                    selectedEstablishment = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Establishment
                }

				_ = selectedEstablishment.beerStatuses
				let controller = segue.destinationViewController as! BeersTableViewController

				controller.managedObjectContext = managedObjectContext
				controller.establishment = selectedEstablishment
			}
		}
	}

	// MARK: - Table View

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return self.fetchedResultsController.sections?.count ?? 0
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filtering {
            return filteredEstablishments.count
        }
        
		let sectionInfo = self.fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("EstablishmentCell", forIndexPath: indexPath) 
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}

	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}

	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if editingStyle == .Delete {
			let context = self.fetchedResultsController.managedObjectContext
			context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)

			do {
				try context.save()
			} catch {
				// Replace this implementation with code to handle the error appropriately.
				// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				//println("Unresolved error \(error), \(error.userInfo)")
				abort()
			}
		}
	}

	func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let 🏬: Establishment
        if filtering {
            🏬 = filteredEstablishments[indexPath.row]
        } else {
            🏬 = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Establishment
        }

		cell.textLabel?.text = 🏬.name

		var displayAddress = 🏬.address
		if let rangeOfAthens = displayAddress.rangeOfString("Athens", options: .CaseInsensitiveSearch) {
			displayAddress = displayAddress.substringWithRange(displayAddress.startIndex ..< rangeOfAthens.startIndex).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		}

		cell.detailTextLabel?.text = displayAddress
	}

	// MARK: - Fetched results controller

	var fetchedResultsController: NSFetchedResultsController {
		if _fetchedResultsController != nil {
			return _fetchedResultsController!
		}

		let fetchRequest = NSFetchRequest()
		// Edit the entity name as appropriate.
		let entity = NSEntityDescription.entityForName("Establishment", inManagedObjectContext: self.managedObjectContext!)
		fetchRequest.entity = entity

		// Set the batch size to a suitable number.
		fetchRequest.fetchBatchSize = 50

		// Edit the sort key as appropriate.

		//TODO: we need to sort based on the order sent by the server. add index generated from the order received from the server.
		let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)

		fetchRequest.sortDescriptors = [sortDescriptor]

		// Edit the section name key path and cache name if appropriate.
		// nil for section name key path means "no sections".
		let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Establishments")
		aFetchedResultsController.delegate = self
		_fetchedResultsController = aFetchedResultsController

		NSFetchedResultsController.deleteCacheWithName("Establishments")

		do {
			try _fetchedResultsController!.performFetch()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			//println("Unresolved error \(error), \(error.userInfo)")
			abort()
		}

		return _fetchedResultsController!
	}
	var _fetchedResultsController: NSFetchedResultsController? = nil
/*
	func controllerWillChangeContent(controller: NSFetchedResultsController) {
		self.tableView.beginUpdates()
	}

	func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
		switch type {
		case .Insert:
			self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
		case .Delete:
			self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
		default:
			return
		}
	}

	func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
		switch type {
		case .Insert:
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
		case .Delete:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
		case .Update:
			self.configureCell(tableView.cellForRowAtIndexPath(indexPath!)!, atIndexPath: indexPath!)
		case .Move:
			tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
			tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
		default:
			return
		}
	}

	func controllerDidChangeContent(controller: NSFetchedResultsController) {
		self.tableView.endUpdates()
	}
*/

	// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.

	func controllerDidChangeContent(controller: NSFetchedResultsController) {
	// In the simplest, most efficient, case, reload the table view.
		self.tableView.reloadData()
	}

    // MARK: - Filtering
    
    var filtering: Bool {
        return searchController.active && searchController.searchBar.text != ""
    }

    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredEstablishments = fetchedResultsController.fetchedObjects?
            .flatMap { $0 as? Establishment }
            .filter { $0.name.lowercaseString.containsString(searchText.lowercaseString) }
            ?? [Establishment]()
        
        tableView.reloadData()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            return
        }
        
        filterContentForSearchText(searchText)
    }
}
