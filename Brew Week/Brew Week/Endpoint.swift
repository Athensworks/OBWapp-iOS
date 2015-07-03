//
//  OBWService.swift
//  Brew Week
//
//  Created by Ben Lachman on 6/21/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import Foundation
import Alamofire

class Endpoint: URLStringConvertible {
	static let baseURLString = "http://obwapp.athensworks.com"

	var relativePath: String

	var URLString: String {
		return Endpoint.baseURLString + "/\(relativePath)/"
	}

	init(path: String) {
		relativePath = path
	}
}
