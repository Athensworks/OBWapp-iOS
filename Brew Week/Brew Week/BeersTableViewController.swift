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
    var sort = SortOrder.Name
    var sortAscending = true
    var filter = FilterMode.All
    var searchText: String?
    

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
        super.viewWillAppear(animated)
        
        if establishment != nil || brewery != nil {
            navigationItem.leftBarButtonItems = []
        }
    }

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

    func refreshResults() {
        _fetchedResultsController = nil
        tableView.reloadData()
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
        
        
        let sortTitle: (SortOrder, String, String, String) -> String = { order, totality, minimum, maximum in
            let title: String
            if self.sort != order {
                title = totality
            } else if self.sortAscending {
                title = "\(maximum) ➙ \(minimum)"
            } else {
                title = "\(minimum) ➙ \(maximum)"
            }
            return title
        }
        
        
        // Name
        
        let sortNameAction = UIAlertAction(title: sortTitle(.Name, "Name", "A", "Z"), style: .Default) { action in
            self.sortAscending = self.sort == .Name ? !self.sortAscending : true
            self.sort = .Name
            self.refreshResults()
        }
        
        alert.addAction(sortNameAction)
        
        
        // Alcohol content
        
        let sortABVAction = UIAlertAction(title: sortTitle(.AlcoholContent, "Alcohol Content", "Session", "Imperial"), style: .Default) { action in
            self.sortAscending = self.sort == .AlcoholContent ? !self.sortAscending : false
            self.sort = .AlcoholContent
            self.refreshResults()
        }
        
        alert.addAction(sortABVAction)
        
        
        // Bitterness
        
        let sortIBUAction = UIAlertAction(title: sortTitle(.Bitterness, "Bitterness", "Malty", "Bitter"), style: .Default) { action in
            self.sortAscending = self.sort == .Bitterness ? !self.sortAscending : false
            self.sort = .Bitterness
            self.refreshResults()
        }
        
        alert.addAction(sortIBUAction)
        
        
        // Popularity
        
        let sortPopularityAction = UIAlertAction(title: sortTitle(.Popularity, "Popularity", "Unpopular", "Popular"), style: .Default) { action in
            self.sortAscending = self.sort == .Popularity ? !self.sortAscending : false
            self.sort = .Popularity
            self.refreshResults()
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
        
        
        // All
        
        let filterAllAction = UIAlertAction(title: "All", style: .Default) { action in
            self.filter = .All
            self.refreshResults()
        }
        
        alert.addAction(filterAllAction)
        
        
        // Interested
        
        let filterInterestedAction = UIAlertAction(title: "Interested", style: .Default) { action in
            self.filter = .Interested
            self.refreshResults()
        }
        
        alert.addAction(filterInterestedAction)
        
        
        // Liked
        
        let filterLikedAction = UIAlertAction(title: "Liked", style: .Default) { action in
            self.filter = .Liked
            self.refreshResults()
        }
        
        alert.addAction(filterLikedAction)
        
        
        // Disliked
        
        let filterDislikedAction = UIAlertAction(title: "Disliked", style: .Default) { action in
            self.filter = .Disliked
            self.refreshResults()
        }
        
        alert.addAction(filterDislikedAction)
        
        
        // Available
        
        let filterAvailableAction = UIAlertAction(title: "Available", style: .Default) { action in
            self.filter = .Available
            self.refreshResults()
        }
        
        alert.addAction(filterAvailableAction)
        
        
        presentViewController(alert, animated: true) {
            
        }
    }

	// MARK: - Segues

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showDetail" {
		    if let indexPath = self.tableView.indexPathForSelectedRow {
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
		return true
	}
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let beer: Beer
        if let status = fetchedResultsController.objectAtIndexPath(indexPath) as? BeerStatus {
            beer = status.beer
        } else {
            beer = fetchedResultsController.objectAtIndexPath(indexPath) as! Beer
        }
        
        let clearAction = UITableViewRowAction(style: .Normal, title: "Untried") { action, indexPath in
            beer.reacted(0)
            tableView.editing = false
        }

        let saveAction = UITableViewRowAction(style: .Normal, title: "Interested") { action, indexPath in
            beer.reacted(1)
            tableView.editing = false
        }
        saveAction.backgroundColor = UIColor(hue: 0.75, saturation: 0.45, brightness: 0.9, alpha: 1)
        
        let likeAction = UITableViewRowAction(style: .Normal, title: "Liked") { action, indexPath in
            beer.reacted(2)
            tableView.editing = false
        }
        likeAction.backgroundColor = UIColor(hue: 0.325, saturation: 0.6, brightness: 0.9, alpha: 1)
        
        let dislikeAction = UITableViewRowAction(style: .Normal, title: "Disliked") { action, indexPath in
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

            if let status = fetchedResultsController.objectAtIndexPath(indexPath) as? BeerStatus {
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
        fetchRequest.entity = NSEntityDescription.entityForName(establishment == nil ? "Beer" : "BeerStatus", inManagedObjectContext: managedObjectContext!)
        
        var predicates = [NSPredicate]()
        
        let attributePrefix: String
        if let e = establishment {
            predicates.append(NSPredicate(format: "establishment == %@", e))
            attributePrefix = "beer."
        } else {
            attributePrefix = ""
        }
        
        if let b = brewery {
            predicates.append(NSPredicate(format: "brewery == %@", b))
        }
        
        switch filter {
        case .All:
            break
        case .Interested:
            predicates.append(NSPredicate(format: "\(attributePrefix)drinkerReaction == 1"))
        case .Liked:
            predicates.append(NSPredicate(format: "\(attributePrefix)drinkerReaction == 2"))
        case .Disliked:
            predicates.append(NSPredicate(format: "\(attributePrefix)drinkerReaction == 3"))
        case .Available:
            if establishment != nil {
                predicates.append(NSPredicate(format: "status LIKE[c] %@", "tapped"))
            } else {
                predicates.append(NSPredicate(format: "SUBQUERY(statuses, $status, $status.status LIKE[c] %@).@count > 0", "tapped"))
            }
        }
        
        if let s = searchText {
            let searchPredicates = s.componentsSeparatedByString(" ")
                .filter { $0.isEmpty == false }
                .map { NSPredicate(format: "\(attributePrefix)name CONTAINS[cd] %@", $0) }
            
            if searchPredicates.isEmpty == false {
                predicates.append(NSCompoundPredicate(andPredicateWithSubpredicates: searchPredicates))
            }
        }
        
        fetchRequest.predicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        var sortDescriptors = [NSSortDescriptor]()
        
        if establishment != nil {
            sortDescriptors.append(NSSortDescriptor(key: "section", ascending: true))
        }
        
        switch sort {
        case .Name:
            sortDescriptors.append(NSSortDescriptor(key: "\(attributePrefix)name", ascending: sortAscending))
        case .AlcoholContent:
            sortDescriptors.append(NSSortDescriptor(key: "\(attributePrefix)abv", ascending: sortAscending))
        case .Bitterness:
            sortDescriptors.append(NSSortDescriptor(key: "\(attributePrefix)ibu", ascending: sortAscending))
        case .Popularity:
            sortDescriptors.append(NSSortDescriptor(key: "\(attributePrefix)favoriteCount", ascending: sortAscending))
        }
        
		fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.fetchBatchSize = 50
		
	    let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: establishment != nil ? "section" : nil, cacheName: fetchRequest.entityName)
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
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        searchText = searchController.searchBar.text
        refreshResults()
    }
}

enum SortOrder {
    case Name
    case Popularity
    case AlcoholContent
    case Bitterness
}

enum FilterMode {
    case All
    case Interested
    case Liked
    case Disliked
    case Available
}
