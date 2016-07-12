//
//  BreweryViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 5/29/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import CoreData
import Alamofire


class BreweryViewController: UITableViewController, NSFetchedResultsControllerDelegate, ManagedObjectViewController, UISearchResultsUpdating {
	
    let searchController = UISearchController(searchResultsController: nil)
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var filteredBreweries = [Brewery]()

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func viewDidLoad() {
		super.viewDidLoad()

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        fetchBreweries() { fetchSucceeded in
            self.tableView.reloadData()
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
    
    func fetchBreweries(completion: Bool -> Void) {
        Alamofire.request(.GET, Endpoint(path: "breweries")).validate().responseJSON { response in
            switch response.result {
            case .Success(let breweriesJSON as [String: AnyObject]):
                Brewery.breweriesFromJSON(breweriesJSON)
                completion(true)
            case .Failure(let error):
                print("Breweries response is error: \(error)")
                completion(false)
            default:
                print("Breweries response is incorrectly typed")
                completion(false)
            }
        }
    }

	//MARK: - Actions
    
	@IBAction func insertNewObject(sender: AnyObject) {
		let context = self.fetchedResultsController.managedObjectContext
		let entity = self.fetchedResultsController.fetchRequest.entity!
		let 🏬 = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as! Brewery

		// If appropriate, configure the new managed object.
		// Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
		🏬.name = "Ohio Brewery"


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
    
    @IBAction func refreshBreweries(sender: UIRefreshControl) {
        fetchBreweries() { fetchSucceeded in
            sender.endRefreshing()
            self.tableView.reloadData()
        }
    }

	// MARK: - Segues

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showBeers" {
			if let indexPath = self.tableView.indexPathForSelectedRow {
                let selectedBrewery: Brewery
                if filtering {
                    selectedBrewery = filteredBreweries[indexPath.row]
                } else if let b = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Brewery {
                    selectedBrewery = b
                } else {
                    print("Uh oh")
                    return
                }
                
				let controller = segue.destinationViewController as! BeersTableViewController

				controller.managedObjectContext = managedObjectContext
				controller.brewery = selectedBrewery
			}
		}
	}

	// MARK: - Table View

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return self.fetchedResultsController.sections?.count ?? 0
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if filtering {
            return filteredBreweries.count
        }
        
		let sectionInfo = self.fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("BreweryCell", forIndexPath: indexPath)
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
        let 🏬: Brewery
        if filtering {
            🏬 = filteredBreweries[indexPath.row]
        } else {
            🏬 = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Brewery
        }

		cell.textLabel?.text = 🏬.name
		cell.detailTextLabel?.text = nil
	}

	// MARK: - Fetched results controller

	var fetchedResultsController: NSFetchedResultsController {
		if _fetchedResultsController != nil {
			return _fetchedResultsController!
		}

		let fetchRequest = NSFetchRequest()
		// Edit the entity name as appropriate.
		let entity = NSEntityDescription.entityForName("Brewery", inManagedObjectContext: self.managedObjectContext!)
		fetchRequest.entity = entity

		// Set the batch size to a suitable number.
		fetchRequest.fetchBatchSize = 50

		// Edit the sort key as appropriate.

		//TODO: we need to sort based on the order sent by the server. add index generated from the order received from the server.
		let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)

		fetchRequest.sortDescriptors = [sortDescriptor]

		// Edit the section name key path and cache name if appropriate.
		// nil for section name key path means "no sections".
		let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Breweries")
		aFetchedResultsController.delegate = self
		_fetchedResultsController = aFetchedResultsController

		NSFetchedResultsController.deleteCacheWithName("Breweries")

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
        let substrings = searchText.componentsSeparatedByString(" ")
            .filter { $0.isEmpty == false }
            .map { $0.lowercaseString }
        
        filteredBreweries = fetchedResultsController.fetchedObjects?
            .flatMap { $0 as? Brewery }
            .filter { brewery in
                let lowercaseName = brewery.name.lowercaseString
                for substring in substrings {
                    if lowercaseName.containsString(substring) == false {
                        return false
                    }
                }
                return true
            }
            ?? [Brewery]()
        
        tableView.reloadData()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            return
        }
        
        filterContentForSearchText(searchText)
    }
}
