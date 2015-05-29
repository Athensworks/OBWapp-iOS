//
//  BeerDetailViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit

class BeerDetailViewController: UIViewController {

	@IBOutlet weak var detailDescriptionLabel: UILabel!

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var tastedSwitch: UISwitch!
	@IBOutlet weak var favoritedSwitch: UISwitch!

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

		if let beer: Beer = self.beer {
			nameLabel.text = beer.name
			tastedSwitch.on = beer.tasted;
			favoritedSwitch.on = beer.favorited;
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

	@IBAction func tastedChanged(sender: UISwitch) {
		beer?.tasted = sender.on
	}

	@IBAction func favoritedChanged(sender: UISwitch) {
		beer?.favorited = sender.on
	}

}

