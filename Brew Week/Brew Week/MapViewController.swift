//
//  MapViewController.swift
//  Brew Week
//
//  Created by Ben Lachman on 7/2/15.
//  Copyright (c) 2015 Ohio Brew Week. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class MapViewController: UIViewController, MKMapViewDelegate, ManagedObjectViewController {
	var managedObjectContext: NSManagedObjectContext? = nil

	@IBOutlet weak var mapView: MKMapView!

	let athens = CLLocation(latitude: 39.329288, longitude: -82.100510)

	override func viewDidLoad() {
        // 2.17 miles = 3500 meters
        let region = MKCoordinateRegionMakeWithDistance(athens.coordinate, 3500.0, 3500.0)

        mapView.setRegion(region, animated: true)

		if let context = managedObjectContext {
			let fetchEstablishments = NSFetchRequest(entityName: "Establishment")

            do {
                let fetchedAnnotations = try context.executeFetchRequest(fetchEstablishments)
                if let annotations = fetchedAnnotations as? [MKAnnotation] {
                    mapView.addAnnotations(annotations)
                }
			} catch {
				print(error, terminator: "")
			}
		}
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "showBeers" {
			if let selectedEstablishment = sender as? Establishment {
				let controller = segue.destinationViewController as! BeersTableViewController

				controller.managedObjectContext = managedObjectContext
				controller.establishment = selectedEstablishment
			}
		}
	}

	// MARK: - Actions

	@IBAction func showEstablishment(sender: UIButton?) {
		let annotations = mapView.selectedAnnotations

		if let establishment = annotations.last as? Establishment {
			self.performSegueWithIdentifier("showBeers", sender: establishment)
		}
	}

	// MARK: - MKMapViewDelegate

	static var lastDistanceFromAthens: CLLocationDistance = Double.infinity

	func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        guard let location = userLocation.location else {
            return
        }
        
        let distanceFromAthens = location.distanceFromLocation(athens)
		// 5 miles = 8046
		if distanceFromAthens < 8046 {

			// only update map region if the user has moved more than 500m
			if abs(distanceFromAthens - MapViewController.lastDistanceFromAthens) > 500 {
				mapView.setRegion(mapView.regionThatFits(MKCoordinateRegionMakeWithDistance(location.coordinate, distanceFromAthens, distanceFromAthens)), animated: true)
				//			mapView.setCenterCoordinate(userLocation.location.coordinate, animated: true)

				MapViewController.lastDistanceFromAthens = distanceFromAthens
			}
		}
	}

	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		if let annotation = annotation as? Establishment {
			let identifier = "establishment"
			var view: MKPinAnnotationView

			if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
				dequeuedView.annotation = annotation
				view = dequeuedView
			} else {
				view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
				view.canShowCallout = true

                let button = UIButton(type: .DetailDisclosure)
                
                button.addTarget(self, action: #selector(MapViewController.showEstablishment(_:)), forControlEvents: .TouchUpInside)
                view.rightCalloutAccessoryView = button
			}

			return view
		}

		return nil
	}
}

// MARK: - Establishment + MKAnnotation

extension Establishment: MKAnnotation {
	var coordinate: CLLocationCoordinate2D {
		get {
			return CLLocationCoordinate2DMake(Double(lat), Double(lon))
		}
	}

	// Title and subtitle for use by map call out UI.
	var title: String? {
		get {
			if beerStatuses.count == 1 {
				return name + " (\(beerStatuses.count)🍺)"
			} else {
				return name + " (\(beerStatuses.count)🍻)"
			}
		}
	}

	var subtitle: String? {
		get {
			return address
		}
	}

}
