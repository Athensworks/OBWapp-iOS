//
//  BeerTableViewCell.swift
//  Brew Week
//
//  Created by Ben Lachman on 3/19/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit

class BeerTableViewCell: UITableViewCell {

	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var breweryNameLabel: UILabel!
	@IBOutlet weak var tastedCheckboxButton: UIButton!
	@IBOutlet weak var tasteCountImageView: UIImageView!
	@IBOutlet weak var favoritedButton: UIButton!
	@IBOutlet weak var tasteCountLabel: UILabel!
	@IBOutlet weak var favoriteCountLabel: UILabel!
	@IBOutlet weak var beerMetadataLabel: UILabel!
	@IBOutlet weak var limitedReleaseImageView: UIImageView!

	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

		limitedReleaseImageView.image = limitedReleaseImageView.image?.colorizedImage(UIColor.brewWeekGold())

		tasteCountImageView.image = tasteCountImageView.image?.colorizedImage(UIColor.brewWeekGold())

		tastedCheckboxButton.setImage(tastedCheckboxButton.imageForState(.Normal)?.colorizedImage(UIColor.brewWeekRed()), forState: .Normal)
		tastedCheckboxButton.setImage(tastedCheckboxButton.imageForState(.Selected)?.colorizedImage(UIColor.brewWeekRed()), forState: .Selected)

		favoritedButton.setImage(favoritedButton.imageForState(.Normal)?.colorizedImage(UIColor.brewWeekRed()), forState: .Normal)
		favoritedButton.setImage(favoritedButton.imageForState(.Selected)?.colorizedImage(UIColor.brewWeekRed()), forState: .Selected)
	}

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

