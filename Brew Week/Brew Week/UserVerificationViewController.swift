//
//  UserVerificationViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 5/28/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import CoreData


class UserVerificationViewController : UIViewController, UITextFieldDelegate {

	@IBOutlet weak var doneButton: UIButton!
	@IBOutlet weak var zipField: UITextField!
	@IBOutlet weak var datePicker: UIDatePicker!
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	// MARK: - Custom Methods

	func verifyFields() {
		if let zipString = zipField.text {
			if count(zipString) >= 5 && datePicker.date.isTwentyOne() {
				doneButton.enabled = true
				return
			}
		}

		doneButton.enabled = false
	}

	// MARK: - Actions

	@IBAction func dateValueChangedAction(sender: UIDatePicker) {
		let birthdate = sender.date

		verifyFields()
	}

	@IBAction func zipCodeChanged(sender: UILabel) {
		verifyFields()
	}

	@IBAction func doneAction(sender: UIButton) {
		if let managedObjectContext = (UIApplication.sharedApplication().delegate as? AppDelegate)?.managedObjectContext {
			var drinker = NSEntityDescription.insertNewObjectForEntityForName("Drinker", inManagedObjectContext: managedObjectContext) as! Drinker


			drinker.age = fabs(datePicker.date.timeIntervalSinceNow)
			drinker.zip = zipField.text

			(UIApplication.sharedApplication().delegate as? AppDelegate)?.drinker = drinker
		}

		NSUserDefaults.standardUserDefaults().setBool(true, forKey: "AgeVerified")

		presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

	// MARK: - UITextFieldDelegate

	func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
		if (range.location + count(string)) > 5 {
			return false
		}

		if (string as NSString).rangeOfCharacterFromSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet).location != NSNotFound {
			return false
		}

		return true
	}

	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.resignFirstResponder()

		return true
	}

}

extension NSDate {
	func isTwentyOne() -> Bool {
		if self.timeIntervalSinceNow < -1*(21*364*24*60*60) { // 21 years
			return true
		}

		return false
	}
}
