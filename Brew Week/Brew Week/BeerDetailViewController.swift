//
//  BeerDetailViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import Alamofire


class BeerDetailViewController: UIViewController {

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var limitedReleaseView: UIView!
	@IBOutlet weak var breweryNameLabel: UILabel!

	@IBOutlet weak var detailDescriptionLabel: UILabel!
	@IBOutlet weak var rateBeerButton: UIButton!

	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var ibuLabel: UILabel!
	@IBOutlet weak var abvLabel: UILabel!

	@IBOutlet weak var tasteCount: UILabel!
	@IBOutlet weak var tasteCountImageView: UIImageView!
	@IBOutlet weak var favoriteCount: UILabel!
	@IBOutlet weak var favoriteCountImageView: UIImageView!

	@IBOutlet weak var tastedButton: UIButton!
	@IBOutlet weak var favoritedButton: UIButton!

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
			breweryNameLabel.text = beer.brewery

			detailDescriptionLabel.text = beer.beerDescription

			abvLabel.text = "\(beer.abv)%"
			ibuLabel.text = String(beer.ibu)

			tasteCount.text = String(beer.tasteCount)
			favoriteCount.text = String(beer.favoriteCount)

			tastedButton.selected = beer.taste != nil ? true : false;
			favoritedButton.selected = beer.favorite != nil ? true : false;
			favoritedButton.enabled = (tastedButton.selected == true)

			rateBeerButton.hidden = (beer.rateBeerID <= 0)
		}

		if let status = self.status {
			var displayStatus: String = "Unknown"

			switch status.status {
				case "empty":
					displayStatus = "Empty"
					statusLabel.backgroundColor = UIColor.brewWeekRed()

					self.reportButton.hidden = true
				case "empty-reported":
					displayStatus = "Reported Empty"
					statusLabel.backgroundColor = UIColor.brewWeekRed()

					self.reportButton.setTitle("Reported Empty! Tap here to confirm it…", forState: .Normal)
					self.reportButton.titleLabel?.font = UIFont.italicSystemFontOfSize(UIFont.systemFontSize())

					self.reportButton.hidden = false
				case "untapped":
					displayStatus = "Not Tapped Yet"
					statusLabel.backgroundColor = UIColor.grayColor()

					self.reportButton.hidden = true
				case "tapped":
					displayStatus = "Tapped"
					statusLabel.backgroundColor = UIColor.brewWeekGold()

					self.reportButton.hidden = false
				case "cancelled":
					displayStatus = "Cancelled"
					statusLabel.backgroundColor = UIColor.grayColor()

					self.reportButton.hidden = true
				default:
					statusLabel.backgroundColor = UIColor.grayColor()
					self.reportButton.hidden = true
			}

			statusLabel.text = displayStatus
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

		beer?.tasted() { (count) in
			self.tasteCount.text = String(count)
		}

		self.favoritedButton.enabled = (sender.selected == true)
	}

	@IBAction func favoritedChanged(sender: UIButton) {
		sender.selected = !sender.selected

		beer?.favorited() { (count) in
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

	@IBAction func reportAction(sender: UIButton) {
//		{
//			"beer_id": 123,
//			"establishment_id": 345,
//			"device_guid": "6b981317-1c2d-4219-ad79-7235013ad597"
//		}

		if let beer = self.beer {
			if let status = self.status {
				let guid = UIDevice.currentDevice().identifierForVendor.UUIDString

				var params = [String: AnyObject]()

				params["beer_id"] = Int(beer.identifier)
				params["establishment_id"] = Int(status.establishment.identifier)
				params["device_guid"] = guid

//				NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions, error: <#NSErrorPointer#>)

				Alamofire.request(.PUT, Endpoint(path: "report"), parameters: params, encoding: .JSON).responseJSON { (request, response, responseJSON, error) in
					sender.setTitle("Reported. Thanks!", forState: .Normal)
					sender.enabled = false
				}
			}
		}
	}
}

