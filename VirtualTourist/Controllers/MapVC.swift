//
//  MapVC.swift
//  VirtualTourist
//
//  Created by Marlhex on 2020-06-05.
//  Copyright © 2020 Ignacio Arias. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController {


	private var fetchResultsController: NSFetchedResultsController<Pin>!

	var dataController: DataController!

	@IBOutlet weak var mapView: MKMapView!


	override func viewDidLoad() {
		super.viewDidLoad()
		initializeFetchResultsController()

		// Add a long tap gesture recognizer
		// Add LongTapGesture
		let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPin(_:)))
		mapView.addGestureRecognizer(longPressRecognizer)

		loadPins()
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		fetchResultsController = nil
	}

	private func initializeFetchResultsController() {
		// Create a fetchRequest
		let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
		let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
		fetchRequest.sortDescriptors = [sortDescriptor]

		fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "nil")
	}

	@objc func addPin(_ sender: UILongPressGestureRecognizer) {
		let location = sender.location(in: mapView)
		let coordinates = mapView.convert(location, toCoordinateFrom: mapView)

		createPin(withCoordinates: coordinates)
	}

	private func createPin(withCoordinates coordinates: CLLocationCoordinate2D) {
		let pin = Pin(context: dataController.viewContext)
		pin.latitude = coordinates.latitude
		pin.longitude = coordinates.longitude

		dataController.viewContext.insert(pin)
		try? dataController.viewContext.save()

		mapView.addAnnotation(pin)
	}

	private func loadPins() {
		// Load all the pins from CoreData
		if let pins = fetchResultsController.fetchedObjects {
			mapView.addAnnotations(pins)
		}
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.destination is AlbumVC {
			guard let pin = sender as? Pin else {
				return
			}
			let controller = segue.destination as! AlbumVC
			controller.pin = pin
			controller.dataController = dataController
		}
	}
}

extension MapVC: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		// Get the selected pin
		let pin: Pin = view.annotation as! Pin

		performSegue(withIdentifier: "openAlbum", sender: pin)
	}
}

extension MapVC: NSFetchedResultsControllerDelegate {
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		// Check that the object is an actual pin
		guard let pin = anObject as? Pin  else { return }

		switch type {
			case .insert:
				// Insert the pin into the map
				mapView.addAnnotation(pin)
			default:
				break
		}
	}
}
