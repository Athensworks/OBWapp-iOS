//
//  BeerDetailViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit

class BeerDetailViewController: UIViewController {


	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var limitedReleaseView: UIView!
	@IBOutlet weak var breweryNameLabel: UILabel!

	@IBOutlet weak var detailDescriptionLabel: UILabel!
	@IBOutlet weak var rateBeerButton: UIButton!

	@IBOutlet weak var ibuLabel: UILabel!
	@IBOutlet weak var abvLabel: UILabel!

	@IBOutlet weak var tasteCount: UILabel!
	@IBOutlet weak var tasteCountImageView: UIImageView!
	@IBOutlet weak var favoriteCount: UILabel!
	@IBOutlet weak var favoriteCountImageView: UIImageView!

	@IBOutlet weak var tastedButton: UIButton!
	@IBOutlet weak var favoritedButton: UIButton!

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

			tasteCount.text = String(beer.tasteCount)
			favoriteCount.text = String(beer.favoriteCount)

			tastedButton.selected = beer.taste != nil ? true : false;
			favoritedButton.selected = beer.favorite != nil ? true : false;

			rateBeerButton.hidden == (beer.rateBeerID <= 0)
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

		if sender.selected == true {
			beer?.tasted()
		}
	}

	@IBAction func favoritedChanged(sender: UIButton) {
		sender.selected = !sender.selected

		if sender.selected == true {
			beer?.favorited()
		}
	}

	@IBAction func rateBeerAction(sender: UIButton) {
		if let beer = self.beer {
			if let url = NSURL(string: "http://www.ratebeer.com/beer/" + String(beer.rateBeerID)) {
				UIApplication.sharedApplication().openURL(url)
			}
		}
	}

	@IBAction func reportAction(sender: UIButton) {
	}
}

