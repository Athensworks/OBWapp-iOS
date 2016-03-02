//
//  UIImage.swift
//  Brew Week
//
//  Created by Ben Lachman on 6/29/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit

extension UIImage {
	func colorizedImage(color: UIColor) -> UIImage {
		let frame = CGRectMake(0, 0, size.width, size.height)
		UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale)

		let context = UIGraphicsGetCurrentContext()

		drawInRect(frame)

		CGContextSetFillColorWithColor(context, color.CGColor);
		CGContextSetBlendMode(context, kCGBlendModeSourceAtop);
		CGContextFillRect(context, frame);

		let colorizedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();

		return colorizedImage;
	}
}
