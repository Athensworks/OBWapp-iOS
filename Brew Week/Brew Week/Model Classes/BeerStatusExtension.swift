//
//  BeerStatusExtension.swift
//  Brew Week
//
//  Created by Ben Lachman on 7/1/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import Foundation

extension BeerStatus {

	class func statusString(forStatus status:String) -> String {
		switch status {

		case "empty":
			return "Out"
		case "empty-reported":
			return "Reported Out"
		case "untapped":
			return "Not Tapped Yet"
		case "tapped":
			return "Tapped"
		case "cancelled":
			return"Cancelled"
		default:
			return "Unknown Status"
		}
	}

	func statusString() -> String {
		return BeerStatus.statusString(forStatus: self.status)
	}

	static var ordering: [String] {
		get {
			return [
				"tapped",
				"empty-reported",
				"untapped",
				"empty",
				"cancelled",
				"unknown"
			]
		}
	}
}
