//
//  BeerDetailViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import Alamofire
import CoreData


class BeerDetailViewController: UIViewController, ManagedObjectViewController {
	var managedObjectContext: NSManagedObjectContext? = nil

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var limitedReleaseView: UIView!
	@IBOutlet weak var breweryNameLabel: UILabel!

	@IBOutlet weak var detailDescriptionLabel: UILabel!
	@IBOutlet weak var rateBeerButton: UIButton!

	@IBOutlet weak var statusAvailabilityLabel: UILabel!
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var ibuLabel: UILabel!
	@IBOutlet weak var abvLabel: UILabel!

	@IBOutlet weak var tasteCount: UILabel!
	@IBOutlet weak var tasteCountImageView: UIImageView!
	@IBOutlet weak var favoriteCount: UILabel!
	@IBOutlet weak var favoriteCountImageView: UIImageView!

	@IBOutlet weak var tastedButton: UIButton!
	@IBOutlet weak var favoritedButton: UIButton!
	@IBOutlet weak var bottomLayoutConstraint: NSLayoutConstraint!

    @IBOutlet weak var reactionEmojiLabel: UILabel!
    @IBOutlet weak var reactionButton: UIButton!
    
	@IBOutlet weak var reportButton: UIButton!

	var status: BeerStatus?
	var beer: Beer? {
		didSet {
		    // Update the view.
		    self.configureView()
		}
	}

	func configureView() {
		// Update the user interface for the detail item.

		if isViewLoaded() == false {
			return
		}

		tasteCountImageView.image = tasteCountImageView.image?.colorizedImage(UIColor.brewWeekGold())
		favoriteCountImageView.image = favoriteCountImageView.image?.colorizedImage(UIColor.brewWeekRed())

		tastedButton.setImage(tastedButton.imageForState(.Normal)?.colorizedImage(UIColor.whiteColor()), forState: .Normal)
		tastedButton.setImage(tastedButton.imageForState(.Selected)?.colorizedImage(UIColor.whiteColor()), forState: .Selected)

		favoritedButton.setImage(favoritedButton.imageForState(.Normal)?.colorizedImage(UIColor.whiteColor()), forState: .Normal)
		favoritedButton.setImage(favoritedButton.imageForState(.Selected)?.colorizedImage(UIColor.whiteColor()), forState: .Selected)

		if let beer = self.beer {
			nameLabel.text = beer.name
			limitedReleaseView.hidden = (beer.limitedRelease == false)
			breweryNameLabel.text = beer.brewery.name

			detailDescriptionLabel.text = beer.beerDescription

            abvLabel.text = beer.abv >= 0 ? "\(beer.abv)%" : "Unknown"
            ibuLabel.text = beer.ibu >= 0 ? String(beer.ibu) : "Unknown"

			tasteCount.text = String(beer.tasteCount)
			favoriteCount.text = String(beer.favoriteCount)

			tastedButton.selected = beer.taste != nil ? true : false;
			favoritedButton.selected = beer.favorite != nil ? true : false;
			favoritedButton.enabled = (tastedButton.selected == true)

			rateBeerButton.hidden = (beer.rateBeerID <= 0)
            
            configureReactionSubview()
		}

		if let status = self.status {
			switch status.status {
				case "empty":
					statusLabel.backgroundColor = UIColor.brewWeekRed()

					self.reportButton.hidden = true
				case "empty-reported":
					statusLabel.backgroundColor = UIColor.brewWeekRed()

					self.reportButton.setTitle("Reported Out! Tap here to confirm it…", forState: .Normal)
					self.reportButton.titleLabel?.font = UIFont.italicSystemFontOfSize(UIFont.systemFontSize())

					self.reportButton.hidden = false
				case "untapped":
					statusLabel.backgroundColor = UIColor.grayColor()

					self.reportButton.hidden = true
				case "tapped":
					statusLabel.backgroundColor = UIColor.brewWeekGold()

					self.reportButton.hidden = false
				case "cancelled":
					statusLabel.backgroundColor = UIColor.grayColor()

					self.reportButton.hidden = true
				default:
					statusLabel.backgroundColor = UIColor.grayColor()
					self.reportButton.hidden = true
			}

			statusLabel.text = status.statusString()

			statusLabel.textColor = UIColor.whiteColor()
			statusAvailabilityLabel.text = "Status"

			reportButton.hidden = false
			bottomLayoutConstraint.constant = 54
		} else {
			// no status set
			reportButton.hidden = true
			bottomLayoutConstraint.constant = 12

			if let beer = self.beer {
				let fetch = NSFetchRequest(entityName: "BeerStatus")

				fetch.predicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [
					NSPredicate(format: "beer.identifier == %d", beer.identifier),
					NSPredicate(format: "status LIKE[cd] %@", "tapped")
					])


                var fetchedStatuses: [BeerStatus]?
                do {
                    fetchedStatuses = try self.managedObjectContext?.executeFetchRequest(fetch) as? [BeerStatus]
                } catch {
                    fetchedStatuses = nil
                }
				if let statuses = fetchedStatuses {
					let establishments = Set(statuses.map { (BeerStatus) -> Establishment  in
						return BeerStatus.establishment
					})

					var establishmentNames: String = ""
					for establishment in establishments {
						if establishmentNames.characters.count > 0 {
							establishmentNames += ", "
						}
						
						establishmentNames += "\(establishment.name)"
					}

					if establishmentNames.characters.count > 0 {
						statusLabel.text = establishmentNames
					} else {
						statusLabel.text = "Not Available"
					}
					
					statusLabel.backgroundColor = UIColor.clearColor()
					statusLabel.textColor = UIColor.blackColor()

					statusAvailabilityLabel.text = "Where"
				}
			}
		}
	}
    
    func configureReactionSubview() {
        guard let beer = beer else {
            return
        }
        
        switch beer.drinkerReaction {
        case 1: // Interested
            reactionEmojiLabel.text = "🤔"
            reactionButton.setTitle("You are interested in this beer.", forState: .Normal)
        case 2: // Liked
            reactionEmojiLabel.text = "👍"
            reactionButton.setTitle("You liked this beer!", forState: .Normal)
        case 3: // Disliked
            reactionEmojiLabel.text = "👎"
            reactionButton.setTitle("You did not like this beer.", forState: .Normal)
        default:
            reactionEmojiLabel.text = "🍺"
            reactionButton.setTitle("Interested in or tried this beer?", forState: .Normal)
        }
    }

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		self.configureView()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: Actions

	@IBAction func tastedChanged(sender: UIButton) {
		sender.selected = !sender.selected

		beer?.tasted(sender.selected) { count in
			self.tasteCount.text = String(count)
		}

		self.favoritedButton.enabled = (sender.selected == true)
	}

	@IBAction func favoritedChanged(sender: UIButton) {
		sender.selected = !sender.selected

		beer?.favorited(sender.selected) { count in
			self.favoriteCount.text = String(count)
		}
	}

	@IBAction func rateBeerAction(sender: UIButton) {
		if let beer = self.beer {
			if let url = beer.rateBeerURL {
				UIApplication.sharedApplication().openURL(url)
			}
		}
	}
    
    @IBAction func changeReaction(sender: UIButton) {
        guard let beer = beer where sender == reactionButton else {
            return
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            
        }
        
        alert.addAction(cancelAction)
        
        let dislikeAction = UIAlertAction(title: "Dislike", style: .Default) { action in
            let expectations = beer.reacted(3)
            self.configureReactionSubview()
            self.tasteCount.text = String(expectations.expectedTasteCount)
            self.favoriteCount.text = String(expectations.expectedFavoriteCount)
        }
        
        alert.addAction(dislikeAction)
        
        let likeAction = UIAlertAction(title: "Like", style: .Default) { action in
            let expectations = beer.reacted(2)
            self.configureReactionSubview()
            self.tasteCount.text = String(expectations.expectedTasteCount)
            self.favoriteCount.text = String(expectations.expectedFavoriteCount)
        }
        
        alert.addAction(likeAction)
        
        let interestedAction = UIAlertAction(title: "Interested", style: .Default) { action in
            let expectations = beer.reacted(1)
            self.configureReactionSubview()
            self.tasteCount.text = String(expectations.expectedTasteCount)
            self.favoriteCount.text = String(expectations.expectedFavoriteCount)
        }
        
        alert.addAction(interestedAction)
        
        let clearAction = UIAlertAction(title: "Not Interested", style: .Default) { action in
            let expectations = beer.reacted(0)
            self.configureReactionSubview()
            self.tasteCount.text = String(expectations.expectedTasteCount)
            self.favoriteCount.text = String(expectations.expectedFavoriteCount)
        }
        
        alert.addAction(clearAction)
        
        presentViewController(alert, animated: true) {
            
        }
    }

	@IBAction func reportAction(sender: UIButton) {
//		{
//			"beer_id": 123,
//			"establishment_id": 345,
//			"device_guid": "6b981317-1c2d-4219-ad79-7235013ad597"
//		}

		if let beer = self.beer {
			if let status = self.status,
             let guid = UIDevice.currentDevice().identifierForVendor?.UUIDString {
				var params = [String: AnyObject]()

				params["beer_id"] = Int(beer.identifier)
				params["establishment_id"] = Int(status.establishment.identifier)
                params["device_guid"] = guid
                
                Alamofire.request(.PUT, Endpoint(path: "report"), parameters: params, encoding: .JSON).validate().responseJSON { response in
                    sender.setTitle("Reported. Thanks!", forState: .Normal)
                    sender.enabled = false
                }
            }
        }
	}
}

