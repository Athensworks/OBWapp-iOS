//
//  BeersTableViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import CoreData
import SwiftyJSON
import Alamofire


class BeersTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, ManagedObjectViewController {

	var managedObjectContext: NSManagedObjectContext? = nil
	var establishment: Establishment? = nil

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	//MARK: - Actions

	@IBAction func refreshBeers(sender: UIRefreshControl) {
		// /establishment/:establishment_id/beer_statuses

		Alamofire.request(.GET, Endpoint(path: "beers")).response { (_, _, data, error) in
			if let data = data as? NSData {
				Beer.beersFromJSON(data)

				if let establishment = self.establishment {
					Alamofire.request(.GET, Endpoint(path: "establishment/\(establishment.identifier)/beer_statuses")).response() { (_, _, statusData, _) in
						if let data = statusData as? NSData {
							let responseJSON = JSON(data: data)

							for (index: String, statusJSON: JSON) in responseJSON["beer_statuses"] {
								establishment.updateOrCreateStatusFromJSON(statusJSON)
							}

							self.fetchedResultsController.performFetch(nil)
						}

						self.refreshControl?.endRefreshing()
					}
				} else {
					self.refreshControl?.endRefreshing()
				}
			}
		}
	}

	@IBAction func tastedChanged(sender: UIButton) {
		sender.selected = !sender.selected

		if let indexPath = tableView.indexPathForRowAtPoint(tableView.convertPoint(sender.center, fromView: sender.superview)) {
			let 🍺: Beer

			if let status = fetchedResultsController.objectAtIndexPath(indexPath) as? BeerStatus {
				🍺 = status.beer
			} else {
				🍺 = fetchedResultsController.objectAtIndexPath(indexPath) as! Beer
			}

			🍺.tasted() { (count) in
				if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? BeerTableViewCell  {
					cell.tasteCountLabel.text = String(count)
				}
			}

			if let cell = tableView.cellForRowAtIndexPath(indexPath) as? BeerTableViewCell  {
				cell.favoritedButton.enabled = (sender.selected == true)
				cell.favoriteCountLabel.enabled = (sender.selected == true)
			}
		}
	}

	@IBAction func favoritedChanged(sender: UIButton) {
		sender.selected = !sender.selected

		if let indexPath = tableView.indexPathForRowAtPoint(tableView.convertPoint(sender.center, fromView: sender.superview)) {
			let 🍺: Beer

			if let status = fetchedResultsController.objectAtIndexPath(indexPath) as? BeerStatus {
				🍺 = status.beer
			} else {
				🍺 = fetchedResultsController.objectAtIndexPath(indexPath) as! Beer
			}

			🍺.favorited() { (count) in
				if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? BeerTableViewCell  {
					cell.favoriteCountLabel.text = String(count)
				}
			}
		}
	}

	@IBAction func insertNewObject(sender: AnyObject) {
		let context = self.fetchedResultsController.managedObjectContext
		let entity = self.fetchedResultsController.fetchRequest.entity!
		let 🍺 = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as! Beer
		     
		// If appropriate, configure the new managed object.
		// Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
		🍺.name = "Test Beer that is Good?"
		🍺.beerDescription = "Super hoppy so that hipsters will like it."
//		🍺.favorited = false
//		🍺.tasted = false


		// Save the context.
		var error: NSError? = nil
		if !context.save(&error) {
		    // Replace this implementation with code to handle the error appropriately.
		    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
		    //println("Unresolved error \(error), \(error.userInfo)")
		    abort()
		}
	}

	// MARK: - Segues

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = self.tableView.indexPathForSelectedRow() {
				if let detailController = (segue.destinationViewController as? BeerDetailViewController) {
					let 🍺: Beer

					if let status = fetchedResultsController.objectAtIndexPath(indexPath) as? BeerStatus {
						detailController.status = status
						🍺 = status.beer
					} else {
						🍺 = fetchedResultsController.objectAtIndexPath(indexPath) as! Beer
					}

					detailController.beer = 🍺
					detailController.managedObjectContext = managedObjectContext
				}
		    }
		}
	}

	// MARK: - Table View

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return self.fetchedResultsController.sections?.count ?? 0
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
		return sectionInfo.numberOfObjects
	}

	override func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
		return self.fetchedResultsController.sectionIndexTitles
	}

	override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
		return self.fetchedResultsController.sectionForSectionIndexTitle(title, atIndex: index)
	}

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if let sections = self.fetchedResultsController.sections as? [NSFetchedResultsSectionInfo] {
			if let index = sections[section].name?.toInt() {
				return BeerStatus.statusString(forStatus: BeerStatus.ordering[index])
			}
		}

		return nil
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("BeerCell", forIndexPath: indexPath) as! UITableViewCell
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
		        
		    var error: NSError? = nil
		    if !context.save(&error) {
		        // Replace this implementation with code to handle the error appropriately.
		        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
		        //println("Unresolved error \(error), \(error.userInfo)")
		        abort()
		    }
		}
	}

	func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		if let beerCell = cell as? BeerTableViewCell {
			let 🍺: Beer

			if let status = fetchedResultsController.objectAtIndexPath(indexPath) as? BeerStatus {
				🍺 = status.beer
			} else {
				🍺 = fetchedResultsController.objectAtIndexPath(indexPath) as! Beer
			}
			
			beerCell.nameLabel.text = 🍺.name
			beerCell.breweryNameLabel.text = 🍺.brewery
			beerCell.favoritedButton.selected = 🍺.favorite != nil ? true : false
			beerCell.favoriteCountLabel.text = String(🍺.favoriteCount)
			beerCell.tastedCheckboxButton.selected = 🍺.taste != nil ? true : false
			beerCell.tasteCountLabel.text = String(🍺.tasteCount)

			beerCell.favoritedButton.enabled = beerCell.tastedCheckboxButton.selected
			beerCell.favoriteCountLabel.enabled = beerCell.tastedCheckboxButton.selected

			beerCell.beerMetadataLabel.text = "ABV \(🍺.abv)% / \(🍺.ibu) IBU"

			beerCell.limitedReleaseImageView.hidden = (🍺.limitedRelease == false)
		}
	}

	// MARK: - Fetched results controller

	var fetchedResultsController: NSFetchedResultsController {
	    if _fetchedResultsController != nil {
	        return _fetchedResultsController!
	    }
	    
	    let fetchRequest = NSFetchRequest()
	    // Edit the entity name as appropriate.
		let entity: NSEntityDescription?
		let sortDescriptors: [NSSortDescriptor]
		var sectionNameKeyPath: String? = nil

		if let establishment = establishment {
			fetchRequest.predicate = NSPredicate(format: "establishment == %@", establishment)

			entity = NSEntityDescription.entityForName("BeerStatus", inManagedObjectContext: self.managedObjectContext!)

			sectionNameKeyPath = "section"
			let statusSortDescriptor = NSSortDescriptor(key: sectionNameKeyPath!, ascending: true)
			//NSSortDescriptor(key: sectionNameKeyPath!, ascending: true)

			let nameSortDescriptor = NSSortDescriptor(key: "beer.name", ascending: true)

			sortDescriptors = [statusSortDescriptor, nameSortDescriptor]
		} else {
			entity = NSEntityDescription.entityForName("Beer", inManagedObjectContext: self.managedObjectContext!)
			let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)

			sortDescriptors = [sortDescriptor]
		}

		fetchRequest.entity = entity

	    // Set the batch size to a suitable number.
	    fetchRequest.fetchBatchSize = 50
	    
	    // Edit the sort key as appropriate.
	    fetchRequest.sortDescriptors = sortDescriptors
	    
	    // Edit the section name key path and cache name if appropriate.
	    // nil for section name key path means "no sections".
	    let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: sectionNameKeyPath, cacheName: entity?.name)
	    aFetchedResultsController.delegate = self
	    _fetchedResultsController = aFetchedResultsController

		NSFetchedResultsController.deleteCacheWithName(entity?.name)
	    
		var error: NSError? = nil
		if !_fetchedResultsController!.performFetch(&error) {
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

	func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String?) -> String? {
		return nil
	}
}

