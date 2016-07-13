//
//  BeersTableViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import CoreData
import Alamofire


class BeersTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, ManagedObjectViewController, UISearchResultsUpdating {
    
    let searchController = UISearchController(searchResultsController: nil)
    
	var managedObjectContext: NSManagedObjectContext? = nil
	var establishment: Establishment? = nil
    var brewery: Brewery? = nil
    var filteredBeers = [Beer]()

	override func awakeFromNib() {
		super.awakeFromNib()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
	}
    
    override func viewWillAppear(animated: Bool) {
        if establishment != nil || brewery != nil {
            navigationItem.leftBarButtonItems = []
        }
    }

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	//MARK: - Actions

    @IBAction func refreshBeers(sender: UIRefreshControl) {
        // /establishment/:establishment_id/beer_statuses
        
        Alamofire.request(.GET, Endpoint(path: "beers")).validate().responseJSON { beersResponse in
            switch beersResponse.result {
            case .Success(let beersJSON as [String: [AnyObject]]):
                Beer.beersFromJSON(beersJSON)
                
                if let establishment = self.establishment {
                    Alamofire.request(.GET, Endpoint(path: "establishment/\(establishment.identifier)/beer_statuses")).validate().responseJSON { statusesResponse in
                        switch statusesResponse.result {
                        case .Success(let statusesJSON as [String: [AnyObject]]):
                            if let statuses = statusesJSON["beer_statuses"] as? [[String: AnyObject]] {
                                for status in statuses {
                                    establishment.updateOrCreateStatusFromJSON(status)
                                }
                            }
                            
                            do {
                                try self.fetchedResultsController.performFetch()
                            } catch let error {
                                print("Fetch failed: \(error)")
                            }
                        case .Failure(let error):
                            print("Beer statuses at establishment \(establishment.identifier) response is error: \(error)")
                        default:
                            print("Beer statuses at establishment \(establishment.identifier) response is incorrectly typed")
                        }
                    }
                }
            
            case .Failure(let error):
                print("Beers response is error: \(error)")
                self.refreshControl?.endRefreshing()

            default:
                print("Beers response is incorrectly typed")
                self.refreshControl?.endRefreshing()

            }
            
            sender.endRefreshing()
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

			🍺.tasted(sender.selected) { count in
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

			🍺.favorited(sender.selected) { count in
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
		do {
			try context.save()
		} catch {
		    // Replace this implementation with code to handle the error appropriately.
		    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
		    //println("Unresolved error \(error), \(error.userInfo)")
		    abort()
		}
	}
    
    @IBAction func sortBeers(sender: AnyObject)
    {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            
        }
        
        alert.addAction(cancelAction)
        
        let sortK = sort[0].key ?? ""
        let sortAscending = sort[0].ascending
        
        let sortNameAction = UIAlertAction(title: "Name" + (sortK == "name" ? " Reversed" : ""), style: .Default) { action in
            self.sort = [NSSortDescriptor(key: "name", ascending: sortK == "name" ? !sortAscending : true)]
        }
        
        alert.addAction(sortNameAction)
        
        let sortABVAction = UIAlertAction(title: "Alcohol Content" + (sortK == "abv" ? " Reversed" : ""), style: .Default) { action in
            self.sort = [NSSortDescriptor(key: "abv", ascending: sortK == "abv" ? !sortAscending : false)]
        }
        
        alert.addAction(sortABVAction)
        
        let sortIBUAction = UIAlertAction(title: "Bitterness" + (sortK == "ibu" ? " Reversed" : ""), style: .Default) { action in
            self.sort = [NSSortDescriptor(key: "ibu", ascending: sortK == "ibu" ? !sortAscending : false)]
        }
        
        alert.addAction(sortIBUAction)
        
        let sortPopularityAction = UIAlertAction(title: "Popularity" + (sortK == "favoriteCount" ? " Reversed" : ""), style: .Default) { action in
            self.sort = [NSSortDescriptor(key: "favoriteCount", ascending: sortK == "favoriteCount" ? !sortAscending : false)]
        }
        
        alert.addAction(sortPopularityAction)
        
        presentViewController(alert, animated: true) {
            
        }
    }
    
    @IBAction func filterBeers(sender: AnyObject)
    {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            
        }
        
        alert.addAction(cancelAction)
        
        let filterAllAction = UIAlertAction(title: "All", style: .Default) { action in
            self.filter = nil
        }
        
        alert.addAction(filterAllAction)
        
        let filterInterestedAction = UIAlertAction(title: "Interested", style: .Default) { action in
            self.filter = NSPredicate(format: "drinkerReaction == 1")
        }
        
        alert.addAction(filterInterestedAction)
        
        let filterLikedAction = UIAlertAction(title: "Liked", style: .Default) { action in
            self.filter = NSPredicate(format: "drinkerReaction == 2")
        }
        
        alert.addAction(filterLikedAction)
        
        let filterDislikedAction = UIAlertAction(title: "Disliked", style: .Default) { action in
            self.filter = NSPredicate(format: "drinkerReaction == 3")
        }
        
        alert.addAction(filterDislikedAction)
        
        presentViewController(alert, animated: true) {
            
        }
    }

	// MARK: - Segues

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = self.tableView.indexPathForSelectedRow {
				if let detailController = (segue.destinationViewController as? BeerDetailViewController) {
					let 🍺: Beer

                    if filtering {
                        🍺 = filteredBeers[indexPath.row]
                    } else if let status = fetchedResultsController.objectAtIndexPath(indexPath) as? BeerStatus {
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
        if filtering {
            return filteredBeers.count
        }
        
        let sectionInfo = self.fetchedResultsController.sections![section]
		return sectionInfo.numberOfObjects
	}

	override func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? {
		return self.fetchedResultsController.sectionIndexTitles
	}

	override func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
		return self.fetchedResultsController.sectionForSectionIndexTitle(title, atIndex: index)
	}

	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if let sections = self.fetchedResultsController.sections {
			if let index = Int(sections[section].name) {
				return BeerStatus.statusString(forStatus: BeerStatus.ordering[index])
			}
		}

		return nil
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("BeerCell", forIndexPath: indexPath) 
		self.configureCell(cell, atIndexPath: indexPath)
		return cell
	}

	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		// Return false if you do not want the specified item to be editable.
		return true
	}
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let beer: Beer
        if filtering {
            beer = filteredBeers[indexPath.row]
        } else if let status = fetchedResultsController.objectAtIndexPath(indexPath) as? BeerStatus {
            beer = status.beer
        } else {
            beer = fetchedResultsController.objectAtIndexPath(indexPath) as! Beer
        }
        
        let clearAction = UITableViewRowAction(style: .Normal, title: "Clear") { action, indexPath in
            beer.reacted(0)
            tableView.editing = false
        }

        let saveAction = UITableViewRowAction(style: .Normal, title: "Interested") { action, indexPath in
            beer.reacted(1)
            tableView.editing = false
        }
        saveAction.backgroundColor = UIColor(hue: 0.75, saturation: 0.45, brightness: 0.9, alpha: 1)
        
        let likeAction = UITableViewRowAction(style: .Normal, title: "Like") { action, indexPath in
            beer.reacted(2)
            tableView.editing = false
        }
        likeAction.backgroundColor = UIColor(hue: 0.325, saturation: 0.6, brightness: 0.9, alpha: 1)
        
        let dislikeAction = UITableViewRowAction(style: .Normal, title: "Dislike") { action, indexPath in
            beer.reacted(3)
            tableView.editing = false
        }
        dislikeAction.backgroundColor = UIColor(hue: 0, saturation: 0.7, brightness: 1, alpha: 1)

        let actions: [UITableViewRowAction]
        switch beer.drinkerReaction {
        case 1: // Interested
            actions = [dislikeAction, likeAction, clearAction]
        case 2: // Liked
            actions = [dislikeAction, saveAction, clearAction]
        case 3: // Disliked
            actions = [likeAction, saveAction, clearAction]
        default:
            actions = [dislikeAction, likeAction, saveAction]
        }
        
        return actions
    }

	func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
		if let beerCell = cell as? BeerTableViewCell {
			let 🍺: Beer

            if filtering {
                🍺 = filteredBeers[indexPath.row]
            } else if let status = fetchedResultsController.objectAtIndexPath(indexPath) as? BeerStatus {
				🍺 = status.beer
			} else {
				🍺 = fetchedResultsController.objectAtIndexPath(indexPath) as! Beer
			}
			
			beerCell.nameLabel.text = 🍺.name
			beerCell.breweryNameLabel.text = 🍺.brewery.name
			beerCell.favoritedButton.selected = false
			beerCell.favoriteCountLabel.text = String(🍺.favoriteCount)
			beerCell.tastedCheckboxButton.selected = 🍺.taste != nil ? true : false
			beerCell.tasteCountLabel.text = String(🍺.tasteCount)
            
            let markEmoji: String
            switch (🍺.drinkerReaction) {
            case 1: // Interested
                markEmoji = "🤔"
            case 2: // Liked
                markEmoji = "👍"
            case 3: // Disliked
                markEmoji = "👎"
            default:
                markEmoji = ""
            }
            
            beerCell.drinkerReactionLabel.text = markEmoji

            beerCell.tastedCheckboxButton.userInteractionEnabled = false
			beerCell.favoritedButton.userInteractionEnabled = false

            if 🍺.abv >= 0 && 🍺.ibu >= 0 {
                beerCell.beerMetadataLabel.text = "\(🍺.abv)% ABV\u{2003}\(🍺.ibu) IBU"
            } else if 🍺.abv >= 0 {
                beerCell.beerMetadataLabel.text = "\(🍺.abv)% ABV"
            } else if 🍺.ibu >= 0 {
                beerCell.beerMetadataLabel.text = "\(🍺.ibu) IBU"
            } else {
                beerCell.beerMetadataLabel.text = ""
            }

			beerCell.limitedReleaseImageView.hidden = (🍺.limitedRelease == false)
		}
	}

	// MARK: - Fetched results controller

	var fetchedResultsController: NSFetchedResultsController {
	    if _fetchedResultsController != nil {
	        return _fetchedResultsController!
	    }
	    
	    let fetchRequest = NSFetchRequest()
        fetchRequest.entity = NSEntityDescription.entityForName(establishment != nil ? "BeerStatus" : "Beer", inManagedObjectContext: managedObjectContext!)
        fetchRequest.predicate = filter
		fetchRequest.sortDescriptors = sort
        fetchRequest.fetchBatchSize = 50
		
        var sectionNameKeyPath: String? = nil

		if let establishment = establishment {
			fetchRequest.predicate = NSPredicate(format: "establishment == %@", establishment)

			sectionNameKeyPath = "section"
			let statusSortDescriptor = NSSortDescriptor(key: sectionNameKeyPath!, ascending: true)
			//NSSortDescriptor(key: sectionNameKeyPath!, ascending: true)

			let nameSortDescriptor = NSSortDescriptor(key: "beer.name", ascending: true)

			fetchRequest.sortDescriptors = [statusSortDescriptor, nameSortDescriptor]
            
        } else if let brewery = brewery {
            fetchRequest.predicate = NSPredicate(format: "brewery == %@", brewery)
		}
        
	    // Edit the section name key path and cache name if appropriate.
	    // nil for section name key path means "no sections".
	    let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: sectionNameKeyPath, cacheName: fetchRequest.entityName)
	    aFetchedResultsController.delegate = self
	    _fetchedResultsController = aFetchedResultsController

		NSFetchedResultsController.deleteCacheWithName(fetchRequest.entityName)
	    
		do {
			try _fetchedResultsController!.performFetch()
		} catch {
            print(exception)
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

	func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
		return nil
	}
    
    // MARK: - Filtering
    
    var filtering: Bool {
        return searchController.active && searchController.searchBar.text != ""
    }
    
    var sort = [NSSortDescriptor(key: "name", ascending: true)] {
        didSet {
            fetchAndReload()
        }
    }
    
    var filter: NSPredicate? {
        didSet {
            fetchAndReload()
        }
    }
    
    func fetchAndReload() {
        _fetchedResultsController = nil
        tableView.reloadData()
    }
    
    func filterContentForSearchText(searchText: String) {
        let substrings = searchText.componentsSeparatedByString(" ")
            .filter { $0.isEmpty == false }
            .map { $0.lowercaseString }
        
        filteredBeers = fetchedResultsController.fetchedObjects?
            .flatMap { $0 as? Beer }
            .filter { beer in
                let lowercaseName = beer.name.lowercaseString
                for substring in substrings {
                    if lowercaseName.containsString(substring) == false {
                        return false
                    }
                }
                return true
            }
            ?? [Beer]()
        
        tableView.reloadData()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else {
            return
        }
        
        filterContentForSearchText(searchText)
    }
}

