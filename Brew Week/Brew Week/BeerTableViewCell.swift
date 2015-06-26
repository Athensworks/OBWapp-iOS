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
	@IBOutlet weak var tastedSwitch: UISwitch!
	@IBOutlet weak var favoritedSwitch: UISwitch!
	@IBOutlet weak var tasteCountLabel: UILabel!
	@IBOutlet weak var favoriteCountLabel: UILabel!

	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
