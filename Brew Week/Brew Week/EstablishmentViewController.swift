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

class EstablishmentViewController: UITableViewController, NSFetchedResultsControllerDelegate {

		var managedObjectContext: NSManagedObjectContext? = nil


		override func awakeFromNib() {
			super.awakeFromNib()
		}

		override func viewDidLoad() {
			super.viewDidLoad()
			// Do any additional setup after loading the view, typically from a nib.
			self.navigationItem.leftBarButtonItem = self.editButtonItem()

			Alamofire.request(.GET, "http://173.230.142.215:3000/beers").response { (request, response, data, error) in
				if data is NSData {
					Beer.beersFromJSON(data as! NSData)

					Alamofire.request(.GET, "http://173.230.142.215:3000/establishments").response { (request, response, establishmentData, error) in
						//parameters: <#[String : AnyObject]?#>, encoding: <#ParameterEncoding#>)
						if establishmentData is NSData {
							Establishment.establishmentsFromJSON(establishmentData as! NSData)
						}
					}
				}
			}
		}

		override func viewDidAppear(animated: Bool) {
			if NSUserDefaults.standardUserDefaults().boolForKey("AgeVerified") == false {
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
			if segue.identifier == "showBeers" {
				if let indexPath = self.tableView.indexPathForSelectedRow() {
					let selectedEstablishment = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Establishment

					let beerStatuses = selectedEstablishment.beerStatuses
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
			let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
			return sectionInfo.numberOfObjects
		}

		override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
			let cell = tableView.dequeueReusableCellWithIdentifier("EstablishmentCell", forIndexPath: indexPath) as! UITableViewCell
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
			let 🏬 = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Establishment

			cell.textLabel?.text = 🏬.name
			cell.detailTextLabel?.text = 🏬.address
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
			fetchRequest.fetchBatchSize = 20

			// Edit the sort key as appropriate.
			let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
			let sortDescriptors = [sortDescriptor]

			fetchRequest.sortDescriptors = [sortDescriptor]

			// Edit the section name key path and cache name if appropriate.
			// nil for section name key path means "no sections".
			let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Establishments")
			aFetchedResultsController.delegate = self
			_fetchedResultsController = aFetchedResultsController

			NSFetchedResultsController.deleteCacheWithName("Establishments")

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

		/*
	 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.

	 func controllerDidChangeContent(controller: NSFetchedResultsController) {
		// In the simplest, most efficient, case, reload the table view.
		self.tableView.reloadData()
	 }
	 */

}
